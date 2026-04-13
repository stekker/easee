module Easee
  class Session
    def initialize(data)
      @data = data.symbolize_keys
    end

    def id = @data.fetch(:sessionId)

    def energy = @data.fetch(:sessionEnergy).to_f
  end
end
