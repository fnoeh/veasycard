require 'spec_helper'

describe Veasycard do

  it "adds method :vcard to class" do
    class Person
    end
    
    p = Person.new
    
    p.should_not respond_to :vcard

    class Person
      include Veasycard
    end

    p.should respond_to :vcard
  end

  describe "returns vCard" do
    before(:all) do
      class Person
        include Veasycard
      end
      @p = Person.new
    end

    it "as object" do
      @p.vcard.should_not be_nil
      @p.vcard.class.should == Vpim::Vcard
    end

    it "in raw format" do
      result = @p.vcard({:format => :raw})
      result.class.should == String
      result.should match(/\ABEGIN:VCARD\n^VERSION:[\d\.]*\n^END:VCARD\n\z/)
    end
  end

  context "Usage" do

    before(:all) do
      class Person
        attr_accessor :last_name
        attr_accessor :first_name
        
        include Veasycard

        veasycard :family_name, :last_name
        veasycard :given_name, :first_name
      end
    end

    it "can map attribute names" do
      mappings = Person.veasycard_attribute_mapping
      mappings.should_not be_nil
      mappings.keys.should include(:family_name, :given_name)
    end

    it "includes given names" do
      p = Person.new
      p.last_name = "Doe"
      p.first_name = "John"
      
      p.vcard(:format => :raw).should match(/^N:Doe;John;;;/)
    end

    context "raises Exception" do
      it "when instance has no name components" do
        p = Person.new # this one has no name
        lambda {p.vcard}.should raise_error(ArgumentError, "no name supplied")
      end
      it "when name components have not been mapped" do
        class User
          include Veasycard
          veasycard :email, :mail_address
        end

        u = User.new
        lambda {u.vcard}.should raise_error(ArgumentError, "no name supplied")
      end
    end

  end
end