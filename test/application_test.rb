require 'test/helper'
class IcontactTest < Test::Unit::TestCase
  
  def setup
    Icontact::Application.api_key = "A key"
    Icontact::Application.shared_secret = "A shared_secret"
  end

  context "A registered application" do

    should "have an api key" do
      assert !Icontact::Application.api_key.nil?
      assert !Icontact::Application.shared_secret.nil?
    end

  end

end
