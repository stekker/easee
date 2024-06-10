RSpec.describe Easee::Client do
  describe "authentication" do
    it "obtains and uses a new access token when none is provided" do
      user_name = "easee"
      password = "money"
      token_cache = ActiveSupport::Cache::MemoryStore.new
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
        .to change { token_cache.fetch(Easee::Client::TOKENS_CACHE_KEY) }
        .from(nil)
        .to(tokens.to_json)
    end

    it "refreshes the access token and uses the new one when it is expired" do
      user_name = "easee"
      password = "money"
      token_cache = ActiveSupport::Cache::MemoryStore.new
      current_tokens = { "accessToken" => "T123", "refreshToken" => "R456" }
      token_cache.write(Easee::Client::TOKENS_CACHE_KEY, current_tokens.to_json)
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
        .to change { token_cache.fetch(Easee::Client::TOKENS_CACHE_KEY) }
        .from(current_tokens.to_json)
        .to(new_tokens.to_json)
    end

    it "only tries to refresh the access token once" do
      user_name = "easee"
      password = "money"
      token_cache = ActiveSupport::Cache::MemoryStore.new
      current_tokens = { "accessToken" => "T123", "refreshToken" => "R456" }
      token_cache.write(Easee::Client::TOKENS_CACHE_KEY, current_tokens.to_json)
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
      token_cache = ActiveSupport::Cache::MemoryStore.new
      current_tokens = { "accessToken" => "T123", "refreshToken" => "R456" }
      token_cache.write(Easee::Client::TOKENS_CACHE_KEY, current_tokens.to_json)

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

    it "uses the encryptor to encrypt the tokens" do
      user_name = "easee"
      password = "money"
      token_cache = ActiveSupport::Cache::MemoryStore.new
      tokens = { "accessToken" => "T123" }

      encryptor = instance_double(Easee::NullEncryptor)
      allow(encryptor).to receive_messages(encrypt: "encrypted", decrypt: tokens.to_json)

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

      client = Easee::Client.new(user_name:, password:, token_cache:, encryptor:)

      expect { client.pair(charger_id: "123ABC", pin_code: "1234") }
        .to change { token_cache.fetch(Easee::Client::TOKENS_CACHE_KEY) }
        .from(nil)
        .to("encrypted")

      expect(encryptor).to have_received(:encrypt).with(tokens.to_json, cipher_options: { deterministic: true })
      expect(encryptor).to have_received(:decrypt).with("encrypted")
    end

    it "raises when the access token could not be obtained" do
      user_name = "test"
      password = "wrong"

      stub_request(:post, "https://api.easee.cloud/api/accounts/login")
        .with(
          body: { userName: user_name, password: }.to_json,
        )
        .to_return(
          status: 400,
          body: {
            errorCode: 100,
            errorCodeName: "InvalidUserPassword",
            type: nil,
            title: "Username or password is invalid",
            status: 400,
            detail: "[Empty in production]",
            instance: nil,
            extensions: {},
          }.to_json,
          headers: { "Content-Type": "application/json" },
        )

      client = Easee::Client.new(user_name:, password:)

      expect { client.pair(charger_id: "123ABC", pin_code: "1234") }
        .to raise_error(Easee::Errors::InvalidCredentials)
    end
  end

  describe "#login" do
    it "returns the access token when credentials are valid" do
      user_name = "easee"
      password = "money"

      stub_request(:post, "https://api.easee.cloud/api/accounts/login")
        .with(
          body: { userName: user_name, password: }.to_json,
        )
        .to_return(
          status: 200,
          body: { accessToken: "T123" }.to_json,
          headers: { "Content-Type": "application/json" },
        )

      client = Easee::Client.new(user_name:, password:)

      expect(client.login).to eq("accessToken" => "T123")
    end

    it "raises InvalidCredentials when the credentials are invalid" do
      user_name = "test"
      password = "wrong"

      stub_request(:post, "https://api.easee.cloud/api/accounts/login")
        .with(
          body: { userName: user_name, password: }.to_json,
        )
        .to_return(
          status: 400,
          body: {
            errorCode: 100,
            errorCodeName: "InvalidUserPassword",
            type: nil,
            title: "Username or password is invalid",
            status: 400,
            detail: "[Empty in production]",
            instance: nil,
            extensions: {},
          }.to_json,
          headers: { "Content-Type": "application/json" },
        )

      client = Easee::Client.new(user_name:, password:)

      expect { client.login }
        .to raise_error(Easee::Errors::InvalidCredentials)
    end

    it "raises Forbidden errors when the request is rerouted with X-Amzn-Errortype: ForbiddenException" do
      user_name = "test"
      password = "old"

      stub_request(:post, "https://api.easee.cloud/api/accounts/login")
        .with(
          body: { userName: user_name, password: }.to_json,
        )
        .to_return(
          status: 301,
          headers: {
            Date: "Fri, 07 Jun 2024 07:30:02 GMT",
            "Content-Type": "application/json",
            "Content-Length": "0",
            Connection: "keep-alive",
            "X-Amzn-Requestid": "aaa0a000-000a-0000-a0a0-00000a00aa00",
            "X-Amzn-Errortype": "ForbiddenException",
            "X-Amz-Apigw-Id": "A_AAAAa0aaAAAaa=",
            "X-Easee-Key": "a00a0000-0a0a-0a0a-aa00-0a0000a0a0a0",
            Location: "https://blackhole.easee.com",
          },
        )

      client = Easee::Client.new(user_name:, password:)

      expect { client.login }
        .to raise_error(Easee::Errors::Forbidden)
    end
  end

  describe "#pair" do
    it "pairs a new charger" do
      token_cache = ActiveSupport::Cache::MemoryStore.new
      token_cache.write(
        Easee::Client::TOKENS_CACHE_KEY,
        { "accessToken" => "T123" }.to_json,
      )

      stub_request(:post, "https://api.easee.cloud/api/chargers/123ABC/pair?pinCode=1234")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(status: 200, body: "")

      client = Easee::Client.new(user_name: "easee", password: "money", token_cache:)

      expect { client.pair(charger_id: "123ABC", pin_code: "1234") }.not_to raise_error
    end
  end

  describe "#unpair" do
    it "unpairs a charger" do
      token_cache = ActiveSupport::Cache::MemoryStore.new
      token_cache.write(
        Easee::Client::TOKENS_CACHE_KEY,
        { "accessToken" => "T123" }.to_json,
      )

      stub_request(:post, "https://api.easee.cloud/api/chargers/123ABC/unpair?pinCode=1234")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(status: 200, body: "")

      client = Easee::Client.new(user_name: "easee", password: "money", token_cache:)

      expect { client.unpair(charger_id: "123ABC", pin_code: "1234") }.not_to raise_error
    end
  end

  describe "#chargers" do
    it "fetches all chargers accessible for the account" do
      token_cache = ActiveSupport::Cache::MemoryStore.new
      token_cache.write(
        Easee::Client::TOKENS_CACHE_KEY,
        { "accessToken" => "T123" }.to_json,
      )

      stub_request(:get, "https://api.easee.cloud/api/chargers")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(
          status: 200,
          body: [
            {
              id: "EASEE123",
              name: "John's charger",
              color: 1,
              productCode: 1,
            },
            {
              id: "EASEE456",
              name: "Mary's charger",
              color: 3,
              productCode: 100,
            },
          ].to_json,
          headers: { "Content-Type": "application/json" },
        )

      client = Easee::Client.new(user_name: "easee", password: "money", token_cache:)

      chargers = client.chargers

      expect(chargers[0]).to have_attributes(
        id: "EASEE123",
        name: "John's charger",
        color: 1,
        product_code: 1,
      )

      expect(chargers[1]).to have_attributes(
        id: "EASEE456",
        name: "Mary's charger",
        color: 3,
        product_code: 100,
      )
    end
  end

  describe "#configuration" do
    it "fetches the technical configuration" do
      token_cache = ActiveSupport::Cache::MemoryStore.new
      token_cache.write(
        Easee::Client::TOKENS_CACHE_KEY,
        { "accessToken" => "T123" }.to_json,
      )

      stub_request(:get, "https://api.easee.cloud/api/chargers/C123/config")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(
          status: 200,
          body: { phaseMode: 2, maxChargerCurrent: 32 }.to_json,
          headers: { "Content-Type": "application/json" },
        )

      client = Easee::Client.new(user_name: "easee", password: "money", token_cache:)

      configuration = client.configuration("C123")

      expect(configuration)
        .to have_attributes(
          phase_mode: 2,
          max_charger_current: 32,
        )
    end
  end

  describe "#site" do
    it "fetches name/address/location info" do
      token_cache = ActiveSupport::Cache::MemoryStore.new
      token_cache.write(
        Easee::Client::TOKENS_CACHE_KEY,
        { "accessToken" => "T123" }.to_json,
      )

      stub_request(:get, "https://api.easee.cloud/api/chargers/C123/site")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(
          status: 200,
          body: {
            name: "Home charger",
            address: {
              street: "Lindelaan",
              buildingNumber: "31",
              zip: "1234 Ab",
              area: "Laderburg",
              country: {
                id: "NL",
                name: "Netherlands",
              },
              latitude: 51.949433,
              longitude: 5.231064,
            },
          }.to_json,
          headers: { "Content-Type": "application/json" },
        )

      client = Easee::Client.new(user_name: "easee", password: "money", token_cache:)

      site = client.site("C123")

      expect(site)
        .to have_attributes(
          name: "Home charger",
          street: "Lindelaan",
          building_number: "31",
          zip: "1234 Ab",
          area: "Laderburg",
          country_id: "NL",
          latitude: 51.949433,
          longitude: 5.231064,
        )
    end
  end

  describe "#state" do
    it "fetches the state for a charger" do
      now = Time.zone.local(2023, 3, 27, 15, 21)
      Timecop.freeze(now)

      token_cache = ActiveSupport::Cache::MemoryStore.new
      token_cache.write(
        Easee::Client::TOKENS_CACHE_KEY,
        { "accessToken" => "T123" }.to_json,
      )

      stub_request(:get, "https://api.easee.cloud/api/chargers/C123/state")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(
          status: 200,
          body: {
            chargerOpMode: 3,
            lifetimeEnergy: 23.67,
            isOnline: true,
            latestPulse: "2023-08-29T12:20:09.000Z",
          }.to_json,
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

      expect(state.meter_reading)
        .to have_attributes(
          reading_kwh: 23.67,
          timestamp: Time.utc(2023, 8, 29, 12, 20, 9),
        )
    end

    it "handles 429 HTTP errors" do
      stub_request(:get, "https://api.easee.cloud/api/chargers/C123/state")
        .to_return(status: 429)

      token_cache = ActiveSupport::Cache::MemoryStore.new
      token_cache.write(
        Easee::Client::TOKENS_CACHE_KEY,
        { "accessToken" => "T123" }.to_json,
      )

      client = Easee::Client.new(user_name: "easee", password: "money", token_cache:)

      expect { client.state("C123") }.to raise_error(Easee::Errors::RateLimitExceeded) do |error|
        expect(error).to be_retryable
      end
    end

    it "raises a Forbidden error when we have no access to the charger (anymore)" do
      stub_request(:get, "https://api.easee.cloud/api/chargers/C123/state")
        .to_return(status: 403)

      token_cache = ActiveSupport::Cache::MemoryStore.new
      token_cache.write(
        Easee::Client::TOKENS_CACHE_KEY,
        { "accessToken" => "T123" }.to_json,
      )

      client = Easee::Client.new(user_name: "easee", password: "money", token_cache:)

      expect { client.state("C123") }.to raise_error(Easee::Errors::Forbidden)
    end
  end

  describe "#pause_charging" do
    it "sends a pause_charging command" do
      token_cache = ActiveSupport::Cache::MemoryStore.new
      token_cache.write(
        Easee::Client::TOKENS_CACHE_KEY,
        { "accessToken" => "T123" }.to_json,
      )

      stub_request(:post, "https://api.easee.cloud/api/chargers/C123/commands/pause_charging")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(status: 200, body: "")

      client = Easee::Client.new(user_name: "easee", password: "money", token_cache:)

      expect { client.pause_charging("C123") }.not_to raise_error
    end
  end

  describe "#resume_charging" do
    it "sends a resume_charging command" do
      token_cache = ActiveSupport::Cache::MemoryStore.new
      token_cache.write(
        Easee::Client::TOKENS_CACHE_KEY,
        { "accessToken" => "T123" }.to_json,
      )

      stub_request(:post, "https://api.easee.cloud/api/chargers/C123/commands/resume_charging")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(status: 200, body: "")

      client = Easee::Client.new(user_name: "easee", password: "money", token_cache:)

      expect { client.resume_charging("C123") }.not_to raise_error
    end
  end

  describe "#poll_lifetime_energy" do
    it "sends a poll_lifetimeenergy command" do
      token_cache = ActiveSupport::Cache::MemoryStore.new
      token_cache.write(
        Easee::Client::TOKENS_CACHE_KEY,
        { "accessToken" => "T123" }.to_json,
      )

      stub = stub_request(:post, "https://api.easee.cloud/api/chargers/C123/commands/poll_lifetimeenergy")
        .with(headers: { "Authorization" => "Bearer T123" })
        .to_return(status: 200, body: "")

      client = Easee::Client.new(user_name: "easee", password: "money", token_cache:)

      client.poll_lifetime_energy("C123")

      expect(stub).to have_been_requested
    end
  end

  describe "#inspect" do
    it "does not include the user name and password" do
      token_cache = ActiveSupport::Cache::MemoryStore.new
      encryptor = Easee::NullEncryptor.new
      client = Easee::Client.new(user_name: "easee", password: "money", token_cache:, encryptor:)

      expect(client.inspect).to match(<<~INSPECT)
        #<Easee::Client @user_name="[FILTERED]", @password="[FILTERED]", @token_cache=#{token_cache.inspect}, @encryptor=#{encryptor.inspect}>
      INSPECT
    end
  end
end
