# frozen_string_literal: true

module Shared
  class Entity
    attr_reader :id

    def initialize(id:)
      @id = id
    end

    def ==(other)
      other.instance_of?(self.class) && other.id == id
    end

    alias eql? ==

    def hash
      [ self.class, id ].hash
    end
  end
end
