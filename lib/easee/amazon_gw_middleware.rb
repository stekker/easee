module Easee
  class AmazonGwMiddleware < Faraday::Middleware
    def on_complete(env)
      return unless env.response_headers["X-Amzn-Errortype"] == "ForbiddenException"

      response_values = Faraday::Response::RaiseError.new.response_values(env)
      raise(Faraday::ForbiddenError, response_values)
    end
  end
end
