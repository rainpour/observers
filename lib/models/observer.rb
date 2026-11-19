# frozen_string_literal: true

require_relative 'observer_error'

module Observers
  class Observer
    attr_reader :object, :action

    def initialize(object:, action:)
      @object = object
      @action = action
    end

    def trigger(action:, event:)
      action = @action if @action

      return unless @object.respond_to?(action)

      # Assumption that if method has params then that param is "event:".
      if event && @object.method(action).parameters.count > 0
        @object.send(action, **{ event: })
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
  end
end
