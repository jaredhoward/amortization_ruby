require_relative './extend/custom_class'
require_relative './loan/adjustable_rate_mortgage'
require_relative './loan/amortization'
require_relative './loan/calculator'
require_relative './loan/mortgage_insurance'

class Loan
  attr_reader :purpose, :program, :arm
  attr_accessor :mi
  extended_attr_accessor :amount, :interest_rate, :total_financed_amount, kind_of: Numeric, validate: ->v{v > 0}, reset: :amortization
  extended_attr_accessor :term, :payments_per_year, kind_of: Integer, validate: ->v{v > 0}, reset: :amortization
  extended_attr_accessor :total_prepaid_finance_amount, :closing_costs_paid_by_seller_amount, :additional_costs, kind_of: Numeric, validate: ->v{v >= 0}, reset: :amortization
  extended_attr_accessor :interest_only_period, kind_of: Integer, validate: ->v{v >= 0}, reset: :amortization
  attr_accessor :balloon_months
  attr_accessor :construction_rate, :construction_period

  def initialize(options={})
    options = {
      term: 360,
      payments_per_year: 12,
      total_prepaid_finance_amount: 0.0,
      closing_costs_paid_by_seller_amount: 0.0
    }.merge(options)

    options.each do |key, value|
      send(:"#{key}=", value) if respond_to?(:"#{key}=")
    end
  end

  def can_calculate?
    amount && interest_rate && term && payments_per_year ? true : false
  end

  def monthly_payment_amount
    return 0.0 unless can_calculate?

    Loan::Calculator.monthly_payment_amount(amount, _interest_rate, term, payments_per_year)
  end

  def amortization
    @amortization ||= Loan::Amortization.new(self)
  end

  def total_financed_amount
    @total_financed_amount || (amount - total_prepaid_finance_amount + closing_costs_paid_by_seller_amount)
  end

  def has_mi?
    mi.instance_of?(Loan::MortgageInsurance)
  end

  def purpose=(value, options={})
    value = case value.downcase
    when 'purchase' then 1
    when 'refinance' then 2
    when 'construction' then 3
    when 'construction-perm' then 4
    when 'other' then 5
    else value
    end if value.instance_of?(String)

    raise "Purpose value of '#{value}' is not allowed" unless (1..5).to_a.include?(value)
    @purpose = value

    if is_construction?
      construction_rate = options[:construction_rate] if options[:construction_rate]
      construction_period = options[:construction_period] if options[:construction_period]
    end
  end

  def program=(value, options={})
    value = case value.downcase
    when 'fixed' then 1
    when 'heloc', 'home equity line of credit' then 2
    when 'arm', 'adjustable rate mortgage' then 3
    when 'monthly arm', 'monthly adjustable rate mortgage' then 4
    when 'gpm', 'graduated payment mortgage' then 5
    when 'two step' then 6
    else value
    end if value.instance_of?(String)

    raise "Program value of '#{value}' is not allowed" unless (1..6).to_a.include?(value)
    @program = value
  end

  def arm=(adjustable_rate_mortgage)
    @amortization = nil
    @arm = if adjustable_rate_mortgage.instance_of?(Loan::AdjustableRateMortgage)
      adjustable_rate_mortgage
    elsif adjustable_rate_mortgage.instance_of?(Hash)
      Loan::AdjustableRateMortgage.new(adjustable_rate_mortgage)
    else
      nil
    end
  end

  def is_arm?
    # [3,4].include?(program)
    arm.instance_of?(Loan::AdjustableRateMortgage)
  end

  def is_heloc?
    # heloc_numrows("heloc_loan_program_id", $row["loan_program_id"]) != 0
    program == 2
  end

  def is_construction?
    [3,4].include?(purpose)
  end

  def method_missing(method_name, *args, &block)
    if method_name =~ /^_/ && method_name =~ /rate/
      (send(method_name.to_s.sub(/^_/, '').to_sym, *args, &block) / 100.0).round(5)
    else
      super
    end
  end

end
