module Easee
  class State
    OP_MODE_UNKNOWN = :unknown

    CHARGER_OP_MODES = {
      0 => :offline,
      1 => :disconnected,
      2 => :awaiting_start,
      3 => :charging,
      4 => :completed,
      5 => :error,
      6 => :ready_to_charge,
      7 => :awaiting_authentication,
      8 => :de_authenticating,
    }.freeze

    def initialize(data)
      @data = data.symbolize_keys
    end

    def charging? = charger_op_mode == :charging
    def disconnected? = charger_op_mode == :disconnected
    def awaiting_start? = charger_op_mode == :awaiting_start
    def online? = @data.fetch(:isOnline)

    def charger_op_mode
      numeric_op_mode = @data.fetch(:chargerOpMode)
      CHARGER_OP_MODES.fetch(numeric_op_mode) { OP_MODE_UNKNOWN }
    end

    def total_power = @data.fetch(:totalPower).to_f

    def session_energy = @data.fetch(:sessionEnergy).to_f

    def dynamic_charger_current = @data.fetch(:dynamicChargerCurrent).to_f

    def meter_reading
      MeterReading.new(
        reading_kwh: @data.fetch(:lifetimeEnergy),
        timestamp: Time.zone.parse(@data.fetch(:latestPulse)),
      )
    end
  end
end
