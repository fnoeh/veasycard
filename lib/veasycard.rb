require 'vpim'

module Veasycard

  def vcard(options={})
    card = Vpim::Vcard.create

    case options[:format]
    when :raw
      card.to_s
    else
      card
    end 
  end

end