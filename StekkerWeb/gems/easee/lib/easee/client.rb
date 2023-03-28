module Easee
  class Client
    BASE_URL = "https://api.easee.cloud".freeze

    def initialize(user_name:, password:)
      @user_name = user_name
      @password = password
      @access_token = nil
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

    private

    attr_reader :user_name, :password

    def connection
      Faraday.new(url: BASE_URL) do |conn|
        conn.request :json
        conn.response :json, content_type: /\bjson$/
        conn.response :raise_error
      end
    end

    def authenticated_connection
      connection.tap do |conn|
        conn.request :authorization, "Bearer", access_token
      end
    end

    def get(endpoint, query = {})
      authenticated_connection.get("#{BASE_URL}#{endpoint}", query)
    rescue Faraday::Error => e
      raise Errors::RequestFailed, "Request returned status #{e.response_status}"
    end

    def post(endpoint, body: nil, query: nil)
      authenticated_connection.post("#{BASE_URL}#{endpoint}", body) do |req|
        req.params = query unless query.nil?
      end
    rescue Faraday::Error => e
      raise Errors::RequestFailed, "Request returned status #{e.response_status}"
    end

    def access_token
      @access_token ||= request_access_token
    end

    # https://developer.easee.cloud/reference/post_api-accounts-login
    def request_access_token
      connection.post("/api/accounts/login", userName: user_name, password:)
        .then { |response| response.body.fetch("accessToken") }
    end
  end
end
