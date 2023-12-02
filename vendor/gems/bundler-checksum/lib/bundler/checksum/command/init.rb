# frozen_string_literal: true

require 'openssl'

module Bundler::Checksum::Command
  module Init
    extend self

    def execute
      $stderr.puts "Initializing checksum file #{checksum_file}"

      checksums = []

      compact_index_cache = Bundler::Fetcher::CompactIndex
        .new(nil, Bundler::Source::Rubygems::Remote.new(Bundler::URI("https://rubygems.org")), nil)
        .send(:compact_index_client)
        .instance_variable_get(:@cache)

      seen = []
      Bundler.definition.resolve.sort_by(&:name).each do |spec|
        next unless spec.source.is_a?(Bundler::Source::Rubygems)

        next if seen.include?(spec.name)
        seen << spec.name

        $stderr.puts "Adding #{spec.name}==#{spec.version}"

        compact_index_dependencies = compact_index_cache.dependencies(spec.name).select { |item| item.first == spec.version.to_s }

        if !compact_index_dependencies.empty?
          compact_index_checksums = compact_index_dependencies.map do |version, platform, dependencies, requirements|
            {
              name: spec.name,
              version: spec.version.to_s,
              platform: Gem::Platform.new(platform).to_s,
              checksum: requirements.detect { |requirement| requirement.first == 'checksum' }.flatten[1]
            }
          end

          checksums += compact_index_checksums.sort_by { |hash| hash.values }
        else
          remote_checksum = Helper.remote_checksums_for_gem(spec.name, spec.version)

          if remote_checksum.empty?
            raise "#{spec.name} #{spec.version} not found on Rubygems!"
          end

          checksums += remote_checksum.sort_by { |hash| hash.values }
        end
      end

      File.write(checksum_file, JSON.generate(checksums, array_nl: "\n") + "\n")
    end

    private

    def checksum_file
      ::Bundler::Checksum.checksum_file
    end

    def lockfile
      lockfile_path = Bundler.default_lockfile
      lockfile = Bundler::LockfileParser.new(Bundler.read_file(lockfile_path))
    end
  end
end
