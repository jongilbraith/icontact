module Icontact

  class List < Application

    attr_accessor :token

    attr_accessor :sequence
    
    attr_accessor :id

    # Not meant for direct instansiation, either retrieve lists as an element of application.lists,
    # or by lookup against the application with application.list(id).
    def initialize(token, sequence, id = nil)
      @token    = token
      @sequence = sequence
      @id       = id
    end
    
    # The name of this list
    def name
      @name ? @name : @name = Hpricot.XML(self.xml).at(:list).at(:name)
    end
    
    # The description of this list
    def description
      @description ? @description : @description = Hpricot.XML(self.xml).at(:list).at(:description)
    end
    
    # I'm not sure what this one is - some sort of boolean flag
    def ownerreceipt
      @ownerreceipt ? @ownerreceipt : @ownerreceipt = Hpricot.XML(self.xml).at(:list).at(:ownerreceipt)
    end
    
    # I'm not sure what this one is - some sort of boolean flag
    def systemwelcome
      @systemwelcome ? @systemwelcome : @systemwelcome = Hpricot.XML(self.xml).at(:list).at(:systemwelcome)
    end
    
    # I'm not sure what this one is - some sort of boolean flag
    def signupwelcome
      @signupwelcome ? @signupwelcome : @signupwelcome = Hpricot.XML(self.xml).at(:list).at(:signupwelcome)
    end
    
    # The contents of the mails sent to new users, if they've selected html email.
    def welcome_html
      @welcome_html ? @welcome_html : @welcome_html = Hpricot.XML(self.xml).at(:list).at(:welcome_html)
    end
    
    # The contents of the mails sent to new users, if they've selected text email.
    def welcome_text
      @welcome_text ? @welcome_text : @welcome_text = Hpricot.XML(self.xml).at(:list).at(:welcome_text)
    end
    
    # This is contents of the signup confirmation mail, aka double opt in email, if they've selected html email.
    def optin_html
      @optin_html ? @optin_html : @optin_html = Hpricot.XML(self.xml).at(:list).at(:optin_html)
    end
    
    # This is contents of the signup confirmation mail, aka double opt in email, if they've selected text email.
    def optin_text
      @optin_text ? @optin_text : @optin_text = Hpricot.XML(self.xml).at(:list).at(:optin_text)
    end
  
    def xml
      if @xml
        @xml
      else
        hmac = Digest::MD5.hexdigest("#{self.class.shared_secret}list/#{self.id}api_key#{self.class.api_key}api_seq#{self.sequence}api_tok#{self.token}")
        url = URI.parse(BASE_URI + "list/#{self.id}?api_key=#{self.class.api_key}&api_seq=#{self.sequence}&api_tok=#{self.token}&api_sig=#{hmac}")

        result = Net::HTTP::get_response(url)
        result.kind_of?(Net::HTTPSuccess) ? @xml = result.body : raise(Icontact::RequestError, "HTTP Response: #{result.code} #{result.message}")
      end
    end
  
  end

end