# frozen_string_literal: true

module API
  module Concerns
    module Packages
      module DebianPackageEndpoints
        extend ActiveSupport::Concern

        DISTRIBUTION_REQUIREMENTS = {
          distribution: ::Packages::Debian::DISTRIBUTION_REGEX
        }.freeze
        COMPONENT_ARCHITECTURE_REQUIREMENTS = {
          component: ::Packages::Debian::COMPONENT_REGEX,
          architecture: ::Packages::Debian::ARCHITECTURE_REGEX
        }.freeze

        included do
          feature_category :package_registry
          urgency :low

          helpers ::API::Helpers::PackagesHelpers
          helpers ::API::Helpers::Packages::BasicAuthHelpers
          include ::API::Helpers::Authentication

          helpers do
            params :shared_package_file_params do
              requires :distribution, type: String, desc: 'The Debian Codename or Suite', regexp: Gitlab::Regex.debian_distribution_regex
              requires :letter, type: String, desc: 'The Debian Classification (first-letter or lib-first-letter)'
              requires :package_name, type: String, desc: 'The Debian Source Package Name', regexp: Gitlab::Regex.debian_package_name_regex
              requires :package_version, type: String, desc: 'The Debian Source Package Version', regexp: Gitlab::Regex.debian_version_regex
              requires :file_name, type: String, desc: 'The Debian File Name'
            end

            def distribution_from!(container)
              ::Packages::Debian::DistributionsFinder.new(container, codename_or_suite: params[:distribution]).execute.last!
            end

            def present_distribution_package_file!
              not_found! unless params[:package_name].start_with?(params[:letter])

              package_file = distribution_from!(user_project).package_files.with_file_name(params[:file_name]).last!

              present_package_file!(package_file)
            end

            def present_index_file!(file_type)
              relation = "::Packages::Debian::#{project_or_group.class.name}ComponentFile".constantize

              relation = relation
                .preload_distribution
                .with_container(project_or_group)
                .with_codename_or_suite(params[:distribution])
                .with_component_name(params[:component])
                .with_file_type(file_type)
                .with_architecture_name(params[:architecture])
                .with_compression_type(nil)
                .order_created_asc

              relation = relation.with_file_sha256(params[:file_sha256]) if params[:file_sha256]

              present_carrierwave_file!(relation.last!.file)
            end
          end

          rescue_from ArgumentError do |e|
            render_api_error!(e.message, 400)
          end

          rescue_from ActiveRecord::RecordInvalid do |e|
            render_api_error!(e.message, 400)
          end

          authenticate_with do |accept|
            accept.token_types(:personal_access_token, :deploy_token, :job_token)
                  .sent_through(:http_basic_auth)
          end

          format :txt
          content_type :txt, 'text/plain'

          params do
            requires :distribution, type: String, desc: 'The Debian Codename or Suite', regexp: Gitlab::Regex.debian_distribution_regex
          end

          namespace 'dists/*distribution', requirements: DISTRIBUTION_REQUIREMENTS do
            # GET {projects|groups}/:id/packages/debian/dists/*distribution/Release.gpg
            # https://wiki.debian.org/DebianRepository/Format#A.22Release.22_files
            desc 'The Release file signature' do
              detail 'This feature was introduced in GitLab 13.5'
            end

            route_setting :authentication, authenticate_non_public: true
            get 'Release.gpg' do
              distribution_from!(project_or_group).file_signature
            end

            # GET {projects|groups}/:id/packages/debian/dists/*distribution/Release
            # https://wiki.debian.org/DebianRepository/Format#A.22Release.22_files
            desc 'The unsigned Release file' do
              detail 'This feature was introduced in GitLab 13.5'
            end

            route_setting :authentication, authenticate_non_public: true
            get 'Release' do
              present_carrierwave_file!(distribution_from!(project_or_group).file)
            end

            # GET {projects|groups}/:id/packages/debian/dists/*distribution/InRelease
            # https://wiki.debian.org/DebianRepository/Format#A.22Release.22_files
            desc 'The signed Release file' do
              detail 'This feature was introduced in GitLab 13.5'
            end

            route_setting :authentication, authenticate_non_public: true
            get 'InRelease' do
              present_carrierwave_file!(distribution_from!(project_or_group).signed_file)
            end

            params do
              requires :component, type: String, desc: 'The Debian Component', regexp: Gitlab::Regex.debian_component_regex
            end

            namespace ':component', requirements: COMPONENT_ARCHITECTURE_REQUIREMENTS do
              params do
                requires :architecture, type: String, desc: 'The Debian Architecture', regexp: Gitlab::Regex.debian_architecture_regex
              end

              namespace 'debian-installer/binary-:architecture' do
                # GET {projects|groups}/:id/packages/debian/dists/*distribution/:component/debian-installer/binary-:architecture/Packages
                # https://wiki.debian.org/DebianRepository/Format#A.22Packages.22_Indices
                desc 'The installer (udeb) binary files index' do
                  detail 'This feature was introduced in GitLab 15.4'
                end

                route_setting :authentication, authenticate_non_public: true
                get 'Packages' do
                  present_index_file!(:di_packages)
                end

                # GET {projects|groups}/:id/packages/debian/dists/*distribution/:component/debian-installer/binary-:architecture/by-hash/SHA256/:file_sha256
                # https://wiki.debian.org/DebianRepository/Format?action=show&redirect=RepositoryFormat#indices_acquisition_via_hashsums_.28by-hash.29
                desc 'The installer (udeb) binary files index by hash' do
                  detail 'This feature was introduced in GitLab 15.4'
                end

                route_setting :authentication, authenticate_non_public: true
                get 'by-hash/SHA256/:file_sha256' do
                  present_index_file!(:di_packages)
                end
              end

              namespace 'source', requirements: COMPONENT_ARCHITECTURE_REQUIREMENTS do
                # GET {projects|groups}/:id/packages/debian/dists/*distribution/:component/source/Sources
                # https://wiki.debian.org/DebianRepository/Format#A.22Sources.22_Indices
                desc 'The source files index' do
                  detail 'This feature was introduced in GitLab 15.4'
                end

                route_setting :authentication, authenticate_non_public: true
                get 'Sources' do
                  present_index_file!(:sources)
                end

                # GET {projects|groups}/:id/packages/debian/dists/*distribution/:component/source/by-hash/SHA256/:file_sha256
                # https://wiki.debian.org/DebianRepository/Format?action=show&redirect=RepositoryFormat#indices_acquisition_via_hashsums_.28by-hash.29
                desc 'The source files index by hash' do
                  detail 'This feature was introduced in GitLab 15.4'
                end

                route_setting :authentication, authenticate_non_public: true
                get 'by-hash/SHA256/:file_sha256' do
                  present_index_file!(:sources)
                end
              end

              params do
                requires :architecture, type: String, desc: 'The Debian Architecture', regexp: Gitlab::Regex.debian_architecture_regex
              end

              namespace 'binary-:architecture', requirements: COMPONENT_ARCHITECTURE_REQUIREMENTS do
                # GET {projects|groups}/:id/packages/debian/dists/*distribution/:component/binary-:architecture/Packages
                # https://wiki.debian.org/DebianRepository/Format#A.22Packages.22_Indices
                desc 'The binary files index' do
                  detail 'This feature was introduced in GitLab 13.5'
                end

                route_setting :authentication, authenticate_non_public: true
                get 'Packages' do
                  present_index_file!(:packages)
                end

                # GET {projects|groups}/:id/packages/debian/dists/*distribution/:component/binary-:architecture/by-hash/SHA256/:file_sha256
                # https://wiki.debian.org/DebianRepository/Format?action=show&redirect=RepositoryFormat#indices_acquisition_via_hashsums_.28by-hash.29
                desc 'The binary files index by hash' do
                  detail 'This feature was introduced in GitLab 15.4'
                end

                route_setting :authentication, authenticate_non_public: true
                get 'by-hash/SHA256/:file_sha256' do
                  present_index_file!(:packages)
                end
              end
            end
          end
        end
      end
    end
  end
end
