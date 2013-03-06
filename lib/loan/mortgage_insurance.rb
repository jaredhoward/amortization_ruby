class Loan
  class MortgageInsurance
    extended_attr_accessor :monthly_premium_amount, :premium_11_29_amount, :cutoff_ltv, :property_value, kind_of: Numeric
    extended_attr_accessor :months_of_reserves, kind_of: Integer, validate: ->v{v >= 0}
    extended_attr_accessor :cutoff_month, kind_of: Integer, validate: ->v{v > 0}

    def initialize(options={})
      options = {
        monthly_premium_amount: 0.0,
        months_of_reserves: 0,
        cutoff_ltv: 0.0,
        property_value: 0.0
      }.merge(options)

      options.each do |key, value|
        send(:"#{key}=", value) if respond_to?(:"#{key}=")
      end
    end

    ###
    # Calculate the premium amount based on the month.
    ###
    def premium_for_month_number(month_number, principle)
      amount = monthly_premium_amount # start with the basic premium
      if premium_11_29_amount # check if we're into the 11-29 year premiums
        amount = premium_11_29_amount if month_number > 120 - months_of_reserves # factor in reserves
      end
      if !property_value.zero? && !cutoff_ltv.zero?
        amount = 0.0 if principle <= property_value * (cutoff_ltv / 100.0)
      end
      amount = 0.0 if cutoff_month && cutoff_month + 1 <= month_number
      return amount
    end

  end
end
