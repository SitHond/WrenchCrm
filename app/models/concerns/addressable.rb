module Addressable
  extend ActiveSupport::Concern

  def address_lines
    [ address1, address2, [ zip, city ].compact_blank.join(" "), state, country ].compact_blank
  end
end
