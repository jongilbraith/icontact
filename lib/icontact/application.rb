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
      hmac = Digest::MD5.hexdigest("#{self.shared_secret}auth/login/#{username}/#{Digest::MD5.hexdigest(password)}api_key#{self.api_key}")
      url = URI.parse(BASE_URI + "auth/login/#{username}/#{Digest::MD5.hexdigest(password)}/?api_key=#{self.api_key}&api_sig=#{hmac}")
      result = Net::HTTP::get_response(url)
      if result.kind_of?(Net::HTTPSuccess)
        xml = Hpricot.XML(result.body)
        if xml.at(:response)[:status] == "fail"
          raise xml.inspect
          # raise Icontact::LoginFail
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
    
    def initialize
      @lists    = {}
      @contacts = {}
    end

    # Retrieves an array contacts matched against the given criteria
    def contacts(search_query = nil)
      # Search query goes at the end as it seems the params need to be in alphabetical order. Makes sense actually, it's just not documented.
      # Thanks to this guy for working it out http://www.icontact.com/forums/topic-465.html
      hmac = Digest::MD5.hexdigest("#{self.class.shared_secret}contactsapi_key#{self.class.api_key}api_seq#{self.sequence}api_tok#{self.token}#{search_query.gsub("=", "") unless search_query.nil?}")
      url = URI.parse(BASE_URI + "contacts?#{(search_query + "&") unless search_query.nil? }api_key=#{self.api_key}&api_seq=#{self.sequence}&api_tok=#{self.token}&api_sig=#{hmac}")

      result = Net::HTTP::get_response(url)
      increment_sequence
      if result.kind_of?(Net::HTTPSuccess)
        xml = Hpricot.XML(result.body)
        xml.at(:response).search(:contact).inject([]) do |contacts, contact_xml|
          id = contact_xml[:id]
          @contacts[id.to_i] = Icontact::Contact.new(self.token, self.sequence, id)
          contacts << contact(id)
        end
      else
        raise Icontact::RequestError, "HTTP Response: #{result.code} #{result.message}"
      end
    end
    
    # Look up a contact by it's id
    def contact(id)
      @contacts[id.to_i] ||=  Icontact::Contact.new(self.token, self.sequence, id)
    end
    
    # Create a new contact
    def create_contact(contact)
      hmac = Digest::MD5.hexdigest("#{self.class.shared_secret}contactapi_key#{self.class.api_key}api_put#{contact.to_xml}api_seq#{self.sequence}api_tok#{self.token}")
      url = URI.parse(BASE_URI + "contact?api_key=#{self.api_key}&api_seq=#{self.sequence}&api_tok=#{self.token}&api_sig=#{hmac}")
      
      result = Net::HTTP.start(url.host, url.port) {|http| http.send_request('PUT', url.request_uri, contact.to_xml) }
      increment_sequence
      if result.kind_of?(Net::HTTPSuccess)
        xml = Hpricot.XML(result.body)
        
        # Return the contact ID for now
        xml.search("contact")[0].get_attribute(:id)
      else
        raise Icontact::RequestError, "HTTP Response: #{result.code} #{result.message}"
      end
    end
    
    # Subscribe a contact to a list
    def subscribe(contact_id, list_id)
      change_subscription(contact_id, list_id, 'subscribed')
    end

    def unsubscribe(contact_id, list_id)
      change_subscription(contact_id, list_id, 'unsubscribed')
    end

    # Retrieves an array of all lists associated with this account, each element being an instance of List.
    def lists
      hmac = Digest::MD5.hexdigest("#{self.class.shared_secret}listsapi_key#{self.class.api_key}api_seq#{self.sequence}api_tok#{self.token}")
      url = URI.parse(BASE_URI + "lists?api_key=#{self.api_key}&api_seq=#{self.sequence}&api_tok=#{self.token}&api_sig=#{hmac}")

      result = Net::HTTP::get_response(url)
      increment_sequence
      if result.kind_of?(Net::HTTPSuccess)
        xml = Hpricot.XML(result.body)
        xml.at(:lists).search(:list).inject([]) do |lists, list_xml|
          id = list_xml[:id]
          @lists[id.to_i] ||= Icontact::List.new(self.token, self.sequence, id)
          lists << list(id)
        end
      else
        raise Icontact::RequestError, "HTTP Response: #{result.code} #{result.message}"
      end
    end
    
    # Look up a list by it's id
    def list(id)
      @lists[id.to_i] ||= Icontact::List.new(self.token, self.sequence, id)
    end
    
  protected
  
    # According to the API documentation, it is necessary to increment the sequence after every API call in a given session
    # This is one convoluted and poorly documented API.
    def increment_sequence
      self.sequence += 1
    end

    def change_subscription(contact_id, list_id, status)
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.subscription( :id => list_id ) do
        xml.status( status )
      end

      hmac = Digest::MD5.hexdigest("#{self.class.shared_secret}contact/#{contact_id}/subscription/#{list_id}api_key#{self.class.api_key}api_put#{xml.target!}api_seq#{self.sequence}api_tok#{self.token}")
      url = URI.parse(BASE_URI + "contact/#{contact_id}/subscription/#{list_id}?api_key=#{self.api_key}&api_seq=#{self.sequence}&api_tok=#{self.token}&api_sig=#{hmac}")

      result = Net::HTTP.start(url.host, url.port) {|http| http.send_request('PUT', url.request_uri, xml.target!) }
      increment_sequence
      return result.kind_of?(Net::HTTPSuccess)
    end
  end
  
end