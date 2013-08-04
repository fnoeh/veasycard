require 'spec_helper'

describe Veasycard do

  describe "method vcard" do
    before :all do
      undef_person
    end

    it "added to class with \"include Veasycard\"" do
      class Person
      end

      p = Person.new
      p.should_not respond_to :vcard

      class Person
        include Veasycard
      end

      p.should respond_to :vcard
    end

    context "raises Exception" do
      it "when instance has no name components" do
        p = Person.new # this one has no name
        lambda {p.vcard}.should raise_error(ArgumentError, "no name supplied")
      end

      it "when name components have not been mapped" do
        class Person
          include Veasycard
          attr_accessor :the_name, :mail_address

          veasycard do
            email :mail_address
          end
        end

        p = Person.new
        p.mail_address = "john.doe@example.com"
        lambda {p.vcard}.should raise_error(ArgumentError, "no name supplied")
      end
    end

    describe "returns vCard" do
      before(:all) do
        undef_person

        class Person
          include Veasycard
          attr_accessor :family_name
        end
        @p = Person.new
        @p.family_name = "Doe"
      end

      it "as Vpim::Vcard object" do
        @p.vcard.should_not be_nil
        @p.vcard.class.should == Vpim::Vcard
      end

      it "in raw format" do
        result = @p.vcard({:format => :raw})
        result.class.should == String
        result.should match(/\ABEGIN:VCARD\n^VERSION:[\d\.]*.*\n^END:VCARD\n\z/m)
      end
    end

    describe "output" do
      before(:all) do
        undef_person

        class Person
          attr_accessor :last_name,
                        :first_name,
                        :birthday,
                        :email

          include Veasycard
        end
      end

      it "contains provided attributes" do
        p = Person.new
        p.last_name  = "Doe"
        p.first_name = "John"
        p.birthday   = Date.new(1950, 1, 1)
        p.email      = "john.doe@example.com"

        p.vcard(:format => :raw).should match(/^N:Doe;John;;;/)
        p.vcard(:format => :raw).should match(/^BDAY:19500101$/)
        p.vcard(:format => :raw).should match(/^EMAIL:john\.doe@example\.com$/)
      end
    end
  end

  describe "attribute mapping" do

    before(:each) do
      undef_person
    end

    it "will be done implicitly" do
      class Person
        include Veasycard

        attr_accessor :family_name,
                      :first_name,
                      :mail_address
      end

      p = Person.new
      p.family_name  = "Doe"
      p.first_name   = "John"
      p.mail_address = "John.Doe@example.com"

      p.vcard.name.family.should == p.family_name
      p.vcard.name.given.should  == p.first_name
      p.vcard.email              == p.mail_address
    end

    it "can be done explicitly" do
      class Person
        include Veasycard
        attr_accessor :the_last_name,
                      :the_first_name

        veasycard do
          family_name :the_last_name
          given_name  :the_first_name
        end
      end

      p = Person.new
      p.the_last_name  = "Doe"
      p.the_first_name = "John"

      card = p.vcard

      card.name.family.should == "Doe"
      card.name.given.should  == "John"
    end

    it "explicit mapping takes precedence over implicit mapping" do
      class Person
        include Veasycard
        attr_accessor :family_name,
                      :the_name

        veasycard do
          family_name :the_name
        end
      end

      p = Person.new
      p.family_name = "dontusethisone"
      p.the_name    = "Correctname"

      p.vcard.name.family.should == p.the_name
    end

    it "allows multiple e-mail addresses with options" do
      class Person
        include Veasycard
        attr_accessor :family_name,
                      :mail_private,
                      :mail_business

        veasycard do
          email :mail_private,  :location => "home", :preferred => true
          email :mail_business, :location => "work"
        end
      end

      p = Person.new
      p.family_name   = "Doe"
      p.mail_private  = "john.doe.private@example.com"
      p.mail_business = "john.doe.business@example.com"

      card = p.vcard
      card.emails.should have(2).things
      card.email.should             == p.mail_private # the one that has preferred: true

      home_address = card.emails.select { |i| i.location == ["home"] }.first
      home_address.location.should  == ["home"]
      home_address.preferred.should == true
      home_address.to_s.should      == p.mail_private

      work_address = card.emails.select { |i| i.location == ["work"] }.first
      work_address.location.should  == ["work"]
      work_address.preferred.should == false
      work_address.to_s.should      == p.mail_business
    end

    describe "date of birth" do

      before :each do
        class Person
          include Veasycard
          attr_accessor :dob,
                        :family_name
        end

        @p = Person.new
        @p.family_name = "Doe"
      end

      it "can be date object" do
        @p.dob = Date.new(2005, 01, 14)
        @p.vcard.birthday.should == @p.dob
        @p.vcard.birthday.to_s.should == @p.dob.strftime("%Y-%m-%d")
      end

      it "can be string" do
        date = "2004-03-19"
        @p.dob = date
        @p.vcard.birthday.should == Date.new(2004, 3, 19)
        @p.vcard.birthday.to_s.should == date
      end
    end
  end
end
