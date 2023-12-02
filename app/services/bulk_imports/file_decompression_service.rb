# frozen_string_literal: true

# File Decompression Service allows gzipped files decompression into tmp directory.
#
# @param tmpdir [String] Temp directory to store downloaded file to. Must be located under `Dir.tmpdir`.
# @param filename [String] Name of the file to decompress.
module BulkImports
  class FileDecompressionService
    include Gitlab::ImportExport::CommandLineUtil

    ServiceError = Class.new(StandardError)

    def initialize(tmpdir:, filename:)
      @tmpdir = tmpdir
      @filename = filename
      @filepath = File.join(@tmpdir, @filename)
      @decompressed_filename = File.basename(@filename, '.gz')
      @decompressed_filepath = File.join(@tmpdir, @decompressed_filename)
    end

    def execute
      validate_tmpdir
      validate_filepath
      validate_decompressed_file_size if Feature.enabled?(:validate_import_decompressed_archive_size)
      validate_symlink(filepath)

      decompress_file

      validate_symlink(decompressed_filepath)

      filepath
    rescue StandardError => e
      File.delete(filepath) if File.exist?(filepath)
      File.delete(decompressed_filepath) if File.exist?(decompressed_filepath)

      raise e
    end

    private

    attr_reader :tmpdir, :filename, :filepath, :decompressed_filename, :decompressed_filepath

    def validate_filepath
      Gitlab::Utils.check_path_traversal!(filepath)
    end

    def validate_tmpdir
      Gitlab::Utils.check_allowed_absolute_path!(tmpdir, [Dir.tmpdir])
    end

    def validate_decompressed_file_size
      raise(ServiceError, 'File decompression error') unless size_validator.valid?
    end

    def validate_symlink(filepath)
      raise(ServiceError, 'Invalid file') if File.lstat(filepath).symlink?
    end

    def decompress_file
      gunzip(dir: tmpdir, filename: filename)
    end

    def size_validator
      @size_validator ||= Gitlab::ImportExport::DecompressedArchiveSizeValidator.new(archive_path: filepath)
    end
  end
end
