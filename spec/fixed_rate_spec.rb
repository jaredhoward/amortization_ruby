require_relative '../lib/loan'

describe Loan do
  [
    {amount: 345_000, interest_rate: 7.25, total_prepaid_finance_amount: 2703.05, pi: 2353.51, last_pi: 2351.23, apr: 7.329},
    {amount: 345_000, interest_rate: 6.75, total_prepaid_finance_amount: 2718, pi: 2237.66, last_pi: 2241.81, apr: 6.827},
    {amount: 500_000, interest_rate: 6, total_prepaid_finance_amount: 8818.8, pi: 2997.75, last_pi: 3000.44, apr: 6.167},
    {amount: 281_250, interest_rate: 6.875, total_prepaid_finance_amount: 5395.525, pi: 1847.61, last_pi: 1849.89, apr: 7.067}
  ].each do |loan_hash|
    context "fixed rate" do
      let(:loan) { Loan.new(loan_hash) }

      it "should be the correct object" do
        loan.should be_an_instance_of Loan
      end

      it "should have the correct monthly payment amount" do
        loan.monthly_payment_amount.should == loan_hash[:pi]
      end

      context "amortization" do

        it "should have the correct p&i" do
          loan.amortization.get_amortization[:table].first[:pi].should == loan_hash[:pi]
        end

        it "should have the correct p&i for the last payment" do
          loan.amortization.get_amortization[:table].last[:pi].should == loan_hash[:last_pi]
        end

        it "should have the correct apr" do
          loan.amortization.annual_percentage_rate.should == loan_hash[:apr]
        end

      end

    end
  end
end
