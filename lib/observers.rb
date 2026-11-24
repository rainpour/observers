# frozen_string_literal: true

require_relative 'keys'
require_relative 'models/observer'

module Observers
  Config = Struct.new(:empty_observers_callback)

  class << self
    def [](key)
      Keys[key].observers
    end

    # The observers of every key the block picks with each object once. Like every interval's for an event observed by
    # many keys.
    def of_keys
      Keys.keys.to_a.flat_map { |key, observed| yield(key) ? observed.observers : [] }.uniq(&:object)
    end

    def included(klass)
      klass.extend Observers
    end

    def config
      @config ||= Config.new(empty_observers_callback: nil)
    end

    def configure
      yield(config)
    end
  end

  def observers(key = self)
    Struct.new(:key) do
      def push(object, action: nil)
        Keys[key].observe(object:, action:)
      end
      alias :<< :push

      def count
        Keys.find(key)&.observers&.count || 0
      end

      # The observers in order, so a list can be made from them, like [MyLogger, *observers].
      def to_a
        Keys.find(key)&.observers.dup || []
      end

      # Puts the observers in a new order, like replace([MyLogger, *observers]), keeping each one's action.
      def replace(objects)
        Keys[key].replace(objects:)
      end
    end.new(key)
  end

  # Observe a key with "observe key, action: :action", or keys and their actions with "observe key => :action".
  # Ruby passes "key => :action" as keyword arguments when the key isn't a symbol, so they arrive in key_actions.
  def observe(key = nil, action: nil, **key_actions)
    key_actions = key.is_a?(Hash) ? key : { key => action } unless key.nil?
    raise ArgumentError, 'Missing key to observe' if key_actions.empty?

    key_actions.each { |each_key, each_action| Keys[each_key].observe(object: self, action: each_action) }
  end

  # Nothing happens for a key that nothing observes, and the key isn't kept, so an object that triggers on itself, like
  # an event, can still be let go.
  def trigger(key: self, action: nil, event: nil)
    Keys.find(key)&.trigger(action:, event:)
  end

  def take(key: self, action: nil, event: nil, returning: nil)
    Keys.find(key)&.take(action:, event:, returning:)
  end

  # TODO: Provide a "pipe/port/take" method that uses ractors to be concurrent... if supplied with immutable Data?
end
