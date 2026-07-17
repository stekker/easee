module Easee
  class Session
    def initialize(data)
      @data = data.symbolize_keys
    end

    def id = @data.fetch(:sessionId)

    def energy = @data.fetch(:sessionEnergy).to_f

    def session_start = parse_time(:sessionStart)
    def session_end = parse_time(:sessionEnd)

    private

    def parse_time(key)
      value = @data[key]
      return if value.nil?

      Time.zone.parse(value)
    end
  end
end
