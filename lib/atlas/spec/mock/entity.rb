module Atlas
  module Spec
    module Mock
      Entity = lambda do |*params|
        Class.new(Atlas::Entity::BaseEntity) do
          parameters(*params)
        end
      end
    end
  end
end
