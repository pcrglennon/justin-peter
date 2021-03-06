require 'mailgun'

class MessageHelper

  CONFIG = {}

  def self.send_messages(addresses, map_name)
    notice = "message_success"
    addresses.split("\r\n").each do |address|
      status = send_message(address, map_name)
      if status.include?("Error")
        notice = "twilio_error"
        break
      end
    end

    notice
  end

  def self.setupConfig
    if File.exist?("./config/config.yml")
      yaml = YAML.load_file("./config/config.yml")[ENV['RACK_ENV']]["message_helper"]
      yaml.each_pair do |key, value|
        ENV[key] = value
      end
    end
    CONFIG[:mailgun_api_key] = ENV['mailgun_api_key']
    CONFIG[:mailgun_domain] = ENV['mailgun_domain']
    CONFIG[:twilio_account_sid] = ENV['twilio_account_sid']
    CONFIG[:twilio_auth_token] = ENV['twilio_auth_token']
  end

  private

    def self.send_message(address, map_name)
      if !address.scan(/@/).empty?
        send_mail(address, map_name)
        notice = "Email sent successfully."
      else
        begin
          send_text(address, map_name)
          notice = "Text sent successfully."
        rescue
          notice = "Twilio Error.  Please verify phone numbers are correct."
        end
      end

      notice
    end

    def self.send_mail(address, map_name)
      mailgun = Mailgun::Client.new(CONFIG[:mailgun_api_key])
      message_params = {
                        :from => "test@#{CONFIG[:mailgun_domain]}",
                        :to => address,
                        :subject => "WhereMeAt?",
                        :text => "You got a map from WhereMeAt!  Check it out: wheremeat.com/#{map_name}"
                       }
      mailgun.send_message(CONFIG[:mailgun_domain], message_params)
    end

    def self.send_text(address, map_name)
      @client = Twilio::REST::Client.new(CONFIG[:twilio_account_sid], CONFIG[:twilio_auth_token])
      message = @client.account.messages.create(
        :body => "WhereMeAt? Check it out: wheremeat.com/#{map_name}",
        :to => "#{address}",
        :from => "9735102922"
      )
    end

end