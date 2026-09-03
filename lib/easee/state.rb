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

    # https://developer.easee.com/docs/charger-observation-ids
    OBSERVATION_IDS = {
      chargerOpMode: 109,
      isOnline: 250,
      totalPower: 120,
      sessionEnergy: 121,
      dynamicChargerCurrent: 48,
      lifetimeEnergy: 124,
    }.freeze

    def self.from_observations(observations)
      by_id = Array(observations).each_with_object({}) do |observation, result|
        observation = observation.symbolize_keys
        result[observation.fetch(:id)] = observation
      end

      new(
        chargerOpMode: by_id.dig(OBSERVATION_IDS.fetch(:chargerOpMode), :value)&.to_i,
        isOnline: coerce_boolean(by_id.dig(OBSERVATION_IDS.fetch(:isOnline), :value)),
        totalPower: by_id.dig(OBSERVATION_IDS.fetch(:totalPower), :value),
        sessionEnergy: by_id.dig(OBSERVATION_IDS.fetch(:sessionEnergy), :value),
        dynamicChargerCurrent: by_id.dig(OBSERVATION_IDS.fetch(:dynamicChargerCurrent), :value),
        lifetimeEnergy: by_id.dig(OBSERVATION_IDS.fetch(:lifetimeEnergy), :value)&.to_f,
        latestPulse: by_id.dig(OBSERVATION_IDS.fetch(:lifetimeEnergy), :timestamp),
      )
    end

    def self.coerce_boolean(value)
      [true, "true", 1, "1"].include?(value)
    end

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
