class Loan
  class Calculator

    ###
    # Calculate the monthly payment amount.  Hugh Chou style.
    ###
    def self.monthly_payment_amount(principle, rate, number_of_payments, payments_per_year)
      rate_per_payment = rate / payments_per_year
      return (principle * (rate_per_payment / (1 - ((1 + rate_per_payment) ** (-1 * number_of_payments))))).to_f.round(2)
    end

  end
end
