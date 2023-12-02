# frozen_string_literal: true

require 'fileutils'

module Tasks
  module Gitlab
    module Assets
      FOSS_ASSET_FOLDERS = %w[app/assets fixtures/emojis vendor/assets/javascripts].freeze
      EE_ASSET_FOLDERS = %w[ee/app/assets].freeze
      JH_ASSET_FOLDERS = %w[jh/app/assets].freeze
      JS_ASSET_PATTERNS = %w[*.js config/**/*.js].freeze
      JS_ASSET_FILES = %w[package.json yarn.lock].freeze
      MASTER_SHA256_HASH_FILE = 'master-assets-hash.txt'
      HEAD_SHA256_HASH_FILE = 'assets-hash.txt'
      PUBLIC_ASSETS_WEBPACK_DIR = 'public/assets/webpack'

      def self.sha256_of_assets_impacting_webpack_compilation
        start_time = Time.now
        asset_files = assets_impacting_webpack_compilation
        puts "Generating the SHA256 hash for #{assets_impacting_webpack_compilation.size} Webpack-related assets..."

        asset_file_sha256s = asset_files.map do |asset_file|
          Digest::SHA256.file(asset_file).hexdigest
        end

        Digest::SHA256.hexdigest(asset_file_sha256s.join).tap { |sha256| puts "=> SHA256 generated in #{Time.now - start_time}: #{sha256}" }
      end

      def self.assets_impacting_webpack_compilation
        assets_folders = FOSS_ASSET_FOLDERS
        assets_folders += EE_ASSET_FOLDERS if ::Gitlab.ee?
        assets_folders += JH_ASSET_FOLDERS if ::Gitlab.jh?

        asset_files = Dir.glob(JS_ASSET_PATTERNS)
        asset_files += JS_ASSET_FILES

        assets_folders.each do |folder|
          asset_files.concat(Dir.glob(["#{folder}/**/*.*"]))
        end

        asset_files
      end

      private_class_method :assets_impacting_webpack_compilation
    end
  end
end

namespace :gitlab do
  namespace :assets do
    desc 'GitLab | Assets | Compile all frontend assets'
    task :compile do
      require_dependency 'gitlab/task_helpers'

      %w[
        yarn:check
        gettext:po_to_json
        rake:assets:precompile
        gitlab:assets:compile_webpack_if_needed
        gitlab:assets:fix_urls
        gitlab:assets:check_page_bundle_mixins_css_for_sideeffects
      ].each(&::Gitlab::TaskHelpers.method(:invoke_and_time_task))
    end

    desc 'GitLab | Assets | Compile all Webpack assets'
    task :compile_webpack_if_needed do
      FileUtils.mv(Tasks::Gitlab::Assets::HEAD_SHA256_HASH_FILE, Tasks::Gitlab::Assets::MASTER_SHA256_HASH_FILE, force: true)

      master_assets_sha256 =
        if File.exist?(Tasks::Gitlab::Assets::MASTER_SHA256_HASH_FILE)
          File.read(Tasks::Gitlab::Assets::MASTER_SHA256_HASH_FILE)
        else
          'missing!'
        end

      head_assets_sha256 = Tasks::Gitlab::Assets.sha256_of_assets_impacting_webpack_compilation.tap do |sha256|
        File.write(Tasks::Gitlab::Assets::HEAD_SHA256_HASH_FILE, sha256)
      end

      puts "Webpack assets SHA256 for `master`: #{master_assets_sha256}"
      puts "Webpack assets SHA256 for `HEAD`: #{head_assets_sha256}"

      public_assets_webpack_dir_exists = Dir.exist?(Tasks::Gitlab::Assets::PUBLIC_ASSETS_WEBPACK_DIR)

      if head_assets_sha256 != master_assets_sha256 || !public_assets_webpack_dir_exists
        FileUtils.rm_r(Tasks::Gitlab::Assets::PUBLIC_ASSETS_WEBPACK_DIR) if public_assets_webpack_dir_exists

        log_path = ENV['WEBPACK_COMPILE_LOG_PATH']

        cmd = 'yarn webpack'
        cmd += " > #{log_path}" if log_path

        unless system(cmd)
          abort 'Error: Unable to compile webpack production bundle.'.color(:red)
        end

        puts "Written webpack stdout log to #{log_path}" if log_path
        puts "You can inspect the webpack log here: #{ENV['CI_JOB_URL']}/artifacts/file/#{log_path}" if log_path && ENV['CI_JOB_URL']
      end
    end

    desc 'GitLab | Assets | Clean up old compiled frontend assets'
    task clean: ['rake:assets:clean']

    desc 'GitLab | Assets | Remove all compiled frontend assets'
    task purge: ['rake:assets:clobber']

    desc 'GitLab | Assets | Uninstall frontend dependencies'
    task purge_modules: ['yarn:clobber']

    desc 'GitLab | Assets | Fix all absolute url references in CSS'
    task :fix_urls do
      css_files = Dir['public/assets/*.css']
      css_files.each do |file|
        # replace url(/assets/*) with url(./*)
        puts "Fixing #{file}"
        system "sed", "-i", "-e", 's/url(\([\"\']\?\)\/assets\//url(\1.\//g', file

        # rewrite the corresponding gzip file (if it exists)
        gzip = "#{file}.gz"
        if File.exist?(gzip)
          puts "Fixing #{gzip}"

          FileUtils.rm(gzip)
          mtime = File.stat(file).mtime

          File.open(gzip, 'wb+') do |f|
            gz = Zlib::GzipWriter.new(f, Zlib::BEST_COMPRESSION)
            gz.mtime = mtime
            gz.write IO.binread(file)
            gz.close

            File.utime(mtime, mtime, f.path)
          end
        end
      end
    end

    desc 'GitLab | Assets | Compile vendor assets'
    task :vendor do
      unless system('yarn webpack-vendor')
        abort 'Error: Unable to compile webpack DLL.'.color(:red)
      end
    end

    desc 'GitLab | Assets | Check that scss mixins do not introduce any sideffects'
    task :check_page_bundle_mixins_css_for_sideeffects do
      system('./scripts/frontend/check_page_bundle_mixins_css_for_sideeffects.js')
    end
  end
end
