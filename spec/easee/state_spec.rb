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
      expect(Easee::State.new(chargerOpMode: 99)).not_to be_charging
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

  describe "#awaiting_start?" do
    it "returns true when the charger op mode is :awaiting_start" do
      expect(Easee::State.new(chargerOpMode: 2)).to be_awaiting_start
    end

    it "returns false when charging" do
      expect(Easee::State.new(chargerOpMode: 3)).not_to be_awaiting_start
    end
  end

  describe "#charger_op_mode" do
    it "returns the symbolic op mode" do
      expect(Easee::State.new(chargerOpMode: 3).charger_op_mode).to eq(:charging)
    end

    it "maps awaiting authentication (7)" do
      expect(Easee::State.new(chargerOpMode: 7).charger_op_mode).to eq(:awaiting_authentication)
    end

    it "maps de-authenticating (8)" do
      expect(Easee::State.new(chargerOpMode: 8).charger_op_mode).to eq(:de_authenticating)
    end

    it "returns :unknown for unmapped op modes" do
      expect(Easee::State.new(chargerOpMode: 99).charger_op_mode).to eq(:unknown)
    end
  end

  describe "#total_power" do
    it "returns the total charging power as a float" do
      expect(Easee::State.new(totalPower: 7.4).total_power).to eq(7.4)
    end
  end

  describe "#session_energy" do
    it "returns the session energy as a float" do
      expect(Easee::State.new(sessionEnergy: 12.34).session_energy).to eq(12.34)
    end
  end

  describe "#dynamic_charger_current" do
    it "returns the dynamic charger current as a float" do
      expect(Easee::State.new(dynamicChargerCurrent: 16.0).dynamic_charger_current).to eq(16.0)
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
