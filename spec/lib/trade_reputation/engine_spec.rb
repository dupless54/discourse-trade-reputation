# frozen_string_literal: true

describe TradeReputation::Engine do
  it "registers the plugin's lib directory as an autoload path" do
    expected_path = File.join(described_class.config.root, "lib")

    expect(described_class.config.autoload_paths).to include(expected_path)
  end
end
