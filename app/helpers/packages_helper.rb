# frozen_string_literal: true

module PackagesHelper
  include ::API::Helpers::RelatedResourcesHelpers

  def package_sort_path(options = {})
    "#{request.path}?#{options.to_param}"
  end

  def nuget_package_registry_url(project_id)
    expose_url(api_v4_projects_packages_nuget_index_path(id: project_id, format: '.json'))
  end

  def package_registry_instance_url(registry_type)
    expose_url("api/#{::API::API.version}/packages/#{registry_type}")
  end

  def package_registry_project_url(project_id, registry_type = :maven)
    project_api_path = expose_path(api_v4_projects_path(id: project_id))
    package_registry_project_path = "#{project_api_path}/packages/#{registry_type}"
    expose_url(package_registry_project_path)
  end

  def package_from_presenter(package)
    presenter = ::Packages::Detail::PackagePresenter.new(package)

    presenter.detail_view.to_json
  end

  def pypi_registry_url(project_id)
    full_url = expose_url(api_v4_projects_packages_pypi_simple_package_name_path({ id: project_id, package_name: '' }, true))
    full_url.sub!('://', '://__token__:<your_personal_token>@')
  end

  def composer_registry_url(group_id)
    expose_url(api_v4_group___packages_composer_packages_path(id: group_id, format: '.json'))
  end

  def composer_config_repository_name(group_id)
    "#{Gitlab.config.gitlab.host}/#{group_id}"
  end

  def track_package_event(event_name, scope, **args)
    ::Packages::CreateEventService.new(nil, current_user, event_name: event_name, scope: scope).execute
    category = args.delete(:category) || self.class.name
    ::Gitlab::Tracking.event(category, event_name.to_s, **args)
  end

  def show_cleanup_policy_link(project)
    Gitlab.com? &&
    Gitlab.config.registry.enabled &&
    project.feature_available?(:container_registry, current_user) &&
    project.container_expiration_policy.nil? &&
    project.container_repositories.exists?
  end

  def show_container_registry_settings(project)
    Gitlab.config.registry.enabled &&
    Ability.allowed?(current_user, :admin_container_image, project)
  end

  def show_package_registry_settings(project)
    Gitlab.config.packages.enabled &&
    Ability.allowed?(current_user, :admin_package, project)
  end

  def cleanup_settings_data
    {
      project_id: @project.id,
      project_path: @project.full_path,
      cadence_options: cadence_options.to_json,
      keep_n_options: keep_n_options.to_json,
      older_than_options: older_than_options.to_json,
      is_admin: current_user&.admin.to_s,
      admin_settings_path: ci_cd_admin_application_settings_path(anchor: 'js-registry-settings'),
      project_settings_path: project_settings_packages_and_registries_path(@project),
      enable_historic_entries: container_expiration_policies_historic_entry_enabled?.to_s,
      help_page_path: help_page_path('user/packages/container_registry/reduce_container_registry_storage', anchor: 'cleanup-policy'),
      show_cleanup_policy_link: show_cleanup_policy_link(@project).to_s,
      tags_regex_help_page_path: help_page_path('user/packages/container_registry/reduce_container_registry_storage', anchor: 'regex-pattern-examples')
    }
  end

  def settings_data
    cleanup_settings_data.merge(
      show_container_registry_settings: show_container_registry_settings(@project).to_s,
      show_package_registry_settings: show_package_registry_settings(@project).to_s,
      cleanup_settings_path: cleanup_image_tags_project_settings_packages_and_registries_path(@project)
    )
  end
end
