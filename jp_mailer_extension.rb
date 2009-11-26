require 'nkf'

# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application_controller'

class JpMailerExtension < Radiant::Extension
  version "1.0"
  description "Enables Mailer extension to send Japanese mails."
  url "http://d.hatena.ne.jp/shunsuk/"
  
  # define_routes do |map|
  #   map.namespace :admin, :member => { :remove => :get } do |admin|
  #     admin.resources :jp_mailer
  #   end
  # end
  
  def activate
    # admin.tabs.add "Jp Mailer", "/admin/jp_mailer", :after => "Layouts", :visibility => [:all]
    
    Mailer.class_eval do
      @@default_charset = 'iso-2022-jp'
      @@encode_subject  = false

      def base64(text, charset="iso-2022-jp", convert=true)
        if convert
          if charset == "iso-2022-jp"
            text = NKF.nkf('-j -m0', text)
          end
        end
        text = [text].pack('m').delete("¥r¥n")
        "=?#{charset}?B?#{text}?="
      end

      def generic_mail_jp(options)
        options[:subject] = base64(options[:subject])
        options[:charset] = "iso-2022-jp"
        generic_mail_org(options)
      end

      alias_method :generic_mail_org, :generic_mail
      alias_method :generic_mail, :generic_mail_jp

      def part(params)
        params[:body] = NKF::nkf('-j', params[:body])
        super params
      end
    end

    Mail.class_eval do
      def send_jp
        Hash.class_eval do
          def to_yaml_jp
            self.to_a.map {|k,v| "#{k}: #{v}"}.join("\n")
          end

          alias_method :to_yaml_org, :to_yaml
          alias_method :to_yaml, :to_yaml_jp
        end

        return_value = send_org

        Hash.class_eval do
          alias_method :to_yaml, :to_yaml_org
        end

        return_value
      end

      alias_method :send_org, :send
      alias_method :send, :send_jp
    end

  end
  
  def deactivate
    # admin.tabs.remove "Jp Mailer"
  end
  
end
