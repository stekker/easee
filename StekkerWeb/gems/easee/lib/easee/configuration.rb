module Easee
  class Configuration
    def initialize(data)
      @data = data.symbolize_keys
    end

    def phase_mode = @data.fetch(:phaseMode)
    def max_charger_current = @data.fetch(:maxChargerCurrent)
  end
end
