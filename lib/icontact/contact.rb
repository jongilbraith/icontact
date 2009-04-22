module Icontact

  class Contact < Application

    attr_accessor :token, :sequence, :id
    
    attr_writer :fname, :lname, :email, :zip

    # Not meant for direct instansiation, either retrieve contacts as an element of application.contacts,
    # or by lookup against the application with application.contact(id).
    def initialize(token, sequence, id = nil)
      @token    = token
      @sequence = sequence
      @id       = id
    end

    # The first name of this contact
    def fname
      @fname ||= retrieve_contact_field(:fname)
    end

    # The last name of this contact
    def lname
      @lname ||= retrieve_contact_field(:lname)
    end
    
    # The email address of this contact
    def email
      @email ||= retrieve_contact_field(:email)
    end
    
    # This contact's preferred prefix - Mr, Mrs, etc
    def prefix
      @prefix ||= retrieve_contact_field(:prefix)
    end
    
    # This contact's suffix, if they have one - phd, esq, etc
    def suffix
      @suffix ||= retrieve_contact_field(:suffix)
    end
    
    # This contact's business name
    def business
      @business ||= retrieve_contact_field(:business)
    end
    
    # The first line of this contact's address
    def address1
      @address1 ||= retrieve_contact_field(:address1)
    end
    
    # The second line of this contact's address
    def address2
      @address2 ||= retrieve_contact_field(:address2)
    end
    
    # The city from this contact's address
    def city
      @city ||= retrieve_contact_field(:city)
    end
    
    # The state / county of this contact's address
    def state
      @state ||= retrieve_contact_field(:state)
    end
    
    # The zip / postal code of this contact's address
    def zip
      @zip ||= retrieve_contact_field(:zip)
    end
    
    # This contact's phone number
    def phone
      @phone ||= retrieve_contact_field(:phone)
    end
    
    # This contact's fax number
    def fax
      @fax ||= retrieve_contact_field(:fax)
    end
    
    # Retrieves the xml for this contact. Memoized.
    def xml
      @xml ||= retrieve_contact
    end
    
    # Prepare the contact for a PUT
    def to_xml
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.contact( :id => "") do
        xml.email( @email )
        xml.zip( @zip )
      end
      return xml.target!
    end
  
  private
    def retrieve_contact_field(field)
      Hpricot.XML(self.xml).at(:contact).at(field) || nil
    end

    def retrieve_contact
      hmac = Digest::MD5.hexdigest("#{self.class.shared_secret}contact/#{self.id}api_key#{self.class.api_key}api_seq#{self.sequence}api_tok#{self.token}")
      url = URI.parse(BASE_URI + "contact/#{self.id}?api_key=#{self.class.api_key}&api_seq=#{self.sequence}&api_tok=#{self.token}&api_sig=#{hmac}")

      result = Net::HTTP::get_response(url)
      increment_sequence
      result.kind_of?(Net::HTTPSuccess) ? result.body : raise(Icontact::RequestError, "HTTP Response: #{result.code} #{result.message}")
    end
  end
end