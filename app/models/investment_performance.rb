class InvestmentPerformance
  attr_reader :family, :statement

  def initialize(family, period: Period.all_time)
    @family = family
    @period = period
    @statement = InvestmentStatement.new(family)
  end

  def net_cash_invested
    statement.totals(period: @period).net_flow
  end

  def reinvested_gains
    totals = statement.totals(period: @period)
    totals.dividends + totals.interest
  end

  def irr
    accounts = statement.investment_accounts
    return nil if accounts.empty?
    
    trades = family.trades.joins(:entry).where(entries: { account_id: accounts.map(&:id) })
    
    cash_flows = trades.map do |trade|
      entry = trade.entry
      # A Buy (qty > 0) has a negative entry amount (spending cash to get securities).
      # This is money entering the holdings portfolio, so it's a NEGATIVE cash flow for XIRR.
      # A Sell (qty < 0) has a positive entry amount (receiving cash from securities).
      # This is money leaving the holdings portfolio, so it's a POSITIVE cash flow for XIRR.
      amount_in_family_currency = statement.convert_to_family_currency(entry.amount_money, entry.account.currency)
      { amount: amount_in_family_currency, date: entry.date }
    end
    
    current_value = statement.holdings_value_money.amount
    return nil if current_value.zero? && cash_flows.empty?
    
    cash_flows << { amount: current_value, date: Date.current }
    
    XirrCalculator.calculate(cash_flows)
  end

  def twr
    nil # Placeholder for Benchmark Return (TWR)
  end
end
