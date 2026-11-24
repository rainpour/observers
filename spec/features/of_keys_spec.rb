# frozen_string_literal: true

require_relative '../../lib/observers'

RSpec.describe 'Observers of keys' do
  let(:daily) { Class.new { include Observers } }
  let(:hourly) { Class.new { include Observers } }
  let(:page) { Class.new { include Observers } }

  before do
    Observers::Keys.reset
    daily.observe :daily
    daily.observe :hourly
    hourly.observe :hourly
    page.observe '/about'
  end

  it 'lists the observers of every key the block picks with each object once' do
    expect(Observers.of_keys { |key| key.is_a?(Symbol) }.map(&:object)).to eq([daily, hourly])
  end

  it 'lists none when the block picks no key' do
    expect(Observers.of_keys { false }).to eq([])
  end
end
