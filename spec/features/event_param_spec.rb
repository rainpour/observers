# frozen_string_literal: true

require_relative '../../lib/models/observer'

RSpec.describe Observers::Observer do
  let(:object) do
    Class.new do
      def with_event(event:) = [:with_event, event]
      def without_event = :without_event
    end.new
  end

  it 'passes the event to a method that takes one' do
    expect(described_class.new(object:, action: nil).trigger(action: :with_event, event: :event)).to eq(%i[with_event event])
  end

  it "doesn't pass the event to a method that takes none" do
    expect(described_class.new(object:, action: nil).trigger(action: :without_event, event: :event)).to eq(:without_event)
  end

  it "looks up the method's params on the first trigger only" do
    observer = described_class.new(object:, action: nil)
    expect(object).to receive(:method).once.and_call_original

    3.times { observer.trigger(action: :with_event, event: :event) }
  end
end
