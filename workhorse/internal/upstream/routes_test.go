package upstream

import (
	"testing"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

func TestAdminGeoPathsWithGeoProxy(t *testing.T) {
	testCases := []testCase{
		{"Regular admin/geo", "/admin/geo", "Geo primary received request to path /admin/geo"},
		{"Specific object replication", "/admin/geo/replication/object_type", "Geo primary received request to path /admin/geo/replication/object_type"},
		{"Specific object replication per-site", "/admin/geo/sites/2/replication/object_type", "Geo primary received request to path /admin/geo/sites/2/replication/object_type"},
		{"Projects replication per-site", "/admin/geo/sites/2/replication/projects", "Geo primary received request to path /admin/geo/sites/2/replication/projects"},
		{"Designs replication per-site", "/admin/geo/sites/2/replication/designs", "Geo primary received request to path /admin/geo/sites/2/replication/designs"},
		{"Projects replication", "/admin/geo/replication/projects", "Local Rails server received request to path /admin/geo/replication/projects"},
		{"Projects replication subpaths", "/admin/geo/replication/projects/2", "Local Rails server received request to path /admin/geo/replication/projects/2"},
		{"Designs replication", "/admin/geo/replication/designs", "Local Rails server received request to path /admin/geo/replication/designs"},
		{"Designs replication subpaths", "/admin/geo/replication/designs/3", "Local Rails server received request to path /admin/geo/replication/designs/3"},
	}

	runTestCasesWithGeoProxyEnabled(t, testCases)
}

func TestProjectNotExistingGitHttpPullWithGeoProxy(t *testing.T) {
	testCases := []testCase{
		{"secondary info/refs", "/group/project.git/info/refs", "Local Rails server received request to path /group/project.git/info/refs"},
		{"primary info/refs", "/-/push_from_secondary/2/group/project.git/info/refs", "Geo primary received request to path /-/push_from_secondary/2/group/project.git/info/refs"},
		{"primary upload-pack", "/-/push_from_secondary/2/group/project.git/git-upload-pack", "Geo primary received request to path /-/push_from_secondary/2/group/project.git/git-upload-pack"},
	}

	runTestCasesWithGeoProxyEnabled(t, testCases)
}

func TestProjectNotExistingGitHttpPushWithGeoProxy(t *testing.T) {
	testCases := []testCase{
		{"secondary info/refs", "/group/project.git/info/refs", "Local Rails server received request to path /group/project.git/info/refs"},
		{"primary info/refs", "/-/push_from_secondary/2/group/project.git/info/refs", "Geo primary received request to path /-/push_from_secondary/2/group/project.git/info/refs"},
		{"primary receive-pack", "/-/push_from_secondary/2/group/project.git/git-receive-pack", "Geo primary received request to path /-/push_from_secondary/2/group/project.git/git-receive-pack"},
	}

	runTestCasesWithGeoProxyEnabled(t, testCases)
}

func TestProjectNotExistingGitSSHPullWithGeoProxy(t *testing.T) {
	testCases := []testCase{
		{"GitLab Shell call to authorized-keys", "/api/v4/internal/authorized_keys", "Local Rails server received request to path /api/v4/internal/authorized_keys"},
		{"GitLab Shell call to allowed", "/api/v4/internal/allowed", "Local Rails server received request to path /api/v4/internal/allowed"},
		{"GitLab Shell call to info/refs", "/api/v4/geo/proxy_git_ssh/info_refs_receive_pack", "Local Rails server received request to path /api/v4/geo/proxy_git_ssh/info_refs_receive_pack"},
		{"GitLab Shell call to receive_pack", "/api/v4/geo/proxy_git_ssh/receive_pack", "Local Rails server received request to path /api/v4/geo/proxy_git_ssh/receive_pack"},
	}

	runTestCasesWithGeoProxyEnabled(t, testCases)
}

func TestProjectNotExistingGitSSHPushWithGeoProxy(t *testing.T) {
	testCases := []testCase{
		{"GitLab Shell call to authorized-keys", "/api/v4/internal/authorized_keys", "Local Rails server received request to path /api/v4/internal/authorized_keys"},
		{"GitLab Shell call to allowed", "/api/v4/internal/allowed", "Local Rails server received request to path /api/v4/internal/allowed"},
		{"GitLab Shell call to info/refs", "/api/v4/geo/proxy_git_ssh/info_refs_upload_pack", "Local Rails server received request to path /api/v4/geo/proxy_git_ssh/info_refs_upload_pack"},
		{"GitLab Shell call to receive_pack", "/api/v4/geo/proxy_git_ssh/upload_pack", "Local Rails server received request to path /api/v4/geo/proxy_git_ssh/upload_pack"},
	}

	runTestCasesWithGeoProxyEnabled(t, testCases)
}

func TestAssetsServedLocallyWithGeoProxy(t *testing.T) {
	path := "/assets/static.txt"
	content := "local geo asset"
	testhelper.SetupStaticFileHelper(t, path, content, testDocumentRoot)

	testCases := []testCase{
		{"assets path", "/assets/static.txt", "local geo asset"},
	}

	runTestCasesWithGeoProxyEnabled(t, testCases)
}
