package upload

import (
	"context"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"syscall"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/lsif_transformer/parser"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/zipartifacts"
)

// Sent by the runner: https://gitlab.com/gitlab-org/gitlab-runner/blob/c24da19ecce8808d9d2950896f70c94f5ea1cc2e/network/gitlab.go#L580
const (
	ArtifactFormatKey     = "artifact_format"
	ArtifactFormatZip     = "zip"
	ArtifactFormatDefault = ""
)

var zipSubcommandsErrorsCounter = promauto.NewCounterVec(
	prometheus.CounterOpts{
		Name: "gitlab_workhorse_zip_subcommand_errors_total",
		Help: "Errors comming from subcommands used for processing ZIP archives",
	}, []string{"error"})

type artifactsUploadProcessor struct {
	format      string
	processLSIF bool
	tempDir     string

	SavedFileTracker
}

// Artifacts is like a Multipart but specific for artifacts upload.
func Artifacts(myAPI *api.API, h http.Handler, p Preparer) http.Handler {
	return myAPI.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		format := r.URL.Query().Get(ArtifactFormatKey)
		mg := &artifactsUploadProcessor{
			format:           format,
			processLSIF:      a.ProcessLsif,
			tempDir:          a.TempPath,
			SavedFileTracker: SavedFileTracker{Request: r},
		}
		interceptMultipartFiles(w, r, h, mg, &eagerAuthorizer{a}, p)
	}, "/authorize")
}

func (a *artifactsUploadProcessor) generateMetadataFromZip(ctx context.Context, file *destination.FileHandler) (*destination.FileHandler, error) {
	metaOpts := &destination.UploadOpts{
		LocalTempPath: a.tempDir,
	}
	if metaOpts.LocalTempPath == "" {
		metaOpts.LocalTempPath = os.TempDir()
	}

	fileName := file.LocalPath
	if fileName == "" {
		fileName = file.RemoteURL
	}

	zipMd := exec.CommandContext(ctx, "gitlab-zip-metadata", fileName)
	zipMd.Stderr = log.ContextLogger(ctx).Writer()
	zipMd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}

	zipMdOut, err := zipMd.StdoutPipe()
	if err != nil {
		return nil, err
	}
	defer zipMdOut.Close()

	if err := zipMd.Start(); err != nil {
		return nil, err
	}
	defer helper.CleanUpProcessGroup(zipMd)

	fh, err := destination.Upload(ctx, zipMdOut, -1, "metadata.gz", metaOpts)
	if err != nil {
		return nil, err
	}

	if err := zipMd.Wait(); err != nil {
		st, ok := helper.ExitStatus(err)

		if !ok {
			return nil, err
		}

		zipSubcommandsErrorsCounter.WithLabelValues(zipartifacts.ErrorLabelByCode(st)).Inc()

		if st == zipartifacts.CodeNotZip {
			return nil, nil
		}

		if st == zipartifacts.CodeLimitsReached {
			return nil, zipartifacts.ErrBadMetadata
		}
	}

	return fh, nil
}

func (a *artifactsUploadProcessor) ProcessFile(ctx context.Context, formName string, file *destination.FileHandler, writer *multipart.Writer) error {
	//  ProcessFile for artifacts requires file form-data field name to eq `file`
	if formName != "file" {
		return fmt.Errorf("invalid form field: %q", formName)
	}

	if a.Count() > 0 {
		return fmt.Errorf("artifacts request contains more than one file")
	}
	a.Track(formName, file.LocalPath)

	select {
	case <-ctx.Done():
		return fmt.Errorf("ProcessFile: context done")
	default:
	}

	if !strings.EqualFold(a.format, ArtifactFormatZip) && a.format != ArtifactFormatDefault {
		return nil
	}

	metadata, err := a.generateMetadataFromZip(ctx, file)
	if err != nil {
		return err
	}

	if metadata != nil {
		fields, err := metadata.GitLabFinalizeFields("metadata")
		if err != nil {
			return fmt.Errorf("finalize metadata field error: %v", err)
		}

		for k, v := range fields {
			writer.WriteField(k, v)
		}

		a.Track("metadata", metadata.LocalPath)
	}

	return nil
}

func (a *artifactsUploadProcessor) Name() string { return "artifacts" }

func (a *artifactsUploadProcessor) TransformContents(ctx context.Context, filename string, r io.Reader) (io.ReadCloser, error) {
	if a.processLSIF {
		return parser.NewParser(ctx, r)
	}

	return a.SavedFileTracker.TransformContents(ctx, filename, r)
}
