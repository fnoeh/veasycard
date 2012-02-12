> This is a work in progress. This gem is not yet ready for use.


# Introduction

With Veasycard you can easily create vCards for your ruby models.

## Installation

Just add

    gem 'veasycard'

to your Gemfile and run `bundle install`.

Alternatively you can run `gem install veasycard`.


Veasycard uses [vPim](https://github.com/sam-github/vpim) by _Sam Roberts_, which will be installed automatically.


## Usage

Just include `Veasycard` in the model for which you want to generate vCards.

    class User
      include Veasycard
    end

You can then create a vCard with the `vcard` method.

    u = User.new
    u.vcard(:format => :raw)


### Attribute mapping

If your model’s attributes use standard names, they will be mapped automatically.
For example this will work for any of the following attribute names which would fill in for the family name:

- family_name
- last_name
- surname

Similarly, these would be used for the given_name:

- given_name
- first_name
- christian_name
- forename

If however your model uses less common attribute names, you can map them manually like in this spanish example:

    class Persona
      include Veasycard

      attr_accessor :apellido, :nombre   # not necessary

      veasycard :family_name, :apellido
      veasycard :given_name, :nombre
    end
