require 'vpim/vcard'

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

    if mapping.nil?
      card = Vpim::Vcard.create
    else
      card = Vpim::Vcard::Maker.make2 do |maker|
        maker.add_name do |name|
          name.prefix = self.send mapping[:prefix] if mapping[:prefix]
          name.given = self.send mapping[:given_name] if mapping[:given_name]
          name.family = self.send mapping[:family_name] if mapping[:family_name]
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