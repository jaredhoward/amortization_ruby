class Loan
  class AdjustableRateMortgage
    attr_accessor :rounding_method, :index, :margin, :interest_fixed, :interest_adjusts
    attr_accessor :cap_no, :cap_first, :cap_annual, :cap_ceiling, :cap_floor

    def initialize(options={})
      options = {
      }.merge(options)

      options.each do |key, value|
        send(:"#{key}=", value) if respond_to?(:"#{key}=")
      end
    end

    def index=(value)
      raise "Index's value of '#{value}' is not allowed" unless value.kind_of?(Numeric)
      @index = value
    end

    def margin=(value)
      raise "Margin's value of '#{value}' is not allowed" unless value.kind_of?(Numeric)
      @margin = value
    end

    def interest_fixed=(value)
      raise "Interest fixed's value of '#{value}' is not allowed" unless value.kind_of?(Integer)
      @interest_fixed = value
    end

    def interest_adjusts=(value)
      raise "Interest adjusts' value of '#{value}' is not allowed" unless value.kind_of?(Integer)
      @interest_adjusts = value
    end

  end
end
