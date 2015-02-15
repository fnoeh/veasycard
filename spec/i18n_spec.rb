require 'spec_helper'
require 'yaml'

I18N_ATTRIBUTES = %w(
  name
  family_name
  given_name
  email
  birthday
)

# returns true if the i18n.yml file contains all the I18N_ATTRIBUTES under the language key
# with at least 1 translation for each attribute
def language_translation_complete?(language, i18n_config)
  given_attributes_for_language = i18n_config[language]

  all_key_attributes_present = (I18N_ATTRIBUTES.sort - given_attributes_for_language.keys.sort) == []
  all_key_attributes_have_translation = given_attributes_for_language.select { |i| given_attributes_for_language[i].nil? }.empty?

  return all_key_attributes_present && all_key_attributes_have_translation
end

# e. g. "en: English"
def name_for_language(language, i18n_config)
  "#{language}: #{i18n_config[language]['name']}"
end

describe "I18n", :i18n do

  it "won't be activated implicitly" do
    person_class = Class.new(Object) {
      attr_accessor :nachname
      include Veasycard
    }

    p = person_class.new
    p.nachname = "Mustermann"

    lambda { p.vcard }.should raise_error
  end

  it "can be activated explicitly" do
    person_class = Class.new(Object) {
      include Veasycard::DE
      attr_accessor :nachname
    }

    p = person_class.new
    p.nachname = "Mustermann"
    p.vcard.name.family.should == p.nachname
  end

  it "attributes from other languages are ignored" do
    person_class = Class.new(Object) {
      include Veasycard::DE
      attr_accessor :family_name,
                    :nachname,
                    :given_name
    }

    p = person_class.new
    p.family_name = "Doe"
    p.given_name  = "John"
    p.nachname    = "Mustermann"

    p.vcard.name.family.should == p.nachname
    p.vcard.name.given.should  == ""
  end

  # TODO: rewrite
  # describe "language file contains necessary attributes for" do
  #   i18n_config = YAML.load_file("lib/i18n.yml")
  #   i18n_config.keys.each do |language|
  #     it name_for_language(language, i18n_config) do
  #       language_translation_complete?(language, i18n_config).should == true
  #     end
  #   end
  # end
end
