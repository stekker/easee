module Easee
  class State
    CHARGER_OP_MODES = {
      0 => :offline,
      1 => :disconnected,
      2 => :awaiting_start,
      3 => :charging,
      4 => :completed,
      5 => :error,
      6 => :ready_to_charge,
    }.freeze

    def initialize(data)
      @data = data.symbolize_keys
    end

    def charging? = charger_op_mode == :charging
    def disconnected? = charger_op_mode == :disconnected
    def online? = @data.fetch(:isOnline)

    def meter_reading
      MeterReading.new(
        reading_kwh: @data.fetch(:lifetimeEnergy),
        timestamp: Time.current,
      )
    end

    private

    def charger_op_mode = CHARGER_OP_MODES.fetch(@data.fetch(:chargerOpMode))
  end
end
