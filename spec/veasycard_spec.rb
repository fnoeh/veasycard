require 'spec_helper'

# this removes any Person class definition
def undef_person
  Object.send(:remove_const, :Person) if defined? Person
end

describe Veasycard do

  before :all do
    undef_person
  end

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
        attr_accessor :family_name
      end
      @p = Person.new
      @p.family_name = "Doe"
    end

    it "as object" do
      @p.vcard.should_not be_nil
      @p.vcard.class.should == Vpim::Vcard
    end

    it "in raw format" do
      result = @p.vcard({:format => :raw})
      result.class.should == String
      result.should match(/\ABEGIN:VCARD\n^VERSION:[\d\.]*.*\n^END:VCARD\n\z/m)
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

    it "includes provided names" do
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

  describe "Attribute mapping" do

    before(:each) do
      undef_person
    end

    it "uses standard names" do
      class Person
        include Veasycard
        attr_accessor :family_name
      end

      p = Person.new
      p.family_name = "foo"

      p.vcard.name.family.should == "foo"
    end

    it "uses alternative attribute names automatically" do
      class Person
        attr_accessor :last_name, :first_name
        include Veasycard
      end

      p = Person.new
      p.first_name = "John"
      p.last_name = "Doe"
      vcard = p.vcard

      lambda { vcard.name }.should_not raise_error

      vcard.name.family.should == "Doe"
      vcard.name.given.should == "John"
    end

    it "manual mapping takes precedence over automatic mapping" do

      class Person
        attr_accessor :family_name
        attr_accessor :the_name
        include Veasycard
        veasycard :family_name, :the_name
      end

      p = Person.new
      p.family_name = "family_name"
      p.the_name = "the_name"

      p.vcard.name.family.should == "the_name"
    end

    context "with i18n" do
      it "won't be activated implicitly" do
        class Person
          attr_accessor :nachname
          include Veasycard
        end

        p = Person.new
        p.nachname = "Mustermann"

        lambda {p.vcard.name}.should raise_error
      end

      it "can be activated explicitly" do
        class Person
          attr_accessor :nachname
          include Veasycard::DE
        end

        p = Person.new
        p.nachname = "Mustermann"

        p.vcard.name.family.should == "Mustermann"
      end
    end

    describe "e-mail addresses" do
      it "use standard attribute names" do
        class Person
          include Veasycard
          attr_accessor :family_name, :mail_address
        end

        p = Person.new
        p.family_name = "Doe"
        p.mail_address = "john.doe@example.com"

        p.vcard.email.should == p.mail_address
      end

      it "can be mapped to alternate attribute names" do
        class Person
          include Veasycard
          attr_accessor :family_name, :the_mail_address
          veasycard :email, :the_mail_address
        end

        p = Person.new
        p.family_name = "Doe"
        p.the_mail_address = "john.doe@example.com"

        p.vcard.email.should == p.the_mail_address
      end

      it "can have multiple e-mail addresses with options" do
        class Person
          include Veasycard
          attr_accessor :family_name, :mail_private, :mail_business
          veasycard :email, :mail_private, :location => "home"
          veasycard :email, :mail_business, :location => "work", :preferred => true
        end

        p = Person.new
        p.family_name = "Doe"
        p.mail_private = "john.doe.private@example.com"
        p.mail_business = "john.doe.business@example.com"

        card = p.vcard
        card.emails.should have(2).things

        business, home = card.emails
        if business == p.mail_private
          home,business = business,home
        end

        home.should == p.mail_private
        business.should == p.mail_business

        home.preferred.should == false
        business.preferred.should == true

        home.location.should include "home"
        business.location.should include "work"
      end
    end

    describe "date of birth" do

      context "standard locale" do
        before :each do
          class Person
            include Veasycard
            attr_accessor :dob, :family_name
          end

          @p = Person.new
          @p.family_name = "Doe"
        end

        it "accepts date objects as d.o.b." do
          @p.dob = Date.new(2005, 01, 14)
          @p.vcard.birthday.should == @p.dob
          @p.vcard.birthday.to_s.should == @p.dob.strftime("%Y-%m-%d")
        end

        it "accepts string as d.o.b." do
          @p.dob = "2004-03-19"
          @p.vcard.birthday.should == Date.new(2004, 3, 19) #@p.dob
          @p.vcard.birthday.to_s.should == @p.dob
        end

        it "can map d.o.b. manually" do
          class Person
            attr_accessor :the_date
            veasycard :birthday, :the_date
          end

          @p = Person.new
          @p.the_date = Date.new(1943, 11, 3)
          @p.family_name = "Doe"
          @p.vcard.birthday.should == @p.the_date
        end
      end
      
      context "other locale" do
        it "with implicit attribute mapping" do
          class Person
            include Veasycard::DE
            attr_accessor :nachname, :geburtstag
          end

          p = Person.new
          p.nachname = "Mustermann"
          p.geburtstag = Date.new(1993, 3, 9)
          p.vcard.birthday.should == p.geburtstag
        end

        it "with explicit attribute mapping" do
          class Person
            include Veasycard::DE
            attr_accessor :nachname, :tag
            veasycard :birthday, :tag
          end

          p = Person.new
          p.nachname = "Mustermann"
          p.tag = Date.new(1993, 3, 9)
          p.vcard.birthday.should == p.tag
        end
      end
    end
  end
end
