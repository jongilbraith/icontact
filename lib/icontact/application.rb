module Icontact
  
  class Application
    
    # Your application's API key, retrieved from within the iContact account
    # at http://www.icontact.com/icp/core/registerapp.
    cattr_accessor :api_key
    
    # Your application's shared secret, retrieved from within the iContact account
    # at http://www.icontact.com/icp/core/registerapp.
    cattr_accessor :shared_secret

    # This is a string returned by iContact after successfully authenticating
    # which must be used in all api calls.
    cattr_accessor :token
    
  end
  
end