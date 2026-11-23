# frozen_string_literal: true

require_relative 'models/key'

module Observers
  class Keys
    class << self
      def [](key)
        keys[key] ||= Key.new(key:)
      end

      # The key when something observes it, without adding it when nothing does. Triggering a key that isn't kept means
      # it can be let go, like an event triggering on itself once per request.
      def find(key)
        keys[key]
      end

      def keys
        @keys ||= {}
        @keys
      end

      def reset
        @keys = {}
      end
    end
  end
end
