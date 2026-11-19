# frozen_string_literal: true

require_relative '../../lib/observers'

RSpec.describe 'A return action' do
  subject(:publisher) { Class.new { include Observers } }

  # Lets the request through, and adds to what comes back.
  let(:guard) do
    Class.new do
      def request = nil
      def response(event:, result:) = result << " checked by #{event}"
    end.new
  end
  let(:router) { Class.new { def request = +'page' }.new }
  let(:never) { Class.new { def response(**) = raise('never passed') }.new }
  let(:mirror) do
    Class.new do
      def mirror = nil
      def response(result:, **) = result << ' mirrored'
    end.new
  end

  before { Observers::Keys.reset }

  it 'gives each observer the take passed its result on the way back out, last first' do
    publisher.observers << guard
    publisher.observers.push(mirror, action: :mirror)
    publisher.observers << router
    publisher.observers << never

    expect(publisher.take(action: :request, event: 'the guard', returning: :response)).to eq('page mirrored checked by the guard')
  end

  it 'passes back nil when nothing answered' do
    results = []
    publisher.observers << Class.new { define_method(:response) { |result:, **| results << result } }.new

    expect([publisher.take(action: :request, returning: :response), results]).to eq([nil, [nil]])
  end
end
