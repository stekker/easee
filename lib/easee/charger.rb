module Easee
  class Charger
    def initialize(data)
      @data = data.symbolize_keys
    end

    def id = @data.fetch(:id)
    def name = @data.fetch(:name)
    def color = @data.fetch(:color)
    def product_code = @data.fetch(:productCode)
  end
end
