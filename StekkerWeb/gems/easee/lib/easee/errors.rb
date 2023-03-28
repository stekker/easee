module Easee
  module Errors
    class Base < ::StandardError; end
    class RequestFailed < Base; end
  end
end
