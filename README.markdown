> This is a work in progress. This gem is not yet ready for use.


# Introduction

With Veasycard you can easily create vCards for your ruby models.

It was designed to be used with as little code as possible on your part.

## Installation

Just add

    gem 'veasycard'

to your Gemfile and run `bundle install`.

Alternatively you can run `gem install veasycard`.


Veasycard uses [vPim](https://github.com/sam-github/vpim) by _Sam Roberts_, which will be installed automatically.


## Usage

Just include `Veasycard` in the model for which you want to generate vCards.

    class User
      attr_accessor :family_name
      include Veasycard
    end

You can then create a vCard with the `vcard` method.

    u = User.new
    u.family_name = "Matsumoto"
    u.vcard

This will return a Vpim::Vcard object as defined by the vPim gem. `to_s` yields the desired output or you can get the text by using the raw format.

    u.vcard(:format => :raw)

will return

    BEGIN:VCARD
    VERSION:3.0
    N:Matsumoto;;;;
    FN:Matsumoto
    END:VCARD


### Attribute mapping

If your model’s attributes use standard names, they will be mapped automatically.
For example this will work for any of the following attribute names which would fill in for the family name:

- family_name
- last_name
- surname

Similarly, these would be used for the given name:

- given_name
- first_name
- christian_name
- forename

If however your model uses less common attribute names, you can map them manually like in this spanish example.

```{ruby}
class Persona
  include Veasycard

  veasycard do
    family_name :apellido
    given_name  :nombre
  end
end
```

#### Address

When using standard attribute names for addresses, you should be good to go.

0. The address fields can be **stored inline** the Person/Company class.

    ```{ruby}
    person = Person.new
    person.family_name = "Holmes"
    person.street = "221B Baker Street"
    ```

0. An **associated address** will be picked up automatically.

    ```{ruby}
    address = Address.new
    address.street = "221B Baker Street"
    address.city = "London"

    person = Person.new
    person.family_name: "Holmes"
    person.address: address
    ```

0. The name of the associated address object can be **specified expliticly**.

    ```{ruby}
    class Person
      include Veasycard
      veasycard do
        address :living_at
      end
    end

    address = Address.new
    address.street = "221B Baker Street"
    address.city = "London"

	person.living_at = address
    ```

0. Not only the associated address object but also the **address fields** can be **specified explicitly**.

    ```{ruby}
    class Person
      include Veasycard
      veasycard do
        address :living_at do
          city :municipality
          street :name_of_street
        end
      end
    end

	address = Address.new
	address.municipality = "London"
	address.name_of_street = "221B Baker Street"

	person.living_at = address
    ```

0. **Non-standard address field names** can still be specified explicitly when **stored inline** the Person class.

    ```{ruby}
    class Person
      include Veasycard
      veasycard do
        address :self do
          city :municipality
          street :name_of_street
		end
      end
    end
    ```

### Internationalization

Veasycard can map non-english attribute names (currently german only).

Attribute names are provided by `lib/i18n.yml`. A model’s language must be set explicitly.

    class Anwender
      attr_accessor :nachname 		# german for last name

      include Veasycard::DE
    end
