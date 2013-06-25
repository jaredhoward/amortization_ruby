require_relative '../lib/loan'

describe Loan do
  [
    {
      amount: 318_320, interest_rate: 6.050, term: 480, total_prepaid_finance_amount: 5376,
      arm: {rounding_method: 2, index: 3.329, margin: 4.990, cap_first: 0, cap_annual: 2.000, cap_ceiling: 9.999, cap_floor: 6.050, interest_fixed: 24, interest_adjusts: 6, no_adjustable_cap: false},
      payments: [[1,1762.55,0.0605],[25,1778.81,0.06125],[31,2227.88,0.08125],[37,2285.87,0.08375],[480,2288.26,0.08375]], apr: 8.041
    },
    {
      amount: 661_500, interest_rate: 5.125, term: 360, total_prepaid_finance_amount: 12_658.37,
      arm: {rounding_method: 2, index: 3.000, margin: 2.750, cap_first: 2.000, cap_annual: 2.000, cap_ceiling: 9.999, cap_floor: 0, interest_fixed: 84, interest_adjusts: 12, no_adjustable_cap: false},
      payments: [[1,3601.78,0.05125],[85,3814.21,0.05750],[360,3811.87,0.05750]], apr: 5.611
    },
    {
      amount: 395_120, interest_rate: 5.850, term: 360, interest_only_period: 24, total_prepaid_finance_amount: 5298.19,
      arm: {rounding_method: 2, index: 3.850, margin: 3.800, cap_first: 5.000, cap_annual: 2.000, cap_ceiling: 5.000, cap_floor: 7.200, interest_fixed: 24, interest_adjusts: 12, no_adjustable_cap: false},
      payments: [[1,1926.21,0.05850],[25,2750.66,0.07250],[360,2745.29,0.07250]], apr: 7.127
    }
  ].each do |loan_hash|
    context "adjustable rate mortgage: $#{loan_hash[:amount]} #{loan_hash[:interest_rate]}% #{loan_hash[:term]}mths" do
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
