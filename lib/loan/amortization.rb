require_relative '../extend/custom_float'

class Loan
  class Amortization
    attr_reader :loan

    def initialize(loan)
      raise ArgumentError, "Amortization must be initialized with a Loan object" unless loan.instance_of?(Loan)
      @loan = loan
    end

    def can_calculate?(principle, rate, number_of_payments)
      principle && !principle.zero? && rate && !rate.zero? && number_of_payments && !number_of_payments.zero?
    end

    ###
    # Calculate the monthly payment amount.  Hugh Chou style.
    ###
    def calc_each_payment(principle, rate, number_of_payments, payments_per_year)
      unless can_calculate?(principle, rate, number_of_payments)
        return 0.0
      else
        rate_per_payment = rate / payments_per_year
        return (principle * (rate_per_payment / (1 - ((1 + rate_per_payment) ** (-1 * number_of_payments))))).to_f
      end
    end

    def get_amortization
      am = amort_variables

      if !can_calculate?(am[:rate], am[:number_of_payments], am[:principle])
        return {
          finance_charge: 0,
          total_of_payments: 0
        }
      else
        x = amortize(am)
        x[:finance_charge] = x[:total_of_payments] - am[:total_financed_amount]

        # $x_table = array();
        # $start_date = (!check_empty($row["application_first_payment_date"])) ? strtotime($row["application_first_payment_date"]) : "";
        # $const_period = 0;
        # foreach ($x["table"] as $key => $value) {
        #   $value["rate"] = round($value["rate"] * 100, 3);
        #   $value["date"] = (!check_empty($start_date) && $start_date != -1)
        #   ? date("M j, Y", mktime(0,0,0,date("n",$start_date)+$key-1,date("j",$start_date),date("Y",$start_date))) : "";
        # 
        #   if loan.purpose == 4
        #     if ($key <= $row["loan_program_construction_period"])
        #       $key = "Const Period ".$key;
        #     else
        #       $key -= $row["loan_program_construction_period"];
        #     end
        # 
        #     $x_table[$key] = $value;
        #   }
        #   $x["table"] = $x_table;
        # }

        return x
      end

    end

    def amort_variables
      return @amort_variables if @amort_variables

      @amort_variables = {
        loan: loan,
        principle: loan.amount,
        rate: loan._interest_rate,
        number_of_payments: loan.term,
        balloon: loan.balloon_months,
        payments_per_year: loan.payments_per_year,
        interest_only: loan.interest_only_period,
        total_financed_amount: loan.total_financed_amount
      }

      @amort_variables[:mi] = loan.mi if loan.has_mi?

      @amort_variables[:arm] = {
        rounding_method: loan.arm.rounding_method,
        index: loan.arm._index,
        margin: loan.arm._margin,
        interest_fixed: loan.arm.interest_fixed,
        interest_adjusts: loan.arm.interest_adjusts,
        no_adjustable_cap: loan.arm.no_adjustable_cap,
        cap_first: (!loan.arm.no_adjustable_cap ? loan.arm._cap_first : 0),
        cap_annual: (!loan.arm.no_adjustable_cap ? loan.arm._cap_annual : 0),
        cap_ceiling: loan.arm._cap_ceiling,
        cap_floor: loan.arm._cap_floor
      } if loan.is_arm?

      if loan.is_heloc?
        # @amort_variables[:heloc] = []
        # $heloc = array();
        # $x_payment = 1;
        # foreach ($row["_heloc"] as $heloc_value) {
        #   if ($heloc_value["heloc_type"] != 0) {
        #     $heloc[$x_payment] = array();
        #     $heloc[$x_payment]["rate"] = $heloc_value["heloc_rate"] / 100;
        # 
        #     if ($heloc_value["heloc_type"] == 1) $heloc[$x_payment]["type"] = "interest_only";
        #       elseif ($heloc_value["heloc_type"] == 2) $heloc[$x_payment]["type"] = "amortize";
        #       elseif ($heloc_value["heloc_type"] == 3) $heloc[$x_payment]["type"] = "percent_of_balance";
        # 
        #       $heloc[$x_payment]["interest_only_ends"] = ($heloc_value["heloc_type"] == 1) ? $x_payment + $heloc_value["heloc_term"] - 1 : 0;
        #       $heloc[$x_payment]["percentage"] = ($heloc_value["heloc_type"] == 3) ? $heloc_value["heloc_payment_percent"] / 100 : 0;
        #       $heloc[$x_payment]["percentage_ends"] = ($heloc_value["heloc_type"] == 3) ? $x_payment + $heloc_value["heloc_term"] - 1 : 0;
        # 
        #       $x_payment += $heloc_value["heloc_term"];
        #     }
        #   }
        # }
      end

      @amort_variables[:construction] = {
        rate: (loan.purpose == 4 ? loan._construction_rate : 0),
        payments: (loan.purpose == 4 ? loan.construction_period : @amort_variables[:number_of_payments])
      } if loan.is_construction?

      return @amort_variables
    end

    def annual_percentage_rate
      @annual_percentage_rate ||= (calc_apr * 100.0).round(3)
    end

    ###
    # Produce an amortization table with all the fixin's and return it all in a tidy array.
    #   mi = array: premium, 11_29, reserves, property_value, cutoff_ltv, cutoff_month
    #   arm = array: rounding_method, index, margin, interest_fixed, interest_adjusts, cap_ceiling, cap_first, cap_annual, cap_floor
    #   construction = array: payments, rate
    ###
    def amortize(options)
      opts = options.dup
      principle = opts.delete(:principle)
      rate = opts.delete(:rate)
      number_of_payments = opts.delete(:number_of_payments)
      payment_amount = opts.delete(:payment_amount)
      balloon = opts.delete(:balloon) || 0
      payments_per_year = opts.delete(:payments_per_year)
      mi = opts.delete(:mi)
      arm = opts.delete(:arm)
      construction = opts.delete(:construction)
      amort_table = opts.delete(:amort_table)
      interest_only = opts.delete(:interest_only) || 0
      heloc = opts.delete(:heloc)

      # initialize some stuff
      report = {table: []}
      payment_number = 0
      total_interest = 0.0
      total_principle = 0.0
      total_mi = 0.0
      total_of_payments = 0.0
      percent_of_balance = 0
      percent_of_balance_ends = 0
      rate_per_payment = rate / payments_per_year

      if construction && !construction[:payments].zero?
        if construction[:rate].zero?
          construction[:rate] = rate # Construction
        else
          balloon += construction[:payments] # Construction-Perm
        end
        number_of_payments += construction[:payments]
        interest_only += construction[:payments]
        payment_amount = ((principle / 2) * (construction[:rate] / payments_per_year)).to_f.round(2)
      end

      interest_only = balloon if !balloon.zero? && interest_only > balloon

      # if the payment amount wasn't specified, go get it...
      unless payment_amount
        payment_amount = loan.monthly_payment_amount # calc_each_payment(amort_variables[:principle], amort_variables[:rate], amort_variables[:number_of_payments], payments_per_year)
      else
        payment_amount = payment_amount.to_f.round(2)
      end
      report[:payment_amount] = payment_amount

      if construction && !construction[:payments].zero?
        if amort_table != false
          construction_principle = amort_table[:construction_principle]
        else
          construction_principle = principle / 2
        end
      end

      while payment_number < number_of_payments do
        payment_number += 1
        if amort_table == false && heloc && heloc[payment_number] && heloc[payment_number][:type]
          rate = heloc[payment_number][:rate]
          rate_per_payment = rate / payments_per_year
          case heloc[payment_number][:type]
          when "interest_only"
            interest_only = heloc[payment_number][:interest_only_ends]
            percent_of_balance = 0
          when "amortize"
            percent_of_balance = 0
          when "percent_of_balance"
            percent_of_balance = heloc[payment_number][:percentage]
            percent_of_balance_ends = heloc[payment_number][:percentage_ends]
          end
        end

        if amort_table # doing APR, the payment amounts are already known
          payment_amount = amort_table[payment_number-1][:pi]
        else # non-APR
          if arm
            oldrate = rate.dup
            rate = calc_arm(arm, payment_number, rate)
            rate_per_payment = rate / payments_per_year
            if rate != oldrate # only recalculate payment amount when the rate changes
              payment_amount = calc_each_payment(principle, rate, number_of_payments - payment_number + 1, payments_per_year).round(2)
            end
          end
        end

        this_interest = if construction && !construction[:payments].zero? && payment_number <= construction[:payments]
          if amort_table == false
            construction_principle * (construction[:rate] / payments_per_year)
          else
            construction_principle * rate_per_payment
          end
        else
          principle * rate_per_payment
        end.to_f.round(2)
        total_interest += this_interest

        this_mi = mi ? mi.premium_for_month_number(payment_number, principle) : 0.0
        total_mi += this_mi

        unless amort_table
          if payment_number <= interest_only
            payment_amount = this_interest
          elsif !percent_of_balance.zero?
            payment_amount = (principle * percent_of_balance).to_f.round(2)
          elsif (!interest_only.zero? && interest_only == payment_number - 1) || (!percent_of_balance_ends.zero? && percent_of_balance_ends == payment_number - 1)
            payment_amount = calc_each_payment(principle, rate, number_of_payments - payment_number + 1, payments_per_year).round(2)
          end
        end
        if payment_number == balloon && amort_table == false
          payment_amount += (principle + this_interest - payment_amount).to_f.round(2)
        end
        total_principle += payment_amount + this_mi - this_interest
        total_of_payments += payment_amount + this_mi

        # adjust principle
        # we round to avoid lousy PHP double-precision wanderings
        principle = if amort_table
          principle + this_interest - payment_amount - this_mi
        else
          principle + this_interest - payment_amount
        end.to_f.round(2)

        # fill out the report
        report[:table] << {
          pi: payment_amount,
          rate: construction && !construction[:payments].zero? && payment_number <= construction[:payments] ? construction[:rate] : rate,
          interest_paid: this_interest,
          interest_paid_total: total_interest,
          mi_paid: this_mi,
          mi_paid_total: total_mi,
          principle_paid: payment_amount - this_interest,
          principle_paid_total: total_principle,
          balance: construction && !construction[:payments].zero? && payment_number <= construction[:payments] ? construction_principle : principle
        }

        report[:mi_cutoff_month] = payment_number - 1 if !report[:mi_cutoff_month] && this_mi.zero?
        break if payment_number == balloon
      end
      report[:mi_cutoff_month] = payment_number if !report[:mi_cutoff_month] && !this_mi.zero?
      report[:final_adjustment] = principle

      last_payment_item = report[:table].last
      last_payment_item[:principle_paid] = (last_payment_item[:principle_paid] + principle).to_f.round(2)
      last_payment_item[:principle_paid_total] = (last_payment_item[:principle_paid_total] + principle).to_f.round(2)
      last_payment_item[:pi] = (last_payment_item[:pi] + principle).to_f.round(2)
      last_payment_item[:balance] = (last_payment_item[:balance] - principle).to_f.round(2)

      report[:total_of_payments] = total_of_payments + principle

      return report
    end

    ###
    # Calculate adjustable interest rate.
    ###
    def calc_arm(arm, payment, rate)
      if payment > arm[:interest_fixed]
        fully_indexed_rate = round_type(arm[:rounding_method], (arm[:index] + arm[:margin]))
        interest_cap = fully_indexed_rate < arm[:cap_ceiling] ? fully_indexed_rate : arm[:cap_ceiling]
        if (payment - arm[:interest_fixed] - 1) % arm[:interest_adjusts] == 0
          if arm[:no_caps] != false
            this_cap = interest_cap
          elsif payment == arm[:interest_fixed] + 1
            this_cap = arm[:cap_first]
          else
            this_cap = arm[:cap_annual]
          end
          if interest_cap > rate
            rate += this_cap
            rate = interest_cap if rate > interest_cap
          else
            rate -= this_cap
            rate = interest_cap if rate < interest_cap
          end
          rate = arm[:cap_floor] if rate < arm[:cap_floor]
          rate = round_type(arm[:rounding_method], rate)
        end
      end
      return rate
    end

    def round_type(type, num)
      num = (num * 100.0).round(3)
      case type
      when 1
        up = num.next_eighth
        up_diff = (num - up).abs
        down = num.last_eighth
        down_diff = (num - down).abs
        num = up_diff <= down_diff ? up : down
      when 2
        num = num.next_eighth
      when 3
        num = num.last_eighth
      when 4
        up = num.next_fourth
        up_diff = (num - up).abs
        down = num.last_fourth
        down_diff = (num - down).abs
        num = up_diff <= down_diff ? up : down
      when 5
        num = num.next_fourth
      when 6
        num = num.last_fourth
      end
      return (num / 100.0).round(5)
    end


    private


    ###
    # Calculate the annual percentage rate.
    ###
    def calc_apr
      opts = amort_variables.dup

      amort_table = amortize(opts)

      # in determining the APR we must ensure that MI is tabulated based on a cutoff payment number and not on LTV
      if opts[:mi] && opts[:mi][:cutoff_ltv]
        opts[:mi][:cutoff_ltv] = nil
        opts[:mi][:cutoff_month] = amort_table[:mi_cutoff_month]
      end
      if opts[:construction] && opts[:construction][:payments]
        amort_table[:table][:construction_principle] = opts[:principle] / 2 - (opts[:principle] - opts[:amount_financed])
      end

      opts.update(principle: opts[:total_financed_amount], payment_amount: amort_table[:payment_amount], interest_only: 0, amort_table: amort_table[:table])

      apr = opts[:loan]._interest_rate
      while amort_table[:final_adjustment] < 0
        apr += 0.1
        amort_table = amortize(opts.merge(rate: apr))
      end
      while amort_table[:final_adjustment] > 0
        apr -= 0.01
        amort_table = amortize(opts.merge(rate: apr))
      end
      while amort_table[:final_adjustment] < 0
        apr += 0.001
        amort_table = amortize(opts.merge(rate: apr))
      end
      while amort_table[:final_adjustment] > 0
        apr -= 0.0001
        amort_table = amortize(opts.merge(rate: apr))
      end
      while amort_table[:final_adjustment] < 0
        apr += 0.00001
        amort_table = amortize(opts.merge(rate: apr))
      end
      while amort_table[:final_adjustment] > 0
        apr -= 0.000001
        amort_table = amortize(opts.merge(rate: apr))
      end
      while amort_table[:final_adjustment] < 0
        apr += 0.0000001
        amort_table = amortize(opts.merge(rate: apr))
      end

      return apr
    end

  end
end
