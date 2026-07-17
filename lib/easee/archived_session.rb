module Easee
  class ArchivedSession
    def initialize(data)
      @data = data.deep_symbolize_keys
    end

    def id = @data.fetch(:id)
    def charger_id = @data.fetch(:chargerId)

    def car_connected = parse_time(:carConnected)
    def car_disconnected = parse_time(:carDisconnected)
    def first_energy_transfer_period_started = parse_time(:firstEnergyTransferPeriodStarted)
    def last_energy_transfer_period_end = parse_time(:lastEnergyTransferPeriodEnd)

    def energy_kwh = @data.fetch(:kiloWattHours).to_f
    def duration_seconds = @data[:actualDurationSeconds]

    def complete? = @data.fetch(:isComplete, false)

    def auth_token = @data[:authToken]
    def auth_user = @data[:authUser]

    private

    def parse_time(key)
      value = @data[key]
      return if value.nil?

      Time.zone.parse(value)
    end
  end
end
