RSpec.describe Easee::State do
  describe "#charging?" do
    it "returns true when the charger op mode is :charging" do
      expect(Easee::State.new(chargerOpMode: 3)).to be_charging
    end

    it "returns false when the charger op mode is :awaiting_start" do
      expect(Easee::State.new(chargerOpMode: 2)).not_to be_charging
    end

    it "returns false for all other charger op modes" do
      expect(Easee::State.new(chargerOpMode: 4)).not_to be_charging
    end

    it "does not fail for unknown op modes" do
      expect(Easee::State.new(chargerOpMode: 7)).not_to be_charging
    end
  end

  describe "#disconnected?" do
    it "returns true when the charger op mode is :disconnected" do
      expect(Easee::State.new(chargerOpMode: 1)).to be_disconnected
    end

    it "returns false for all other charger op modes" do
      expect(Easee::State.new(chargerOpMode: 6)).not_to be_disconnected
    end
  end

  describe "#online?" do
    it "returns true when the charger is online" do
      expect(Easee::State.new(isOnline: true)).to be_online
    end

    it "returns false when the charger is offline" do
      expect(Easee::State.new(isOnline: false)).not_to be_online
    end
  end

  describe "#meter_reading" do
    it "returns a meter reading using the delivered session power" do
      now = Time.zone.local(2023, 3, 27, 15, 21)
      Timecop.freeze(now)

      state = Easee::State.new(lifetimeEnergy: 23.67, latestPulse: "2023-03-27T15:21:00.000Z")

      expect(state.meter_reading).to have_attributes(reading_kwh: 23.67, timestamp: now)
    end
  end
end
