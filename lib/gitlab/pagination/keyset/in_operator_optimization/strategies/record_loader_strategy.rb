# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      module InOperatorOptimization
        module Strategies
          class RecordLoaderStrategy
            RECORDS_COLUMN = 'records'

            def initialize(finder_query, model, order_by_columns)
              verify_order_by_attributes_on_model!(model, order_by_columns)

              @finder_query = finder_query
              @order_by_columns = order_by_columns
              @table_name = model.table_name
            end

            def initializer_columns
              ["NULL::#{table_name} AS #{RECORDS_COLUMN}"]
            end

            def columns
              query = finder_query
                .call(*order_by_columns.array_lookup_expressions_by_position(QueryBuilder::RECURSIVE_CTE_NAME))
                .select("#{table_name}")
                .limit(1)

              ["(#{query.to_sql})"]
            end

            def final_projections
              ["(#{RECORDS_COLUMN}).*"]
            end

            private

            attr_reader :finder_query, :order_by_columns, :table_name

            def verify_order_by_attributes_on_model!(model, order_by_columns)
              order_by_columns.map(&:column).each do |column|
                unless model.columns_hash[column.attribute_name.to_s]
                  text = <<~TEXT
                    The "RecordLoaderStrategy" does not support the following ORDER BY column because
                    it's not available on the \"#{model.table_name}\" table: #{column.attribute_name}

                    Omit the "finder_query" parameter to use the "OrderValuesLoaderStrategy".
                  TEXT
                  raise text
                end
              end
            end
          end
        end
      end
    end
  end
end
