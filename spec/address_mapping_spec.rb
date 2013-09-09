require 'spec_helper'

describe "address" do
  before(:each) do
    undef_person
  end

  context "as nested object" do
    before(:each) do
      class Address
        attr_accessor :the_street,
                      :the_supplement,
                      :the_city,
                      :the_zipcode,
                      :the_country,
                      :the_region,
                      :the_pobox
      end

      @address                 = Address.new
      @address.the_street      = '2300 Main St'
      @address.the_supplement  = 'Ext.'
      @address.the_city        = 'Sampleville'
      @address.the_zipcode     = '01234'
      @address.the_country     = 'USA'
      @address.the_region      = 'NC'
      @address.the_pobox       = "1234-5678"

      @it_includes_all_address_attributes = ->(card) {
        card.address.street.should      == '2300 Main St'
        card.address.extended.should    == 'Ext.'
        card.address.locality.should    == 'Sampleville'
        card.address.postalcode.should  == '01234'
        card.address.country.should     == 'USA'
        card.address.region.should      == 'NC'
        card.address.pobox.should       == "1234-5678"
        card.to_s.should match /^ADR:1234-5678;Ext.;2300 Main St;Sampleville;NC;01234;USA$/
      }
    end

    it "can be left unmapped explicitly" do
      class Person
        include Veasycard
        attr_accessor :last_name, :address
        veasycard do
          address nil
        end
      end

      p                     = Person.new
      p.last_name           = "Doe"
      p.address             = Address.new
      p.address.the_street  = "2300 Main St."
      p.address.the_city    = "Sampleville"
      p.address.the_zipcode = "01234"
      p.address.the_country = "USA"

      vcard = p.vcard(format: 'raw')
      vcard.should_not include('2300 Main St.')
      vcard.should_not include('Sampleville')
      vcard.should_not include('01234')
      vcard.should_not include('USA')
    end

    context "when mapped explicitly" do
      context "with address attributes mapped implicitly" do
        before(:each) do
          undef_person
          class Person
            include Veasycard
            attr_accessor :family_name,
                          :the_address

            veasycard do
              address :the_address, preferred: true
            end
          end

          class Address
            attr_accessor :street,
                          :supplement,
                          :locality,
                          :zipcode,
                          :country,
                          :region,
                          :pobox
          end

          address = Address.new
          address.street     = '2300 Main St'
          address.supplement = 'Ext.'
          address.locality   = 'Sampleville'
          address.zipcode    = '01234'
          address.country    = "USA"
          address.region     = 'NC'
          address.pobox      = '1234-5678'

          @person                  = Person.new
          @person.family_name      = 'Doe'
          @person.the_address      = address
        end

        it "includes all attributes" do
          @it_includes_all_address_attributes.call(@person.vcard)
        end
      end

      context "with address attributes mapped explicitly as well" do
        before(:each) do
          undef_person
          class Person
            include Veasycard
            attr_accessor :family_name,
                          :the_address

            veasycard do
              address :the_address, preferred: true, location: 'home' do
                street     :the_street
                supplement :the_supplement
                locality   :the_city
                zipcode    :the_zipcode
                country    :the_country
                region     :the_region
                pobox      :the_pobox
              end
            end
          end

          @person                  = Person.new
          @person.family_name      = 'Doe'
          @person.the_address      = @address
        end

        it "includes all attributes" do
          @it_includes_all_address_attributes.call(@person.vcard)
        end

        it "accepts options"
      end
    end
  end

  context "when mapped implicitly" do

  end
end