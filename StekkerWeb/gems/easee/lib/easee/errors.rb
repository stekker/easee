module Easee
  module Errors
    class Base < ::RuntimeError; end
    class RequestFailed < Base; end
  end
end
