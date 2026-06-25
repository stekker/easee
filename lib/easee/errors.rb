module Easee
  module Errors
    class Base < ::StandardError
      def retryable? = false
    end

    class InvalidCredentials < Base
      CODES = [100, 727].freeze
    end

    class RequestFailed < Base
      attr_reader :response

      def initialize(message, response = nil)
        @response = response
        super(message)
      end
    end

    class Forbidden < Base; end

    class InvalidPinCode < RequestFailed
      CODE = 193
    end

    class ChargerNotFound < RequestFailed
      CODE = 400
    end

    class RateLimitExceeded < RequestFailed
      def retryable? = true
    end
  end
end
