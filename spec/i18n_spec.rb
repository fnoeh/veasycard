require 'spec_helper'
require 'yaml'

describe "I18n" do
	describe "Standard attribute names are provided for" do
		it "english" do
			yml = YAML.load_file("lib/i18n.yml")
			yml["en"]["family_name"].should include "last_name"
			yml["en"]["given_name"].should include "first_name"
		end
	end
end