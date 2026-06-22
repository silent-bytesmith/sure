require "test_helper"

class XirrCalculatorTest < ActiveSupport::TestCase
  test "calculates correct annualized return for simple case" do
    cash_flows = [
      { amount: BigDecimal("-10000"), date: Date.new(2023, 1, 1) },
      { amount: BigDecimal("11000"), date: Date.new(2024, 1, 1) }
    ]
    # 10% return over 1 year
    assert_in_delta 0.10, XirrCalculator.calculate(cash_flows), 0.001
  end

  test "returns nil for empty or invalid cash flows" do
    assert_nil XirrCalculator.calculate([])
    assert_nil XirrCalculator.calculate([ { amount: BigDecimal("-100"), date: Date.today } ])
  end

  test "returns nil when no positive cash flow exists" do
    cash_flows = [
      { amount: BigDecimal("-10000"), date: Date.new(2023, 1, 1) },
      { amount: BigDecimal("-1000"), date: Date.new(2024, 1, 1) }
    ]
    assert_nil XirrCalculator.calculate(cash_flows)
  end

  test "calculates negative returns correctly" do
    cash_flows = [
      { amount: BigDecimal("-10000"), date: Date.new(2023, 1, 1) },
      { amount: BigDecimal("9000"), date: Date.new(2024, 1, 1) }
    ]
    # -10% return over 1 year
    assert_in_delta(-0.10, XirrCalculator.calculate(cash_flows), 0.001)
  end
end
