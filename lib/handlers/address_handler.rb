module Handlers

  module AddressHandler

    class << self
    end

    # Retrieves the object that holds the address attributes. This is typically an instant
    # of a class like Person, Company or Address.
    #
    # @return [Object] the object that holds the address attributes.
    def address_container
      case container = @mapping[:address] && @mapping[:address][:mapped_to]
        when nil
          implicit_address_container || self
        when :self
          self
        else
          self.send(container)
      end
    end

  private

    def handle_address(maker)
      address_values = retrieve_address_values_from(address_container)
      address_values.reject! { |k,v| v.nil? }

      maker.add_addr do |addr|
        address_values.each do |key,value|
          vpim_attribute = vpim_attribute_overridden_or_default(key)
          addr.send("#{vpim_attribute}=", value)
        end
      end
    end

    def implicit_address_container
      result = nil
      translated_address_meta["names"].each do |possible_container|
        if self.respond_to?(possible_container)
          result = self.send(possible_container)
          break unless result.nil?
        end
      end
      return result
    end

    def retrieve_address_values_from(address_object)
      address_values = {}
      vcard_attributes_address.each do |attribute|
        if @mapping[:address].nil? || @mapping[:address][:attributes].nil?
          translated_address_attributes[attribute.to_s].each do |possible_attribute_name|
            r = address_object.send(possible_attribute_name) if address_object.respond_to?(possible_attribute_name)
            address_values[attribute] = r
            break(r) unless r.nil?
          end
        else
          if a = @mapping[:address][:attributes][attribute]
            address_values[attribute] = address_object.send(a)
            next # don't look through the i18n translations
          end
        end
      end

      address_values
    end

    def vcard_attributes_address
      self.class.vcard_attributes_address
    end
  end
end
