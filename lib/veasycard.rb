require 'vpim/vcard'
require 'yaml'

module Veasycard

  module ClassMethods
    attr_reader :veasycard_attribute_mapping

    def veasycard(vcard_attribute, attribute)
      @veasycard_attribute_mapping ||= {}
      @veasycard_attribute_mapping[vcard_attribute] = attribute
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def vcard(options={})
    mapping = self.class.veasycard_attribute_mapping

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

          i18n["en"][name.to_s].each do |translation|
            n = self.send(translation) rescue nil
            if n
              names[name] = n unless n.nil?
              break
            end
          end
        end
        
        raise ArgumentError.new "no name supplied" if names.values.compact.empty?
        
        name.family = names[:family_name] if names[:family_name]
        name.given  = names[:given_name]  if names[:given_name]
        name.prefix = names[:prefix]      if names[:prefix]
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