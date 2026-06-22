require "test_helper"

class InvestmentPerformanceTest < ActiveSupport::TestCase
  setup do
    @family = families(:empty)
    @account = @family.accounts.create!(
      name: "Brokerage", 
      balance: 11000, 
      currency: "USD", 
      accountable: Investment.new
    )
    # create a deposit
    Entry.create!(
      account: @account, 
      amount: 10000, 
      date: 1.year.ago.to_date, 
      name: "Deposit", 
      currency: "USD"
    )
  end

  test "calculates net cash invested and irr" do
    perf = InvestmentPerformance.new(@family)
    assert_equal Money.new(10000, "USD"), perf.net_cash_invested
    
    # Approx 10% return
    assert_in_delta 0.10, perf.irr, 0.01
  end

  test "reinvested gains handles dividends and interest" do
    perf = InvestmentPerformance.new(@family)
    assert_equal Money.new(0, "USD"), perf.reinvested_gains
  end
end
