require_relative '../extend/custom_float'

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
    extended_attr_accessor :index, :margin, kind_of: Numeric, validate: ->v{v >= 0}, reset: :rate_cap
    extended_attr_accessor :cap_first, :cap_annual, :cap_ceiling, :cap_floor, kind_of: Numeric, validate: ->v{v >= 0}
    extended_attr_accessor :interest_fixed, :interest_adjusts, kind_of: Integer, validate: ->v{v > 0}
    extended_attr_accessor :no_adjustable_cap, kind_of: [TrueClass,FalseClass]

    def initialize(options={})
      options = {
        rounding_method: 2,
        index: 0.0,
        margin: 0.0,
        cap_first: 0.0,
        cap_annual: 0.0,
        cap_ceiling: 0.0,
        cap_floor: 0.0,
        interest_fixed: 0,
        interest_adjusts: 0,
        no_adjustable_cap: false
      }.merge(options)

      options.each do |key, value|
        send(:"#{key}=", value) if respond_to?(:"#{key}=")
      end
    end

    def rate_cap
      return @rate_cap if @rate_cap

      fully_indexed_rate = rounded_rate(_index + _margin)
      @rate_cap = fully_indexed_rate < _cap_ceiling ? fully_indexed_rate : _cap_ceiling
    end

    def rate_for_month_number(month_number, rate)
      if month_number > interest_fixed
        if (month_number - interest_fixed - 1) % interest_adjusts === 0
          cap_adjustment = if no_adjustable_cap != false
            rate_cap
          elsif month_number == interest_fixed + 1
            _cap_first
          else
            _cap_annual
          end
          if rate_cap > rate
            rate += cap_adjustment
            rate = rate_cap if rate > rate_cap
          else
            rate -= cap_adjustment
            rate = rate_cap if rate < rate_cap
          end
          rate = _cap_floor if rate < _cap_floor
          rate = rounded_rate(rate)
        end
      end
      return rate
    end

    def rounded_rate(rate)
      rate = (rate * 100.0).round(3)
      case rounding_method
      when 1
        up = rate.next_eighth
        up_diff = (rate - up).abs
        down = rate.last_eighth
        down_diff = (rate - down).abs
        rate = up_diff <= down_diff ? up : down
      when 2
        rate = rate.next_eighth
      when 3
        rate = rate.last_eighth
      when 4
        up = rate.next_fourth
        up_diff = (rate - up).abs
        down = rate.last_fourth
        down_diff = (rate - down).abs
        rate = up_diff <= down_diff ? up : down
      when 5
        rate = rate.next_fourth
      when 6
        rate = rate.last_fourth
      end
      return (rate / 100.0).round(5)
    end

    def method_missing(method_name, *args, &block)
      if method_name =~ /^_/ && method_name =~ /(index|margin|cap_first|cap_annual|cap_ceiling|cap_floor)$/
        (send(method_name.to_s.sub(/^_/, '').to_sym, *args, &block) / 100.0).round(5)
      else
        super
      end
    end

  end
end
