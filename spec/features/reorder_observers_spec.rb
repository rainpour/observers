# frozen_string_literal: true

require_relative '../../lib/observers'

RSpec.describe 'Reordering observers' do
  subject(:publisher) { Class.new { include Observers } }

  let(:first) { Class.new { def handle = 'first' }.new }
  let(:mirror) { Class.new { def mirror = 'mirror' }.new }

  before do
    Observers::Keys.reset
    publisher.observers << first
    publisher.observers.push(mirror, action: :mirror)
  end

  it 'puts an object first, keeping the others and their actions' do
    logger = Class.new { def handle = 'logger' }.new
    observers = publisher.observers
    observers.replace([logger, *observers])

    expect([publisher.observers.to_a.map(&:object), publisher.observers.to_a.last.action]).to eq([[logger, first, mirror], :mirror])
  end

  it 'lets the first object answer' do
    publisher.observers.replace([Class.new { def handle = 'logger' }.new, *publisher.observers])

    expect(publisher.take).to eq('logger')
  end
end
