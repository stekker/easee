RSpec.describe Easee::Site do
  describe "#country_id" do
    it "returns nil when the address country is nil" do
      site = Easee::Site.new(address: { country: nil })

      expect(site.country_id).to be_nil
    end
  end
end
