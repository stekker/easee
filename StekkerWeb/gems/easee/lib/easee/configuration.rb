module Easee
  class Configuration
    def initialize(data)
      @data = data.symbolize_keys
    end

    def number_of_phases = @data.fetch(:phaseMode)
    def max_current_amp = @data.fetch(:maxChargerCurrent)
  end
end
