module Icontact

  class Contact < Application

    attr_accessor :token

    attr_accessor :sequence
    
    attr_accessor :id

    # Not meant for direct instansiation, either retrieve contacts as an element of application.contacts,
    # or by lookup against the application with application.contact(id).
    def initialize(token, sequence, id = nil)
      @token    = token
      @sequence = sequence
      @id       = id
    end

    # The first name of this contact
    def fname
      @fname ? @fname : @fname = Hpricot.XML(self.xml).at(:contact).at(:fname)
    end

    # The last name of this contact
    def lname
      @lname ? @lname : @lname = Hpricot.XML(self.xml).at(:contact).at(:lname)
    end
    
    # The email address of this contact
    def email
      @email ? @email : @email = Hpricot.XML(self.xml).at(:contact).at(:email)
    end
    
    # This contact's preferred prefix - Mr, Mrs, etc
    def prefix
      @prefix ? @prefix : @prefix = Hpricot.XML(self.xml).at(:contact).at(:prefix)
    end
    
    # This contact's suffix, if they have one - phd, esq, etc
    def suffix
      @suffix ? @suffix : @suffix = Hpricot.XML(self.xml).at(:contact).at(:suffix)
    end
    
    # This contact's business name
    def business
      @business ? @business : @business = Hpricot.XML(self.xml).at(:contact).at(:business)
    end
    
    # The first line of this contact's address
    def address1
      @address1 ? @address1 : @address1 = Hpricot.XML(self.xml).at(:contact).at(:address1)
    end
    
    # The second line of this contact's address
    def address2
      @address2 ? @address2 : @address2 = Hpricot.XML(self.xml).at(:contact).at(:address2)
    end
    
    # The city from this contact's address
    def city
      @city ? @city : @city = Hpricot.XML(self.xml).at(:contact).at(:city)
    end
    
    # The state / county of this contact's address
    def state
      @state ? @state : @state = Hpricot.XML(self.xml).at(:contact).at(:state)
    end
    
    # The zip / postal code of this contact's address
    def zip
      @zip ? @zip : @zip = Hpricot.XML(self.xml).at(:contact).at(:zip)
    end
    
    # This contact's phone number
    def phone
      @phone ? @phone : @phone = Hpricot.XML(self.xml).at(:contact).at(:phone)
    end
    
    # This contact's fax number
    def fax
      @fax ? @fax : @fax = Hpricot.XML(self.xml).at(:contact).at(:fax)
    end
    
    # Retrieves the xml for this contact. Memoized.
    def xml
      if @xml
        @xml
      else
        hmac = Digest::MD5.hexdigest("#{self.class.shared_secret}contact/#{self.id}api_key#{self.class.api_key}api_seq#{self.sequence}api_tok#{self.token}")
        url = URI.parse(BASE_URI + "contact/#{self.id}?api_key=#{self.class.api_key}&api_seq=#{self.sequence}&api_tok=#{self.token}&api_sig=#{hmac}")

        result = Net::HTTP::get_response(url)
        result.kind_of?(Net::HTTPSuccess) ? @xml = result.body : raise(Icontact::RequestError, "HTTP Response: #{result.code} #{result.message}")
      end
    end
  
  end
 
end