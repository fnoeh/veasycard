require 'vpim/vcard'
require 'yaml'
require 'handlers/address_handler'
require 'handlers/names_handler'

module Veasycard

  include Handlers::NamesHandler
  include Handlers::AddressHandler

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
        @veasycard_attribute_mapping[:address][:attributes] ||= {}
        @veasycard_attribute_mapping[:address][:attributes][attribute] = value
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
      @veasycard_attribute_mapping[:address] ||= {mapped_to: attribute} unless attribute.nil?
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
    next unless lang =~ /[a-z]{2}/
    eval %Q{module #{lang.upcase}
      include Veasycard
      def veasycard_language; :#{lang}; end

      def self.included(base)
        base.extend(Veasycard::ClassMethods)
      end
    end}
  end

  def vcard(options={})
    load_i18n
    load_attribute_mapping
    make_card
    return_card(options[:format])
  end

private


  # @return [Hash] all attributes from a top-level language in i18n.yml.
  def veasycard_language_attributes
    @i18n[veasycard_language.to_s]["attributes"]
  end

  def return_card(format=nil)
    case format
    when :raw, 'raw'
      @card.to_s
    else
      @card
    end
  end

  def load_i18n
    @i18n = YAML.load_file("lib/i18n.yml")
  end

  def load_attribute_mapping
    @mapping = self.class.veasycard_attribute_mapping || {}
  end

  def make_card
    @card = Vpim::Vcard::Maker.make2 do |maker|
      handle_name(maker)
      handle_email(maker)
      handle_address(maker)
      handle_birthday(maker)
    end
  end

  def handle_email(maker)
    if not_mapped_explicitly?(:email)
      use_implicitly_mapped_email_attributes(maker)
    else
      use_explicitly_mapped_email_attributes(maker)
    end
  end

  def use_implicitly_mapped_email_attributes(maker)
    veasycard_language_attributes["email"].each do |attribute|
      maker.add_email(self.send(attribute)) if self.respond_to? attribute
    end
  end

  def use_explicitly_mapped_email_attributes(maker)
    @mapping[:email].each do |options,attribute|
      add_email_to_maker(maker, options, attribute)
    end
  end

  def add_email_to_maker(maker, options, attribute)
    maker.add_email(self.send attribute) do |e|
      options.each do |option,value|
        e.send("#{option}=", value.to_s)
      end
    end
  end

  def is_mapped_explicitly?(attribute)
    not not_mapped_explicitly?(attribute)
  end

  def not_mapped_explicitly?(attribute)
    @mapping[attribute].nil?
  end

  def valid_attribute?(data, method)
    data.respond_to? method
  end

  def translated_address_meta
    veasycard_language_attributes["address"]["meta"]
  end

  def translated_address_attributes
    veasycard_language_attributes["address"]["attributes"]
  end

  def handle_birthday(maker)
    if m = @mapping[:birthday] rescue nil
      set_maker_attribute(maker, "birthday", self.send(m))
    else
      # no mapping applies... => check all defaults from i18n
      veasycard_language_attributes["birthday"].each do |default|
        if value = self.send(default) rescue nil
          set_maker_attribute(maker, "birthday", value)
          break
        end
      end
    end
  end

  def overridden_vpim_defaults
    @overridden_vpim_defaults ||= {
      # veasycard name => Vpim name
      :supplement => :extended,
      :zipcode    => :postalcode
    }
  end

  def vpim_default_overridden?(key)
    overridden_vpim_defaults.include? key
  end

  def vpim_attribute_overridden_or_default(key)
    if vpim_default_overridden?(key)
      overridden_vpim_defaults[key]
    else
      key
    end
  end

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
