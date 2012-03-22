require 'vpim/vcard'
require 'yaml'

module Veasycard

  def veasycard_language
    :en
  end

  module ClassMethods
    attr_reader :veasycard_attribute_mapping

    def veasycard(vcard_attribute, attribute, options = {})
      @veasycard_attribute_mapping ||= {}

      case vcard_attribute
      when :email
        @veasycard_attribute_mapping[:email] ||= {}
        @veasycard_attribute_mapping[:email][options] = attribute
      else
        @veasycard_attribute_mapping[vcard_attribute] = attribute
      end    
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  i18n = YAML.load_file("lib/i18n.yml")
  i18n.each_key do |lang|
    s = "module #{lang.upcase}
      include Veasycard
      def veasycard_language; :#{lang}; end

      def self.included(base)
        base.extend(Veasycard::ClassMethods)
      end
    end"
    eval s if lang =~ /[a-z]{2}/
  end

  def vcard(options={})
    mapping = self.class.veasycard_attribute_mapping || {}

    card = Vpim::Vcard::Maker.make2 do |maker|

      i18n = YAML.load_file("lib/i18n.yml")

      maker.add_name do |name|
        names = {}

        [:family_name, :given_name].each do |name|
          if m = mapping[name] rescue nil
            actual_value = self.send m
            names[name] = actual_value
            next
          end

          i18n[self.veasycard_language.to_s][name.to_s].each do |translation|
            n = self.send(translation) rescue nil
            if n
              names[name] = n
              break
            end
          end
        end
        
        raise ArgumentError.new "no name supplied" if names.values.compact.empty?
        
        name.family = names[:family_name] if names[:family_name]
        name.given  = names[:given_name]  if names[:given_name]
        name.prefix = names[:prefix]      if names[:prefix]
      end
      
      if mapping[:email].nil?
        # try default values for this language
        i18n[self.veasycard_language.to_s]["email"].each do |attribute|
          maker.add_email(self.send(attribute)) if self.respond_to? attribute
        end
      else
        # use manual attribute override
        mapping[:email].each do |options,attribute|
          maker.add_email(self.send attribute) do |e|
            options.each { |option,value| e.send("#{option}=", value.to_s) }
          end
        end
      end
    end
  
    case options[:format]
    when :raw
      card.to_s
    else
      card
    end
  end

end