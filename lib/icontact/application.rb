module Icontact
  
  class Application
    
    BASE_URI = "http://api.icontact.com/icp/core/api/v1.0/"
    
    # Your application's API key, retrieved from within the iContact account
    # at http://www.icontact.com/icp/core/registerapp.
    cattr_accessor :api_key
    
    # Your application's shared secret, retrieved from within the iContact account
    # at http://www.icontact.com/icp/core/registerapp.
    cattr_accessor :shared_secret

    # Log into the application - returns a session
    def self.login(username, password)
      hmac = Digest::MD5.hexdigest("#{self.shared_secret}auth/login/#{username}/#{Digest::MD5.hexdigest("cn1000!")}api_key#{self.api_key}")
      url = URI.parse(BASE_URI + "auth/login/#{username}/#{Digest::MD5.hexdigest(password)}/?api_key=#{self.api_key}&api_sig=#{hmac}")

      result = Net::HTTP::get_response(url)
      if result.kind_of?(Net::HTTPSuccess)
        xml = Hpricot.XML(result.body)
        if xml.at(:response)[:status] == "fail"
          raise Icontact::LoginFail
        elsif xml.at(:response)[:status] == "success"
          { :token => xml.at(:token).inner_html, :sequence => xml.at(:seq).inner_html.to_i }
        end
      else
        raise Icontact::RequestError, "HTTP Response: #{result.code} #{result.message}"
      end
    end

  end
  
end