require 'vpim/vcard'
require 'yaml'

module Veasycard

  def veasycard_language
    :en
  end

  module ClassMethods
    attr_reader :veasycard_attribute_mapping

    def vcard_attributes_address
      return VCARD_ATTRIBUTES_ADDRESS
    end

    VCARD_ATTRIBUTES_PERSONAL = [
      :family_name,
      :given_name,
      :email,
      :birthday,
      :address
    ]
    VCARD_ATTRIBUTES_ADDRESS = [
      :street,
      :supplement,
      :locality,
      :zipcode,
      :pobox,
      :region,
      :country
    ]

    VCARD_ATTRIBUTES = VCARD_ATTRIBUTES_PERSONAL + VCARD_ATTRIBUTES_ADDRESS

    def set_attribute(attribute, value)
      if VCARD_ATTRIBUTES_PERSONAL.include?(attribute)
        @veasycard_attribute_mapping[attribute] = value
      elsif VCARD_ATTRIBUTES_ADDRESS.include?(attribute)
        @veasycard_attribute_mapping[:address][attribute] = value
      else
        raise Error.new "Oops, something went wrong."
      end
    end

    def method_missing(m, *args, &block)
      if VCARD_ATTRIBUTES.include?(m)
        define_method(m) { |args|
          set_attribute(m, *args)
        }.call(args)
      else
        raise NoMethodError.new "Cannot use #{m} with veasycard."
      end
    end

    def email attribute, options = {}
      @veasycard_attribute_mapping[:email] ||= {}
      @veasycard_attribute_mapping[:email][options] = attribute
    end

    def address attribute, options = {}, &block
      @veasycard_attribute_mapping[:address] ||= {attribute: attribute} unless attribute.nil?
      yield if block_given?
    end

    def veasycard(&block)
      @veasycard_attribute_mapping ||= {}
      yield
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  # TODO: add config file to only define specific language modules
  i18n = YAML.load_file("lib/i18n.yml")
  i18n.each_key do |lang|
    s = %Q{module #{lang.upcase}
      include Veasycard
      def veasycard_language; :#{lang}; end

      def self.included(base)
        base.extend(Veasycard::ClassMethods)
      end
    end}
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
            actual_value = self.send m # actual_value is the value stored in the models appropriate instance variable, e.g. "John"
            names[name] = actual_value # names["given_name"] = "John"
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

      # other attributes
      %w(birthday).each do |attribute|
        if m = mapping[attribute.to_sym] rescue nil
          set_maker_attribute(maker, attribute, self.send(m))
          next
        end

        # no mapping applies... => check all defaults from i18n
        i18n[self.veasycard_language.to_s][attribute].each do |default|
          if value = self.send(default) rescue nil
            set_maker_attribute(maker, attribute, value)
            break
          end
        end
      end

      unless mapping[:address].nil?

        address_object = self.send(mapping[:address][:attribute])

        maker.add_addr do |addr|
          address_values = {}

          overridden_vpim_defaults = {
            :supplement => :extended,
            :zipcode    => :postalcode
          }

          self.class.vcard_attributes_address.each do |address_attribute|
            if a = mapping[:address][address_attribute]
              address_values[address_attribute] = address_object.send(a)
              next # don't look through the i18n translations
            end

            i18n[self.veasycard_language.to_s]['address'][address_attribute.to_s].each do |translation|
              if address_object.respond_to?(translation)
                address_values[address_attribute] = address_object.send(translation)
                break
              end
            end
          end

          address_values.each do |key,value|
            vpim_attribute = (overridden_vpim_defaults.keys.include? key) ? overridden_vpim_defaults[key] : key
            addr.send("#{vpim_attribute}=", value)
          end
        end
      end
    end

    case options[:format]
    when :raw, 'raw'
      card.to_s
    else
      card
    end
  end

private

  def set_maker_attribute(maker, attribute, value)
    adjusted_value = adjust_attribute_type(attribute, value)
    maker.send("#{attribute}=", adjusted_value)
  end

  def adjust_attribute_type(attribute, value)
    case attribute.to_sym
    when :birthday
      case value
      when String
        return Date.parse(value)
      when Date, DateTime
        return value
      end
    else
      return value
    end
  end
end