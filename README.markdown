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


Until future versions of Veasycard add some magic, you have to map your model’s attributes like this

    class Persona
      include Veasycard

      attr_accessor :apellido, :nombre   # not necessary

      veasycard :family_name, :apellido
      veasycard :given_name, :nombre
    end
