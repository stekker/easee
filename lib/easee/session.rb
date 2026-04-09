module Easee
  class Session
    def initialize(data)
      @data = data.symbolize_keys
    end

    def id = @data.fetch(:id)

    def energy = @data.fetch(:kiloWattHours).to_f
  end
end
