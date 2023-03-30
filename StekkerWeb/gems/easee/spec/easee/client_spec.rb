RSpec.describe Easee::Client do
  describe "authentication" do
    it "obtains and uses a new access token when none is provided" do
      user_name = "easee"
      password = "money"
      token_cache = ThreadSafe::Cache.new
      tokens = { "accessToken" => "T123" }

      stub_request(:post, "https://api.easee.cloud/api/accounts/login")
        .with(
          body: { userName: user_name, password: }.to_json,
        )
        .to_return(
          status: 200,
          body: tokens.to_json,
          headers: { "Content-Type": "application/json" },
        )

      stub_request(:post, "https://api.easee.cloud/api/chargers/123ABC/pair?pinCode=1234")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(status: 200, body: "")

      client = Easee::Client.new(user_name:, password:, token_cache:)

      expect { client.pair(charger_id: "123ABC", pin_code: "1234") }
        .to change { token_cache[:tokens] }
        .from(nil)
        .to(tokens)
    end

    it "refreshes the access token and uses the new one when it is expired" do
      user_name = "easee"
      password = "money"
      token_cache = ThreadSafe::Cache.new
      current_tokens = { "accessToken" => "T123", "refreshToken" => "R456" }
      token_cache[:tokens] = current_tokens
      new_tokens = { "accessToken" => "T789" }

      stub_request(:post, "https://api.easee.cloud/api/chargers/123ABC/pair?pinCode=1234")
        .to_return(
          { status: 401, body: "Invalid token" },
          { status: 200, body: "" },
        )

      stub_request(:post, "https://api.easee.cloud/api/accounts/refresh_token")
        .with(
          body: { accessToken: "T123", refreshToken: "R456" }.to_json,
        )
        .to_return(
          status: 200,
          body: new_tokens.to_json,
          headers: { "Content-Type": "application/json" },
        )

      client = Easee::Client.new(user_name:, password:, token_cache:)

      expect { client.pair(charger_id: "123ABC", pin_code: "1234") }
        .to change { token_cache[:tokens] }
        .from(current_tokens)
        .to(new_tokens)
    end

    it "only tries to refresh the access token once" do
      user_name = "easee"
      password = "money"
      token_cache = ThreadSafe::Cache.new
      current_tokens = { "accessToken" => "T123", "refreshToken" => "R456" }
      token_cache[:tokens] = current_tokens
      new_tokens = { "accessToken" => "T789", "refreshToken" => "R654" }

      stub_request(:post, "https://api.easee.cloud/api/chargers/123ABC/pair?pinCode=1234")
        .to_return(
          { status: 401, body: "Invalid token" },
          { status: 401, body: "Invalid token" },
        )

      stub_request(:post, "https://api.easee.cloud/api/accounts/refresh_token")
        .with(
          body: { accessToken: "T123", refreshToken: "R456" }.to_json,
        )
        .to_return(
          status: 200,
          body: new_tokens.to_json,
          headers: { "Content-Type": "application/json" },
        )

      client = Easee::Client.new(user_name:, password:, token_cache:)

      expect { client.pair(charger_id: "123ABC", pin_code: "1234") }.to raise_error(Easee::Errors::RequestFailed)
    end

    it "fails when the acess token could not be refreshed" do
      user_name = "easee"
      password = "money"
      token_cache = ThreadSafe::Cache.new
      current_tokens = { "accessToken" => "T123", "refreshToken" => "R456" }
      token_cache[:tokens] = current_tokens

      stub_request(:post, "https://api.easee.cloud/api/chargers/123ABC/pair?pinCode=1234")
        .to_return(
          status: 401, body: "Invalid token",
        )

      stub_request(:post, "https://api.easee.cloud/api/accounts/refresh_token")
        .with(
          body: { accessToken: "T123", refreshToken: "R456" }.to_json,
        )
        .to_return(
          status: 401,
          body: {
            errorCode: 104,
            errorCodeName: "InvalidRefreshToken",
          }.to_json,
          headers: { "Content-Type": "application/json" },
        )

      client = Easee::Client.new(user_name:, password:, token_cache:)

      expect { client.pair(charger_id: "123ABC", pin_code: "1234") }
        .to raise_error(Easee::Errors::RequestFailed)
    end
  end

  describe "#pair" do
    it "pairs a new charger" do
      token_cache = ThreadSafe::Cache.new.tap { |x| x[:tokens] = { "accessToken" => "T123" } }

      stub_request(:post, "https://api.easee.cloud/api/chargers/123ABC/pair?pinCode=1234")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(status: 200, body: "")

      client = Easee::Client.new(user_name: "easee", password: "money", token_cache:)

      expect { client.pair(charger_id: "123ABC", pin_code: "1234") }.not_to raise_error
    end
  end

  describe "#unpair" do
    it "unpairs a charger" do
      token_cache = ThreadSafe::Cache.new.tap { |x| x[:tokens] = { "accessToken" => "T123" } }

      stub_request(:post, "https://api.easee.cloud/api/chargers/123ABC/unpair?pinCode=1234")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(status: 200, body: "")

      client = Easee::Client.new(user_name: "easee", password: "money", token_cache:)

      expect { client.unpair(charger_id: "123ABC", pin_code: "1234") }.not_to raise_error
    end
  end

  describe "#state" do
    it "fetches the state for a charger" do
      now = Time.zone.local(2023, 3, 27, 15, 21)
      Timecop.freeze(now)

      token_cache = ThreadSafe::Cache.new.tap { |x| x[:tokens] = { "accessToken" => "T123" } }

      stub_request(:get, "https://api.easee.cloud/api/chargers/C123/state")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(
          status: 200,
          body: { chargerOpMode: 3, sessionEnergy: 23.67, isOnline: true }.to_json,
          headers: { "Content-Type": "application/json" },
        )

      client = Easee::Client.new(user_name: "easee", password: "money", token_cache:)

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
      token_cache = ThreadSafe::Cache.new.tap { |x| x[:tokens] = { "accessToken" => "T123" } }

      stub_request(:post, "https://api.easee.cloud/api/chargers/C123/commands/pause_charging")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(status: 200, body: "")

      client = Easee::Client.new(user_name: "easee", password: "money", token_cache:)

      expect { client.pause_charging("C123") }.not_to raise_error
    end
  end

  describe "#resume_charging" do
    it "sends a resume_charging command" do
      token_cache = ThreadSafe::Cache.new.tap { |x| x[:tokens] = { "accessToken" => "T123" } }

      stub_request(:post, "https://api.easee.cloud/api/chargers/C123/commands/resume_charging")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(status: 200, body: "")

      client = Easee::Client.new(user_name: "easee", password: "money", token_cache:)

      expect { client.resume_charging("C123") }.not_to raise_error
    end
  end
end
