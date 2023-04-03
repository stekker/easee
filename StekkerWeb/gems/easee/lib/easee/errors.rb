module Easee
  module Errors
    class Base < ::StandardError; end

    class RequestFailed < Base
      attr_reader :response

      def initialize(message, response = nil)
        @response = response
        super(message)
      end
    end
  end
end
