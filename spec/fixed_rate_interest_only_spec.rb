require_relative '../lib/loan'

describe Loan do
  [
    {amount: 345_000, interest_rate: 7.75, interest_only_period: 120, total_prepaid_finance_amount: 2859.75, first_pi: 2228.13, normal_pi: 2832.27, last_pi: 2833.69, apr: 7.830}
  ].each do |loan_hash|
    context "fixed rate interest only" do
      let(:loan) { Loan.new(loan_hash) }

      it "should be the correct object" do
        loan.should be_an_instance_of Loan
      end

      context "amortization" do

        it "should have the correct p&i for the first payment" do
          loan.amortization.get_amortization[:table].first[:pi].should == loan_hash[:first_pi]
        end

        it "should have the correct p&i after the interest only period" do
          loan.amortization.get_amortization[:table][loan_hash[:interest_only_period]][:pi].should == loan_hash[:normal_pi]
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
