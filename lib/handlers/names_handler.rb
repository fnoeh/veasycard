module Handlers

  module NamesHandler

    class << self
    end

  private

    def handle_name(maker)
      maker.add_name do |name_maker|
        @names = {}

        [:family_name, :given_name].each do |name_type|
          if is_mapped_explicitly?(name_type)
            use_explicitly_mapped_name(name_type)
          else
            use_implicitly_mapped_name(name_type)
          end
        end

        fail_if_no_name_supplied
        add_names_to_maker(name_maker)
      end
    end

    def fail_if_no_name_supplied
      raise ArgumentError.new "no name supplied" if @names.values.compact.empty?
    end

    def add_names_to_maker(maker)
      maker.family = @names[:family_name] if @names[:family_name]
      maker.given  = @names[:given_name]  if @names[:given_name]
      maker.prefix = @names[:prefix]      if @names[:prefix]
    end

    def use_implicitly_mapped_name(type) # type = :(family|given)_name
      # byebug
      translated_name_attributes(type.to_s).each do |translation|
        if self.respond_to?(translation)
          @names[type] = self.send(translation)
          break
        end
      end
    end

    def use_explicitly_mapped_name(type) # type = :(family|given)_name
      mapped_attribute_name = @mapping[type]
      actual_value = self.send(mapped_attribute_name)
      @names[type] = actual_value
    end

    def translated_name_attributes(name_type)
      @i18n[self.veasycard_language.to_s]["attributes"][name_type]
    end

    def translated_family_name_attributes
      @i18n[self.veasycard_language.to_s]["attributes"]['family_name']
    end

    def translated_given_name_attributes
      @i18n[self.veasycard_language.to_s]["attributes"]['given_name']
    end
  end
end