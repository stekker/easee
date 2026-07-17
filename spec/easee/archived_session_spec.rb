RSpec.describe Easee::ArchivedSession do
  it "exposes the session fields" do
    session = described_class.new(
      "id" => 387,
      "chargerId" => "EH98AAGY",
      "carConnected" => "2026-01-02T19:23:23Z",
      "carDisconnected" => "2026-01-03T11:57:00Z",
      "firstEnergyTransferPeriodStarted" => "2026-01-02T20:00:05+00:00",
      "lastEnergyTransferPeriodEnd" => "2026-01-03T11:57:00+00:00",
      "kiloWattHours" => 29.155331,
      "actualDurationSeconds" => 10558,
      "isComplete" => true,
      "authToken" => "FD2ACA9C",
      "authUser" => 709817,
    )

    expect(session).to have_attributes(
      id: 387,
      charger_id: "EH98AAGY",
      car_connected: Time.zone.parse("2026-01-02T19:23:23Z"),
      car_disconnected: Time.zone.parse("2026-01-03T11:57:00Z"),
      first_energy_transfer_period_started: Time.zone.parse("2026-01-02T20:00:05Z"),
      last_energy_transfer_period_end: Time.zone.parse("2026-01-03T11:57:00Z"),
      energy_kwh: 29.155331,
      duration_seconds: 10558,
      complete?: true,
      auth_token: "FD2ACA9C",
      auth_user: 709817,
    )
  end

  it "treats missing car_connected and car_disconnected as nil" do
    session = described_class.new(
      "id" => 388,
      "chargerId" => "EH98AAGY",
      "kiloWattHours" => 0.0,
      "isComplete" => false,
    )

    expect(session).to have_attributes(
      car_connected: nil,
      car_disconnected: nil,
      first_energy_transfer_period_started: nil,
      last_energy_transfer_period_end: nil,
      complete?: false,
    )
  end
end
