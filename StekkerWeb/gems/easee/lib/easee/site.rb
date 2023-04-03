module Easee
  class Site
    def initialize(data)
      @data = data.deep_symbolize_keys
    end

    def name = @data.fetch(:name)
    def street = address.fetch(:street)
    def house_number = address.fetch(:buildingNumber)
    def zip_code = address.fetch(:zip)
    def city = address.fetch(:area)
    def country = address.fetch(:country).fetch(:id)
    def latitude = address.fetch(:latitude)
    def longitude = address.fetch(:longitude)

    private

    def address
      @address ||= @data.fetch(:address)
    end
  end
end
