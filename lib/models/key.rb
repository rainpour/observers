# frozen_string_literal: true

module Observers
  class NoObserversError < StandardError; end

  class Key
    attr_reader :observers

    def initialize(key:)
      @key = key
      @observers = []
    end

    def observe(object:, action:)
      # TODO: We can observe objects directly, no need to wrap in an observer, unless need to let the object's observer override the action?
      # A future reason I can think of for keeping observer wrapper is to track whether the object has implemented certain actions/methods.
      @observers << Observer.new(object:, action:)
    end

    # The observers in a new order. Each is an observer already, which keeps its action, or an object to observe.
    def replace(objects:)
      @observers = objects.map { |object| object.is_a?(Observer) ? object : Observer.new(object:, action: nil) }
    end

    # @returns: The result of the last observer with a non-nil value.
    def trigger(action: nil, event: nil)
      # TODO: Breaks some tests... should it? Yes. Should it be disabled when testing? Yes.
      # raise NoObserversError, "No observers configured for #{@key}" if @observers.empty?

      last_result = nil

      per_observer_per_action(action:, event:) do |observer, action|
        result = observer.trigger(action:, event:)
        last_result = result unless result.nil?
        yield if block_given?
      end

      last_result
    end

    # @returns: The result of the first observer and the first action with a non-nil value.
    # With "returning: :action", each observer the take passed, last first, is then given that result on its way back
    # out, with "action(event:, result:)", when it has that action.
    def take(action: nil, event: nil, returning: nil)
      # TODO: Breaks some tests... should it? Yes. Should it be disabled when testing? Yes.
      # raise NoObserversError, "No observers configured for #{@key}" if @observers.empty?

      passed = []
      result = nil
      per_observer_per_action(action:, event:) do |observer, action|
        passed |= [observer]
        result = observer.trigger(action:, event:)
        yield if block_given?
        break unless result.nil?
      end

      passed.reverse_each { |observer| observer.pass_back(action: returning, event:, result:) } if returning
      result
    end

    private

    def per_observer_per_action(action:, event:)
      action ||= event&.action

      if action
        @observers.each do |observer|
          yield observer, action
        end
      elsif event&.actions
        @observers.each do |observer|
          event.actions.each do |action|
            yield observer, action
          end
        end
      else
        @observers.each do |observer|
          yield observer, :handle
        end
      end
    end
  end
end
