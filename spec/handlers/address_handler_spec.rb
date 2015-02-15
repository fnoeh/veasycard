require_relative '../spec_helper'

describe Handlers::AddressHandler do

  subject { person.vcard.address }

  let(:define_address_with_implicit_attribute_names) {
    class Address
      attr_accessor :country,
                    :locality,
                    :pobox,
                    :region,
                    :street,
                    :extended,
                    :postalcode
    end
  }

  let(:define_address_with_explicit_attribute_names) {
    class Address
      attr_accessor :the_country,
                    :the_locality,
                    :the_pobox,
                    :the_region,
                    :the_street,
                    :the_extended,
                    :the_postalcode
    end
  }

  let(:address_instance_with_implicit_attributes_names) {
    address = Address.new
    address.country    = address_values["country"]
    address.locality   = address_values["locality"]
    address.pobox      = address_values["pobox"]
    address.region     = address_values["region"]
    address.street     = address_values["street"]
    address.extended   = address_values["extended"]
    address.postalcode = address_values["postalcode"]
    address
  }

  let(:address_instance_with_explicit_attributes_names) {
    address = Address.new
    address.the_country    = address_values["country"]
    address.the_locality   = address_values["locality"]
    address.the_pobox      = address_values["pobox"]
    address.the_region     = address_values["region"]
    address.the_street     = address_values["street"]
    address.the_extended   = address_values["extended"]
    address.the_postalcode = address_values["postalcode"]
    address
  }

  let(:address_values) {
    {
      "country"    => "Fantasia",
      "locality"   => "Sampleville",
      "pobox"      => "1234 Gimme",
      "region"     => "out there",
      "street"     => "1000 Main St.",
      "extended"   => "right there",
      "postalcode" => "77777"
    }
  }

  shared_examples "address with correct content" do
    its("country")    { should eq address_values["country"] }
    its("locality")   { should eq address_values["locality"] }
    its("pobox")      { should eq address_values["pobox"] }
    its("region")     { should eq address_values["region"] }
    its("street")     { should eq address_values["street"] }
    its("extended")   { should eq address_values["extended"] }
    its("postalcode") { should eq address_values["postalcode"] }
  end

  describe "#address_container" do
    # TODO
    context "when mapped explicitly" do
    end
  end

  describe "#handle_address" do
    context "when address is mapped to person explicitly" do
      before(:each) do
        @person_class = Class.new(Object) {
          attr_accessor :given_name, :the_address
          include Veasycard
          veasycard do
            address :the_address
          end
        }
      end

      let(:person) {
        person = @person_class.new
        person.given_name = "Johnjohn"
        person.the_address = address
        person
      }

      context "and address attributes are mapped implicitly" do
        before(:each) do
          define_address_with_implicit_attribute_names
        end
        let(:address) { address_instance_with_implicit_attributes_names }

        it_behaves_like "address with correct content"
      end

      context "and address attributes are mapped explicitly" do

        before(:each) do
          @person_class = Class.new(Object) {
            attr_accessor :given_name, :the_address
            include Veasycard
            veasycard do
              address :the_address do
                country    :the_country
                locality   :the_locality
                pobox      :the_pobox
                region     :the_region
                street     :the_street
                supplement :the_extended
                zipcode    :the_postalcode
              end
            end
          }

          define_address_with_explicit_attribute_names
        end

        let(:address) { address_instance_with_explicit_attributes_names }

        it_behaves_like "address with correct content"
      end
    end

    context "when address is mapped to person implicitly" do
      before(:each) do
        @person_class = Class.new(Object) {
          include Veasycard
          attr_accessor :given_name, :home_address
        }
      end

      context "and address attributes are mapped implicitly" do
        before(:each) do
          define_address_with_implicit_attribute_names
        end

        let(:person) {
          person = @person_class.new
          person.given_name = "Johnjohn"
          person.home_address = address_instance_with_implicit_attributes_names
          person
        }

        it_behaves_like "address with correct content"
      end
    end

    context "when address attributes are on the person" do
      let(:person) {
        person = @person_class.new
        person.given_name = "Johnjohn"
        person.country    = address_values["country"]
        person.locality   = address_values["locality"]
        person.pobox      = address_values["pobox"]
        person.region     = address_values["region"]
        person.street     = address_values["street"]
        person.extended   = address_values["extended"]
        person.postalcode = address_values["postalcode"]
        person
      }

      context "when address is mapped to person explicitly" do
        before(:each) do
          @person_class = Class.new(Object) {
            attr_accessor :given_name,
                          :country,
                          :locality,
                          :pobox,
                          :region,
                          :street,
                          :extended,
                          :postalcode
            include Veasycard

            veasycard do
              address :self
            end
          }
        end

        it_behaves_like "address with correct content"
      end

      context "when address attributes are mapped implicitly to person" do
        before(:each) do
          @person_class = Class.new(Object) {
            attr_accessor :given_name,
                          :country,
                          :locality,
                          :pobox,
                          :region,
                          :street,
                          :extended,
                          :postalcode
            include Veasycard
          }
        end

        it_behaves_like "address with correct content"
      end
    end
  end

  describe '.address {}' do
    # TODO
    # veasycard do
    #   address :the_address, preferred: true, location: 'home' do
    #     ...
    #   end
    # end
    it "allows multiple addresses with options"
  end
end