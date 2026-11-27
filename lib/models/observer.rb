# frozen_string_literal: true

require_relative 'observer_error'

module Observers
  class Observer
    attr_reader :object, :action

    def initialize(object:, action:)
      @object = object
      @action = action
      @takes_event = {}
    end

    def trigger(action:, event:)
      action = @action if @action

      return unless @object.respond_to?(action)

      if event && takes_event?(action)
        @object.send(action, event:)
      else
        @object.send(action)
      end
    rescue StandardError => e
      # Events trigger events, so this error bubbles up to become the error for the next rescue:
      # "RequestEvent -> Rain::Router#route_request -> StatusEvent -> Error404Node.render -> unknown keyword: :props"
      raise ObserverError.new(e.message, object:, event:, action:, previous_error: e)
    end

    # Gives the object a take's result on its way back out. The observer's own action doesn't apply, as it's for the
    # way in.
    def pass_back(action:, event:, result:)
      return unless @object.respond_to?(action)

      @object.send(action, event:, result:)
    rescue StandardError => e
      raise ObserverError.new(e.message, object:, event:, action:, previous_error: e)
    end

    private

    # Assumes that if the method has params then that param is "event:". Looked up on the first trigger rather than on
    # every one, as Object#method makes a new Method each time, and by then gems like LowType have redefined methods.
    def takes_event?(action)
      @takes_event.fetch(action) { @takes_event[action] = @object.method(action).parameters.any? }
    end
  end
end
