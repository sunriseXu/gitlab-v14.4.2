# frozen_string_literal: true
module API
  class RpmProjectPackages < ::API::Base
    helpers ::API::Helpers::PackagesHelpers
    helpers ::API::Helpers::Packages::BasicAuthHelpers
    include ::API::Helpers::Authentication

    feature_category :package_registry

    before do
      require_packages_enabled!

      not_found! unless ::Feature.enabled?(:rpm_packages, authorized_user_project)

      authorize_read_package!(authorized_user_project)
    end

    authenticate_with do |accept|
      accept.token_types(:personal_access_token_with_username, :deploy_token_with_username, :job_token_with_username)
            .sent_through(:http_basic_auth)
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      namespace ':id/packages/rpm' do
        desc 'Download repository metadata files'
        params do
          requires :file_name, type: String, desc: 'Repository metadata file name'
        end
        get 'repodata/*file_name', requirements: { file_name: API::NO_SLASH_URL_PART_REGEX } do
          not_found!
        end

        desc 'Download RPM package files'
        params do
          requires :package_file_id, type: Integer, desc: 'RPM package file id'
          requires :file_name, type: String, desc: 'RPM package file name'
        end
        get '*package_file_id/*file_name', requirements: { file_name: API::NO_SLASH_URL_PART_REGEX } do
          not_found!
        end

        desc 'Upload a RPM package'
        post do
          authorize_create_package!(authorized_user_project)

          if authorized_user_project.actual_limits.exceeded?(:rpm_max_file_size, params[:file].size)
            bad_request!('File is too large')
          end

          not_found!
        end

        desc 'Authorize package upload from workhorse'
        post 'authorize' do
          not_found!
        end
      end
    end
  end
end
