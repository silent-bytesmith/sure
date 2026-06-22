class XirrCalculator
  MAX_ITERATIONS = 100
  TOLERANCE = 0.00001

  def self.calculate(cash_flows, guess = 0.1)
    return nil if cash_flows.nil? || cash_flows.size < 2
    
    # Sort by date
    sorted_flows = cash_flows.sort_by { |cf| cf[:date] }
    min_date = sorted_flows.first[:date]
    
    # Must have at least one positive and one negative cash flow
    amounts = sorted_flows.map { |cf| cf[:amount] }
    return nil unless amounts.any?(&:positive?) && amounts.any?(&:negative?)

    rate = guess.to_f
    
    MAX_ITERATIONS.times do
      npv = 0.0
      npv_prime = 0.0
      
      sorted_flows.each do |cf|
        years = (cf[:date] - min_date).to_f / 365.0
        amount = cf[:amount].to_f
        
        npv += amount / ((1.0 + rate) ** years)
        if years > 0
          npv_prime -= (years * amount) / ((1.0 + rate) ** (years + 1.0))
        end
      end
      
      return rate if npv.abs < TOLERANCE
      return nil if npv_prime == 0.0
      
      rate = rate - (npv / npv_prime)
    end
    
    nil # Failed to converge
  end
end
