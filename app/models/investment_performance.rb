class InvestmentPerformance
  attr_reader :family, :statement

  def initialize(family, period: Period.all_time)
    @family = family
    @statement = InvestmentStatement.new(family, period: period)
  end

  def net_cash_invested
    statement.totals.net_flow
  end

  def reinvested_gains
    totals = statement.totals
    totals.dividends + totals.interest
  end

  def irr
    accounts = statement.investment_accounts
    return nil if accounts.empty?
    
    entries = Entry.where(account: accounts).where.not(amount: 0)
    
    cash_flows = entries.map do |entry|
      # Deposits into the investment account are positive entry amounts.
      # From the portfolio's perspective, this is money added (out of pocket).
      # For XIRR, investments (deposits) are negative, returns (withdrawals/final value) are positive.
      amount_in_family_currency = entry.amount_money.exchange_to(family.currency)
      { amount: -amount_in_family_currency.amount, date: entry.date }
    end
    
    current_value = statement.portfolio_value_money.amount
    return nil if current_value.zero? && cash_flows.empty?
    
    cash_flows << { amount: current_value, date: Date.current }
    
    XirrCalculator.calculate(cash_flows)
  end

  def twr
    nil # Placeholder for Benchmark Return (TWR)
  end
end
