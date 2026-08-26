# frozen_string_literal: true

module TradeReputation
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace TradeReputation
    config.autoload_paths << File.join(config.root, "lib")
  end
end
