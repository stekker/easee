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
      PAIRING_RESULT_TITLES = %w[IncorrectPIN].freeze
    end

    class ChargerNotFound < RequestFailed
      CODE = 400
    end

    class TooManyAttempts < RequestFailed
      PAIRING_RESULT_TITLES = %w[TooManyAttempts].freeze
    end

    class AlreadyPaired < RequestFailed
      PAIRING_RESULT_TITLES = %w[AlreadyPairedWithPartner AlreadyPairedWithUser].freeze
    end

    class RateLimitExceeded < RequestFailed
      def retryable? = true
    end

    # https://developer.easee.com/docs/enumerations — pairing result codes (0..7)
    # ride on a single HTTP errorCode of 123, with the specific reason in `title`.
    PAIRING_ERROR_CODE = 123

    PAIRING_RESULT_ERRORS = [
      InvalidPinCode,
      TooManyAttempts,
      AlreadyPaired,
    ].freeze
  end
end
