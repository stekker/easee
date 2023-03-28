RSpec.describe Easee::Client do
  describe "#pair" do
    it "pairs a new charger" do
      stub_token_request(user_name: "easee", password: "money")

      stub_request(:post, "https://api.easee.cloud/api/chargers/123ABC/pair?pinCode=1234")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(status: 200, body: "")

      client = Easee::Client.new(user_name: "easee", password: "money")

      expect { client.pair(charger_id: "123ABC", pin_code: "1234") }.not_to raise_error
    end
  end

  describe "#unpair" do
    it "unpairs a charger" do
      stub_token_request(user_name: "easee", password: "money")

      stub_request(:post, "https://api.easee.cloud/api/chargers/123ABC/unpair?pinCode=1234")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(status: 200, body: "")

      client = Easee::Client.new(user_name: "easee", password: "money")

      expect { client.unpair(charger_id: "123ABC", pin_code: "1234") }.not_to raise_error
    end
  end

  describe "#state" do
    it "fetches the state for a charger" do
      now = Time.zone.local(2023, 3, 27, 15, 21)
      Timecop.freeze(now)

      stub_token_request(user_name: "easee", password: "money")

      stub_request(:get, "https://api.easee.cloud/api/chargers/C123/state")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(
          status: 200,
          body: { chargerOpMode: 3, sessionEnergy: 23.67, isOnline: true }.to_json,
          headers: { "Content-Type": "application/json" },
        )

      client = Easee::Client.new(user_name: "easee", password: "money")

      state = client.state("C123")

      expect(state)
        .to have_attributes(
          charging?: true,
          disconnected?: false,
          online?: true,
        )

      expect(state.meter_reading).to have_attributes(reading_kwh: 23.67, timestamp: now)
    end
  end

  describe "#pause_charging" do
    it "sends a pause_charging command" do
      stub_token_request(user_name: "easee", password: "money")

      stub_request(:post, "https://api.easee.cloud/api/chargers/C123/commands/pause_charging")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(status: 200, body: "")

      client = Easee::Client.new(user_name: "easee", password: "money")

      expect { client.pause_charging("C123") }.not_to raise_error
    end
  end

  describe "#resume_charging" do
    it "sends a resume_charging command" do
      stub_token_request(user_name: "easee", password: "money")

      stub_request(:post, "https://api.easee.cloud/api/chargers/C123/commands/resume_charging")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(status: 200, body: "")

      client = Easee::Client.new(user_name: "easee", password: "money")

      expect { client.resume_charging("C123") }.not_to raise_error
    end
  end

  def stub_token_request(user_name: "easee", password: "money")
    stub_request(:post, "https://api.easee.cloud/api/accounts/login")
      .with(
        body: { userName: user_name, password: }.to_json,
      )
      .to_return(
        status: 200,
        body: { accessToken: "T123" }.to_json,
        headers: { "Content-Type": "application/json" },
      )
  end
end
