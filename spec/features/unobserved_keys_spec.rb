# frozen_string_literal: true

require_relative '../../lib/observers'

RSpec.describe 'Unobserved keys' do
  # Like an event, which triggers on itself and should be let go after.
  let(:publisher_class) { Class.new { include Observers } }
  let(:subscriber) { Class.new { def handle = 'handled' }.new }

  before { Observers::Keys.reset }

  it "doesn't keep a key that's triggered but not observed" do
    publisher = publisher_class.new

    expect([publisher.trigger(action: :handle), Observers::Keys.keys]).to eq([nil, {}])
  end

  it "doesn't keep a key that's taken but not observed" do
    publisher = publisher_class.new

    expect([publisher.take(action: :handle, returning: :response), Observers::Keys.keys]).to eq([nil, {}])
  end

  it "doesn't keep a key whose observers are only counted or listed" do
    observers = publisher_class.new.observers

    expect([observers.count, observers.to_a, Observers::Keys.keys]).to eq([0, [], {}])
  end

  it 'lets an object that triggered on itself be garbage collected' do
    count = lambda do
      GC.start
      ObjectSpace.each_object(publisher_class).count
    end
    before = count.call

    100.times { publisher_class.new.trigger(action: :handle) }

    expect(count.call - before).to be < 100
  end

  it 'still triggers and takes on observed keys' do
    publisher = publisher_class.new
    publisher.observers << subscriber

    expect([publisher.trigger(action: :handle), publisher.take(action: :handle)]).to eq(%w[handled handled])
  end
end
