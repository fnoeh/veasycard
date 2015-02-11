module Handlers

  module AddressHandler

    class << self
    end

  private

    def handle_address(maker)

      # TODO: use implicit mapping (inline or not) if mapping is nil
      # if @mapping[:address].nil? || @mapping[:address][:mapped_to].nil?
      #   puts "returning..."
      #   return
      # end

      address_values = retrieve_address_values_from address_container
      address_values.reject! { |k,v| v.nil? }
      maker.add_addr do |addr|
        address_values.each do |key,value|
          vpim_attribute = vpim_attribute_overridden_or_default(key)
          addr.send("#{vpim_attribute}=", value)
        end
      end
    end

    def address_container
      container = @mapping[:address] && @mapping[:address][:mapped_to]

      case container
        # TODO: wtf is Person anyway?! It probably doesn't belong here
        when :self, Person
          self
        when nil
          implicitly_mapped_address_container || self
        else
          self.send(container)
      end
    end

    def implicitly_mapped_address_container
      result = nil
      if @i18n[self.veasycard_language.to_s]["address"].nil?
        # address was not mapped explicitly
        # puts "returning".green
        # return
      end

      @i18n[self.veasycard_language.to_s]["address"]["meta"]["names"].each do |possible_container|
        if self.respond_to?(possible_container)
          result = self.send(possible_container)
          break unless result.nil?
        end
      end
      return result
    end

    def address_attributes_inline?
      address_container || self
    end

    def retrieve_address_values_from(address_object)
      # puts "address_object = #{address_object.inspect}".red
      address_values = {}
      # byebug
      vcard_attributes_address.each_with_index do |address_attribute, i|
        # next if @mapping["address"].nil?

        # byebug if i == 0
        if @mapping[:address].nil? || @mapping[:address][:attributes].nil?

          attribute_value = @i18n[self.veasycard_language.to_s]["address"]["attributes"][address_attribute.to_s].each do |possible_attribute_name|
            r = address_object.send(possible_attribute_name) if address_object.respond_to?(possible_attribute_name)
            address_values[address_attribute] = r
            break(r) unless r.nil?
          end
        else
          if a = @mapping[:address][:attributes][address_attribute]
            address_values[address_attribute] = address_object.send(a)
            next # don't look through the i18n translations
          end
        end

        # translated_address_attributes[address_attribute.to_s].each do |translation|
        #   if valid_attribute?(address_object, translation)
        #     address_values[address_attribute] = address_object.send(translation)
        #     break
        #   end
        # end
      end

      # byebug
      address_values
    end

    def vcard_attributes_address
      self.class.vcard_attributes_address
    end
  end
end
