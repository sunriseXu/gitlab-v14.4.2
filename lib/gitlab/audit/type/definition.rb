# frozen_string_literal: true

module Gitlab
  module Audit
    module Type
      class Definition
        include ActiveModel::Validations

        attr_reader :path
        attr_reader :attributes

        validate :validate_schema
        validate :validate_file_name

        InvalidAuditEventTypeError = Class.new(StandardError)

        AUDIT_EVENT_TYPE_SCHEMA_PATH = Rails.root.join('config', 'audit_events', 'types', 'type_schema.json')
        AUDIT_EVENT_TYPE_SCHEMA = JSONSchemer.schema(AUDIT_EVENT_TYPE_SCHEMA_PATH)

        # The PARAMS in config/audit_events/types/type_schema.json
        PARAMS = %i[
          name
          description
          introduced_by_issue
          introduced_by_mr
          group
          milestone
          saved_to_database
          streamed
        ].freeze

        PARAMS.each do |param|
          define_method(param) do
            attributes[param]
          end
        end

        def initialize(path, opts = {})
          @path = path
          @attributes = {}

          # assign nil, for all unknown opts
          PARAMS.each do |param|
            @attributes[param] = opts[param]
          end
        end

        def key
          name.to_sym
        end

        private

        def validate_schema
          schema_errors = AUDIT_EVENT_TYPE_SCHEMA
                            .validate(attributes.to_h.deep_stringify_keys)
                            .map { |error| JSONSchemer::Errors.pretty(error) }

          errors.add(:base, schema_errors) if schema_errors.present?
        end

        def validate_file_name
          # ignoring Style/GuardClause because if we move this into one line, we cause Layout/LineLength errors
          # rubocop:disable Style/GuardClause
          unless File.basename(path, ".yml") == name
            errors.add(:base, "Audit event type '#{name}' has an invalid path: '#{path}'. " \
              "'#{name}' must match the filename")
          end
          # rubocop:enable Style/GuardClause
        end

        class << self
          def paths
            @paths ||= [Rails.root.join('config', 'audit_events', 'types', '*.yml')]
          end

          def definitions
            # We lazily load all definitions
            @definitions ||= load_all!
          end

          def get(key)
            definitions[key.to_sym]
          end

          private

          def load_all!
            paths.each_with_object({}) do |glob_path, definitions|
              load_all_from_path!(definitions, glob_path)
            end
          end

          def load_all_from_path!(definitions, glob_path)
            Dir.glob(glob_path).each do |path|
              definition = load_from_file(path)

              if previous = definitions[definition.key]
                raise InvalidAuditEventTypeError, "Audit event type '#{definition.key}' " \
                  "is already defined in '#{previous.path}'"
              end

              definitions[definition.key] = definition
            end
          end

          def load_from_file(path)
            definition = File.read(path)
            definition = YAML.safe_load(definition)
            definition.deep_symbolize_keys!

            new(path, definition).tap(&:validate!)
          rescue StandardError => e
            raise InvalidAuditEventTypeError, "Invalid definition for `#{path}`: #{e.message}"
          end
        end
      end
    end
  end
end

Gitlab::Audit::Type::Definition.prepend_mod
