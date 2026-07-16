RSpec.describe Easee::Session do
  it "exposes the session fields" do
    session = described_class.new(
      "sessionId" => 12345,
      "sessionEnergy" => 3.42,
      "sessionStart" => "2026-01-05T10:00:00Z",
      "sessionEnd" => "2026-01-05T11:30:00Z",
    )

    expect(session).to have_attributes(
      id: 12345,
      energy: 3.42,
      session_start: Time.zone.parse("2026-01-05T10:00:00Z"),
      session_end: Time.zone.parse("2026-01-05T11:30:00Z"),
    )
  end

  it "returns nil for session_start and session_end when the fields are missing or null" do
    session = described_class.new(
      "sessionId" => 12345,
      "sessionEnergy" => 0.0,
      "sessionStart" => nil,
      "sessionEnd" => nil,
    )

    expect(session).to have_attributes(
      session_start: nil,
      session_end: nil,
    )
  end
end
