class Loan
  class AdjustableRateMortgage
    ROUNDING_METHODS = {
      1 => 'TO THE NEAREST 1/8 %',
      2 => 'UP TO THE NEAREST 1/8 %',
      3 => 'DOWN TO THE NEAREST 1/8 %',
      4 => 'TO THE NEAREST 1/4 %',
      5 => 'UP TO THE NEAREST 1/4 %',
      6 => 'DOWN TO THE NEAREST 1/4 %',
      0 => 'DO NOT ROUND'
    }.freeze

    extended_attr_accessor :rounding_method, kind_of: Integer, validate: ->v{!ROUNDING_METHODS[v].nil?}
    extended_attr_accessor :index, :margin, :cap_first, :cap_annual, :cap_ceiling, :cap_floor, kind_of: Numeric, validate: ->v{v >= 0}
    extended_attr_accessor :interest_fixed, :interest_adjusts, kind_of: Integer, validate: ->v{v > 0}
    extended_attr_accessor :no_adjustable_cap, kind_of: [TrueClass,FalseClass]

    def initialize(options={})
      options = {
        rounding_method: 2
      }.merge(options)

      options.each do |key, value|
        send(:"#{key}=", value) if respond_to?(:"#{key}=")
      end
    end

    def method_missing(method_name, *args, &block)
      if method_name =~ /^_/ method_name =~ /(index|margin|cap_first|cap_annual|cap_ceiling|cap_floor)$/)
        (send(method_name.to_s.sub(/^_/, '').to_sym, *args, &block) / 100.0).round(5)
      else
        super
      end
    end

  end
end
