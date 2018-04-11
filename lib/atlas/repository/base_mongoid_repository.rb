# frozen_string_literal: true

module Atlas
  module Repository
    class BaseMongoidRepository
      I18N_SCOPE = %i[atlas repository base_mongoid_repository].freeze

      include Mixin::Create
      include Mixin::FindOne
      include Mixin::FindLast
      include Mixin::FindPaginated
      include Mixin::FindInBatchesEnum
      include Mixin::Transform
      include Mixin::Update
      include Mixin::Destroy

      def initialize(model:, entity:, notifier:)
        @model = model
        @entity = entity
        @notifier = notifier
      end

      protected

      attr_reader :model, :entity

      private

      attr_accessor :model, :entity, :notifier

      def wrap
        yield
      rescue Mongo::Error::OperationFailure => op_failure_err
        error(op_failure_err)
      rescue Mongoid::Errors::MongoidError => internal_err
        error(internal_err)
      end

      def error(message)
        notifier.send_error(message)
        Atlas::Repository::RepositoryResponse.new(data: { base: message }, success: false)
      end

      def apply_statements(sorting: [], filtering: [], pagination: {}, grouping: false)
        result = [
          [:apply_filter,     filtering],
          [:apply_group,      grouping],
          [:apply_order,      sorting]
        ].reduce(model) do |mod, (meth, param)|
          method(meth).call(mod, param)
        end

        paginated_result = apply_pagination(result, pagination)

        return { query: paginated_result, count: result.count } unless grouping

        count_query = model.collection.aggregate(result.pipeline)

        query = model.collection.aggregate(paginated_result.pipeline).each.map do |row|
          row.to_h.except('_id')
        end

        { query: query, count: count_query.count }
      end

      def apply_pagination(model, offset: nil, limit: nil)
        criteria = model
        criteria = criteria.offset(offset) if offset
        criteria = criteria.limit(limit) if limit
        criteria
      end

      def apply_order(model, sorting)
        sorting.present? ? model.order(OrderParser.order_params(model, sorting)) : model
      end

      def apply_filter(model, filtering)
        filtering ? model.where(FilterParser.filter_params(model, filtering)) : model.all
      end

      def apply_group(model, grouping)
        return model unless grouping

        GroupParser.group_params(model, grouping).reduce(model) do |cur, group|
          cur.group(group)
        end
      end

      def model_to_entity(element)
        return element if element.is_a?(Hash)
        entity_params = element.attributes.symbolize_keys
        entity ? entity.new(**entity_params) : entity_params
      end
    end
  end
end
