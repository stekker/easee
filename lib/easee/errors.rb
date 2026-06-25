module Easee
  module Errors
    class Base < ::StandardError
      def retryable? = false
    end

    class InvalidCredentials < Base; end

    class RequestFailed < Base
      attr_reader :response

      def initialize(message, response = nil)
        @response = response
        super(message)
      end
    end

    class Forbidden < Base; end

    class InvalidPinCode < RequestFailed; end

    class ChargerNotFound < RequestFailed; end

    class RateLimitExceeded < RequestFailed
      def retryable? = true
    end
  end
end
