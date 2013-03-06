require_relative '../lib/loan'

describe Loan do

  context "attribute validation" do

    it "should only allow numbers for amount" do
      Loan.new(amount: 100_000).should be_an_instance_of(Loan)
      Loan.new(amount: 100_000.0).should be_an_instance_of(Loan)
      expect { Loan.new(amount: '') }.to raise_error(ArgumentError)
      expect { Loan.new(amount: {}) }.to raise_error(ArgumentError)
      expect { Loan.new(amount: []) }.to raise_error(ArgumentError)
    end

    it "should only allow numbers greater than zero for amount" do
      Loan.new(amount: 100_000).should be_an_instance_of(Loan)
      expect { Loan.new(amount: 0) }.to raise_error(ArgumentError)
      expect { Loan.new(amount: -100_000) }.to raise_error(ArgumentError)
    end

    it "should only allow numbers for amount" do
      Loan.new(interest_rate: 5).should be_an_instance_of(Loan)
      Loan.new(interest_rate: 5.25).should be_an_instance_of(Loan)
      expect { Loan.new(interest_rate: '') }.to raise_error(ArgumentError)
      expect { Loan.new(interest_rate: {}) }.to raise_error(ArgumentError)
      expect { Loan.new(interest_rate: []) }.to raise_error(ArgumentError)
    end

    it "should only allow numbers greater than zero for interest_rate" do
      Loan.new(interest_rate: 5.25).should be_an_instance_of(Loan)
      expect { Loan.new(interest_rate: 0) }.to raise_error(ArgumentError)
      expect { Loan.new(interest_rate: -5.25) }.to raise_error(ArgumentError)
    end

    it "should only allow integers for term" do
      Loan.new(term: 360).should be_an_instance_of(Loan)
      expect { Loan.new(term: 360.0) }.to raise_error(ArgumentError)
      expect { Loan.new(term: '') }.to raise_error(ArgumentError)
      expect { Loan.new(term: {}) }.to raise_error(ArgumentError)
      expect { Loan.new(term: []) }.to raise_error(ArgumentError)
    end

    it "should only allow integers greater than zero for term" do
      Loan.new(term: 360).should be_an_instance_of(Loan)
      expect { Loan.new(term: 0) }.to raise_error(ArgumentError)
      expect { Loan.new(term: -360) }.to raise_error(ArgumentError)
    end

    it "should only allow integers for payments_per_year" do
      Loan.new(payments_per_year: 12).should be_an_instance_of(Loan)
      expect { Loan.new(payments_per_year: 12.0) }.to raise_error(ArgumentError)
      expect { Loan.new(payments_per_year: '') }.to raise_error(ArgumentError)
      expect { Loan.new(payments_per_year: {}) }.to raise_error(ArgumentError)
      expect { Loan.new(payments_per_year: []) }.to raise_error(ArgumentError)
    end

    it "should only allow integers greater than zero for term" do
      Loan.new(payments_per_year: 12).should be_an_instance_of(Loan)
      expect { Loan.new(payments_per_year: 0) }.to raise_error(ArgumentError)
      expect { Loan.new(payments_per_year: -12) }.to raise_error(ArgumentError)
    end

    it "should only allow numbers for total_prepaid_finance_amount" do
      Loan.new(total_prepaid_finance_amount: 2_000).should be_an_instance_of(Loan)
      Loan.new(total_prepaid_finance_amount: 2_000.0).should be_an_instance_of(Loan)
      expect { Loan.new(total_prepaid_finance_amount: '') }.to raise_error(ArgumentError)
      expect { Loan.new(total_prepaid_finance_amount: {}) }.to raise_error(ArgumentError)
      expect { Loan.new(total_prepaid_finance_amount: []) }.to raise_error(ArgumentError)
    end

    it "should only allow numbers greater or equal to zero for total_prepaid_finance_amount" do
      Loan.new(total_prepaid_finance_amount: 0).should be_an_instance_of(Loan)
      Loan.new(total_prepaid_finance_amount: 2_000).should be_an_instance_of(Loan)
      expect { Loan.new(total_prepaid_finance_amount: -2_000) }.to raise_error(ArgumentError)
    end

    it "should only allow numbers for closing_costs_paid_by_seller_amount" do
      Loan.new(closing_costs_paid_by_seller_amount: 2_000).should be_an_instance_of(Loan)
      Loan.new(closing_costs_paid_by_seller_amount: 2_000.0).should be_an_instance_of(Loan)
      expect { Loan.new(closing_costs_paid_by_seller_amount: '') }.to raise_error(ArgumentError)
      expect { Loan.new(closing_costs_paid_by_seller_amount: {}) }.to raise_error(ArgumentError)
      expect { Loan.new(closing_costs_paid_by_seller_amount: []) }.to raise_error(ArgumentError)
    end

    it "should only allow numbers greater or equal to zero for closing_costs_paid_by_seller_amount" do
      Loan.new(closing_costs_paid_by_seller_amount: 0).should be_an_instance_of(Loan)
      Loan.new(closing_costs_paid_by_seller_amount: 2_000).should be_an_instance_of(Loan)
      expect { Loan.new(closing_costs_paid_by_seller_amount: -2_000) }.to raise_error(ArgumentError)
    end

  end

  context "attribute reset" do
    let(:loan) { l = Loan.new; l.amortization; l }

    it "should have an amortization ready" do
      loan.instance_variable_get(:@amortization).should be_an_instance_of(Loan::Amortization)
    end

    it "should reset amortization when amount is changed" do
      loan.amount = 100_000
      loan.instance_variable_get(:@amortization).should be_nil
    end

    it "should reset amortization when interest_rate is changed" do
      loan.interest_rate = 5.25
      loan.instance_variable_get(:@amortization).should be_nil
    end

    it "should reset amortization when term is changed" do
      loan.term = 360
      loan.instance_variable_get(:@amortization).should be_nil
    end

    it "should reset amortization when payments_per_year is changed" do
      loan.payments_per_year = 12
      loan.instance_variable_get(:@amortization).should be_nil
    end

    it "should reset amortization when total_prepaid_finance_amount is changed" do
      loan.total_prepaid_finance_amount = 2_000
      loan.instance_variable_get(:@amortization).should be_nil
    end

    it "should reset amortization when closing_costs_paid_by_seller_amount is changed" do
      loan.closing_costs_paid_by_seller_amount = 2_000
      loan.instance_variable_get(:@amortization).should be_nil
    end

  end

end
