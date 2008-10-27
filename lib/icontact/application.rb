module Icontact
  
  class Application
    
    BASE_URI = "http://api.icontact.com/icp/core/api/v1.0/"
    
    # Your application's API key and shared secret, retrieved from within the iContact account.
    # at http://www.icontact.com/icp/core/registerapp.
    cattr_accessor :api_key, :shared_secret
    
    # A particular instance of application will have a dedicated token and sequence # for that session.
    attr_accessor :token, :sequence
    
    # Log into the application - returns a logged in application object, with token and sequence number required for further requests.
    def self.login(username, password)
      hmac = Digest::MD5.hexdigest("#{self.shared_secret}auth/login/#{username}/#{Digest::MD5.hexdigest("cn1000!")}api_key#{self.api_key}")
      url = URI.parse(BASE_URI + "auth/login/#{username}/#{Digest::MD5.hexdigest(password)}/?api_key=#{self.api_key}&api_sig=#{hmac}")

      result = Net::HTTP::get_response(url)
      if result.kind_of?(Net::HTTPSuccess)
        xml = Hpricot.XML(result.body)
        if xml.at(:response)[:status] == "fail"
          raise Icontact::LoginFail
        elsif xml.at(:response)[:status] == "success"
          application = self.new
          application.token = xml.at(:token).inner_html
          application.sequence = xml.at(:seq).inner_html.to_i
          application
        end
      else
        raise Icontact::RequestError, "HTTP Response: #{result.code} #{result.message}"
      end
    end

    # Retrieves an array of all lists associated with this account, each element being an instance of List.
    def lists
      hmac = Digest::MD5.hexdigest("#{self.class.shared_secret}listsapi_key#{self.class.api_key}api_seq#{self.sequence}api_tok#{self.token}")
      url = URI.parse(BASE_URI + "lists?api_key=#{self.api_key}&api_seq=#{self.sequence}&api_tok=#{self.token}&api_sig=#{hmac}")

      result = Net::HTTP::get_response(url)
      if result.kind_of?(Net::HTTPSuccess)
        xml = Hpricot.XML(result.body)
        xml.at(:lists).search(:list).inject([]) do |lists, list_xml|
          self.instance_variable_set("@list_#{list_xml[:id]}", Icontact::List.new(self.token, self.sequence, list_xml[:id]))
          lists << self.instance_variable_get("@list_#{list_xml[:id]}")
        end
      else
        raise Icontact::RequestError, "HTTP Response: #{result.code} #{result.message}"
      end
    end
    
    # Look up a list by it's id
    def list(id)
      self.instance_variable_get("@list_#{id}").nil? ? self.instance_variable_set("@list_#{id}", Icontact::List.new(self.token, self.sequence, id)) : self.instance_variable_get("@list_#{id}")
    end
    
  end
  
end