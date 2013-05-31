# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'rspec', :version => 2 do
  
  watch('lib/veasycard.rb') do |m| 
    [
      'spec/address_mapping_spec.rb',
      'spec/veasycard_spec.rb'
    ]
  end

  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
  
  watch('spec/spec_helper.rb')  { "spec" }
  watch('.rspec')
  
  watch('lib/i18n.yml') { "spec --tag i18n" }
end

