require_relative '../lib/loan'

describe Loan do
  [
    {
      amount: 318_320, interest_rate: 6.050, term: 480, total_prepaid_finance_amount: 5376,
      arm: {rounding_method: 2, index: 3.329, margin: 4.990, cap_first: 0, cap_annual: 2.000, cap_ceiling: 9.999, cap_floor: 6.050, interest_fixed: 24, interest_adjusts: 6, no_adjustable_cap: false},
      payments: [[1,1762.55,0.0605],[25,1778.81,0.06125],[31,2227.88,0.08125],[37,2285.87,0.08375],[480,2288.26,0.08375]], apr: 8.041
    }
  ].each do |loan_hash|
    context "adjustable rate mortgage" do
      let(:loan) { Loan.new(loan_hash) }

      it "should be the correct loan object" do
        loan.should be_an_instance_of(Loan)
      end

      it "should be the correct arm object" do
        loan.arm.should be_an_instance_of(Loan::AdjustableRateMortgage)
      end

      context "amortization" do

        it "should have the correct apr" do
          loan.amortization.annual_percentage_rate.should == loan_hash[:apr]
        end

        loan_hash[:payments].each do |payment|
          context "payment ##{payment[0]}" do

            it "should have the correct p&i" do
              loan.amortization.get_amortization[:table][payment[0]-1][:pi].should == payment[1]
            end

            it "should have the correct interest rate" do
              loan.amortization.get_amortization[:table][payment[0]-1][:rate].should == payment[2]
            end

          end
        end

      end

    end
  end
end
