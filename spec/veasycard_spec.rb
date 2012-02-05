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
      @p.vcard({:format => :raw}).class.should == String
    end
  end

end