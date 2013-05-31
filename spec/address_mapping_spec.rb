require 'spec_helper'

describe "address" do
  
  context "as nested object" do
    
    context "when mapped explicitly" do
      context "with address attributes mapped explicitly as well" do
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
          
          @address                 = Address.new
          @address.the_street      = '2300 Main St'
          @address.the_supplement  = 'Ext.'
          @address.the_city        = 'Sampleville'
          @address.the_zipcode     = '01234'
          @address.the_country     = 'USA'
          @address.the_region      = 'NC'
          @address.the_pobox       = "1234-5678"
          
          @person                  = Person.new
          @person.family_name      = 'Doe'
          @person.the_address      = @address
        end
        
        it "includes all attributes" do
          c = @person.vcard
          
          c.address.street.should    == '2300 Main St'
          c.address.extended.should  == 'Ext.'
          c.address.locality.should  == 'Sampleville'
          c.address.postalcode.should  == '01234'
          c.address.country.should   == 'USA'
          c.address.region.should    == 'NC'
          c.address.pobox.should     == "1234-5678"
          
          c.to_s.should match /^ADR:1234-5678;Ext.;2300 Main St;Sampleville;NC;01234;USA$/
        end
      end
      
      context "with address attributes mapped implicitly" do
        before(:each) do
          class Address
            attr_accessor :street,
                          :zipcode,
                          :locality
          end
          
          class Person
            include Veasycard
            attr_accessor :family_name,
                          :the_address
            
            veasycard do
              address :the_address, preferred: true
            end
          end
          
          @address = Address.new
          @address.street   = "2300 Main St"
          @address.zipcode  = "01234"
          @address.locality = "Sampleville"
        end
        
        it "includes all attributes"
      end
    end
    
  end
  
  context "when mapped implicitly" do
    
  end
end
