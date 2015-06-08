require 'bigdecimal'

module BTC
  # Modeled after NSNumberFormatter in Cocoa, this class allows to convert
  # bitcoin amounts to their string representations and vice versa.
  class CurrencyFormatter

    STYLE_BTC       = :btc       # 1.0 is 1 btc (100_000_000 satoshis)
    STYLE_BTC_LONG  = :btc_long  # 1.00000000 is 1 btc (100_000_000 satoshis)
    STYLE_MBTC      = :mbtc      # 1.0 is 0.001 btc (100_000 satoshis)
    STYLE_BIT       = :bit       # 1.0 is 0.000001 btc (100 satoshis)
    STYLE_SATOSHIS  = :satoshis  # 1.0 is 0.00000001 btc (1 satoshi)

    attr_accessor :style
    attr_accessor :show_suffix

    # Returns a singleton formatter for BTC values (1.0 is one bitcoin) without suffix.
    def self.btc_formatter
      @btc_formatter ||= self.new(style: STYLE_BTC)
    end

    # Returns a singleton formatter for BTC values where there are always 8 places
    # after decimal point (e.g. "42.00000000").
    def self.btc_long_formatter
      @btc_long_formatter ||= self.new(style: STYLE_BTC_LONG)
    end

    def initialize(style: :btc, show_suffix: false)
      @style = style
      @show_suffix = show_suffix
    end

    # Returns formatted string for an amount in satoshis.
    def string_from_number(number)
      if @style == :btc
        number = number.to_i
        return "#{number / BTC::COIN}.#{'%08d' % [number % BTC::COIN]}".gsub(/0+$/,"").gsub(/\.$/,".0")
      elsif @style == :btc_long
        number = number.to_i
        return "#{number / BTC::COIN}.#{'%08d' % [number % BTC::COIN]}"
      else
        # TODO: parse other styles
        raise "Not implemented"
      end
    end

    # Returns amount of satoshis parsed from a formatted string according to style attribute.
    def number_from_string(string)
      bd = BigDecimal.new(string)
      if @style == :btc || @style == :btc_long
        return (bd * BTC::COIN).to_i
      else
        # TODO: support other styles
        raise "Not Implemented"
      end
    end

    # Creates a copy if you want to customize another formatter (e.g. a global singleton like btc_formatter)
    def dup
      self.class.new(style: @style, show_suffix: @show_suffix)
    end

  end # BitcoinFormatter
end # BTC
