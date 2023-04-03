require "active_support/notifications"
require "active_support/cache"

require_relative "null_encryptor"

module Easee
  class Client
    BASE_URL = "https://api.easee.cloud".freeze
    TOKENS_CACHE_KEY = "easee.auth.tokens".freeze

    def initialize(
      user_name:,
      password:,
      token_cache: ActiveSupport::Cache::MemoryStore.new,
      encryptor: NullEncryptor.new
    )
      @user_name = user_name
      @password = password
      @token_cache = token_cache
      @encryptor = encryptor
    end

    # https://developer.easee.cloud/reference/post_api-chargers-id-unpair
    def unpair(charger_id:, pin_code:)
      post("/api/chargers/#{charger_id}/unpair", query: { pinCode: pin_code })
    end

    # https://developer.easee.cloud/reference/post_api-chargers-id-pair
    def pair(charger_id:, pin_code:)
      post("/api/chargers/#{charger_id}/pair", query: { pinCode: pin_code })
    end

    # https://developer.easee.cloud/reference/get_api-chargers-id-state
    def state(charger_id)
      get("/api/chargers/#{charger_id}/state")
        .then { |response| State.new(response.body) }
    end

    # https://developer.easee.cloud/reference/post_api-chargers-id-commands-pause-charging
    def pause_charging(charger_id)
      post("/api/chargers/#{charger_id}/commands/pause_charging")
    end

    # https://developer.easee.cloud/reference/post_api-chargers-id-commands-resume-charging
    def resume_charging(charger_id)
      post("/api/chargers/#{charger_id}/commands/resume_charging")
    end

    def configuration(charger_id)
      get("/api/chargers/#{charger_id}/configuration")
        .then { |response| Configuration.new(response.body) }
    end

    def site(charger_id)
      get("/api/chargers/#{charger_id}/site")
        .then { |response| Site.new(response.body) }
    end

    def inspect
      <<~INSPECT
        #<#{self.class.name} @user_name="[FILTERED]", @password="[FILTERED]", @token_cache=#{@token_cache.inspect}, @encryptor=#{@encryptor.inspect}>
      INSPECT
    end

    private

    attr_reader :user_name, :password

    def connection
      Faraday.new(url: BASE_URL) do |conn|
        conn.request :json
        conn.response :raise_error
      end
    end

    def authenticated_connection
      connection.tap do |conn|
        conn.request :authorization, "Bearer", access_token
        conn.response :json, content_type: /\bjson$/
      end
    end

    def get(endpoint, query = {})
      with_error_handling do
        authenticated_connection.get("#{BASE_URL}#{endpoint}", query)
      end
    end

    def post(endpoint, body: nil, query: nil)
      with_error_handling do
        authenticated_connection.post("#{BASE_URL}#{endpoint}", body) do |req|
          req.params = query unless query.nil?
        end
      end
    end

    def with_error_handling
      token_refreshed ||= false

      yield
    rescue Faraday::UnauthorizedError => e
      if token_refreshed
        raise Errors::RequestFailed, "Request returned status #{e.response_status}"
      else
        refresh_access_token!
        token_refreshed = true

        retry
      end
    rescue Faraday::Error => e
      raise Errors::RequestFailed, "Request returned status #{e.response_status}"
    end

    def access_token
      encrypted_tokens = @token_cache.fetch(TOKENS_CACHE_KEY) do
        @encryptor.encrypt(request_access_token, cipher_options: { deterministic: true })
      end

      plain_text_tokens = @encryptor.decrypt(encrypted_tokens)

      JSON.parse(plain_text_tokens).fetch("accessToken")
    end

    def refresh_access_token!
      @token_cache.write(
        TOKENS_CACHE_KEY,
        @encryptor.encrypt(refresh_access_token, cipher_options: { deterministic: true }),
        expires_in: 1.day,
      )
    rescue Faraday::Error => e
      raise Errors::RequestFailed, "Request returned status #{e.response_status}"
    end

    # https://developer.easee.cloud/reference/post_api-accounts-login
    def request_access_token
      connection
        .post("/api/accounts/login", userName: user_name, password:)
        .then(&:body)
    end

    # https://developer.easee.cloud/reference/post_api-accounts-refresh-token
    def refresh_access_token
      tokens = JSON.parse(
        @encryptor.decrypt(
          @token_cache.fetch(TOKENS_CACHE_KEY),
        ),
      )

      connection
        .post(
          "/api/accounts/refresh_token",
          accessToken: tokens.fetch("accessToken"),
          refreshToken: tokens.fetch("refreshToken"),
        )
        .then(&:body)
    end
  end
end
