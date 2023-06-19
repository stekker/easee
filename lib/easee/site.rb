module Easee
  class Site
    def initialize(data)
      @data = data.deep_symbolize_keys
    end

    def name = @data.fetch(:name)
    def street = address.fetch(:street)
    def building_number = address.fetch(:buildingNumber)
    def zip = address.fetch(:zip)
    def area = address.fetch(:area)
    def country_id = country[:id]
    def latitude = address.fetch(:latitude)
    def longitude = address.fetch(:longitude)

    private

    def country = address.fetch(:country) || {}

    def address
      @address ||= @data.fetch(:address)
    end
  end
end
