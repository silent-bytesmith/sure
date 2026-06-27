# Investment PDF Import Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to upload E*TRADE brokerage statement PDFs to automatically extract trades and cash flows via Gemini API, linking perfectly to the Personal ROI feature.

**Architecture:** A new `InvestmentPdfImport` model handles the file upload lifecycle and mapping logic, while a newly implemented `Provider::Gemini` handles the AI extraction using Google's generative language API with JSON response constraints.

**Tech Stack:** Ruby on Rails, Minitest, Gemini API (via raw HTTP Faraday wrapper to avoid heavy dependencies).

## Global Constraints

- Do not use OpenAI endpoints; must use Gemini.
- Do not use `google/langextract`; use native `Provider::Gemini` integration.
- Ensure trades populate the `Trade` model with valid `qty`, `price`, and `ticker` so the ROI calculations work out-of-the-box.

---

### Task 1: Create Gemini Provider and Client Interface

**Files:**
- Create: `app/models/provider/gemini.rb`
- Create: `app/models/provider/gemini/client.rb`
- Test: `test/models/provider/gemini_test.rb`

**Interfaces:**
- Produces: `Provider::Gemini#extract_investment_statement(pdf_content:)`

- [ ] **Step 1: Write the failing test for the Provider**

```ruby
# test/models/provider/gemini_test.rb
require "test_helper"

class Provider::GeminiTest < ActiveSupport::TestCase
  test "it is registered as an LLM concept" do
    assert Provider::Registry.get_provider(:gemini).is_a?(Provider::Gemini)
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `sg docker -c "docker compose exec -T web bin/rails test test/models/provider/gemini_test.rb"`
Expected: FAIL with uninitialized constant Provider::Gemini

- [ ] **Step 3: Write minimal implementation**

```ruby
# app/models/provider/gemini.rb
class Provider::Gemini
  include Provider::LlmConcept

  def supports_pdf_processing?
    true
  end
  
  def extract_investment_statement(pdf_content:, family: nil)
    client = Provider::Gemini::Client.new
    extractor = Provider::Gemini::InvestmentStatementExtractor.new(client: client, pdf_content: pdf_content)
    
    begin
      data = extractor.extract
      Provider::Response.new(success: true, data: data)
    rescue => e
      Provider::Response.new(success: false, error: Provider::Error.new(message: e.message))
    end
  end
end
```

```ruby
# app/models/provider/gemini/client.rb
class Provider::Gemini::Client
  def initialize(api_key: ENV.fetch("GEMINI_API_KEY", ""))
    @api_key = api_key
  end
  
  def generate_content(prompt)
    # Placeholder for actual faraday HTTP request to Gemini API
    # Should handle returning JSON parsed output
    raise NotImplementedError
  end
end
```

Register the provider in `app/models/provider/registry.rb` by adding `gemini` if necessary, or let autoload handle it. (Verify how existing providers are registered).

- [ ] **Step 4: Commit**
```bash
git add app/models/provider/gemini.rb app/models/provider/gemini/client.rb test/models/provider/gemini_test.rb
git commit -m "feat: add base Gemini provider"
```

---

### Task 2: Build the Investment Statement Extractor

**Files:**
- Create: `app/models/provider/gemini/investment_statement_extractor.rb`
- Test: `test/models/provider/gemini/investment_statement_extractor_test.rb`

**Interfaces:**
- Consumes: `Provider::Gemini::Client`
- Produces: Hash containing `{ transactions: [ { date, type, ticker, qty, price, amount, name } ] }`

- [ ] **Step 1: Write the extractor logic**

```ruby
# app/models/provider/gemini/investment_statement_extractor.rb
class Provider::Gemini::InvestmentStatementExtractor
  attr_reader :client, :pdf_content

  def initialize(client:, pdf_content:)
    @client = client
    @pdf_content = pdf_content
  end

  def extract
    pages = extract_pages_from_pdf
    # Chunking logic similar to BankStatementExtractor
    # Call client.generate_content with JSON instruction
    # Normalize result
  end
  
  private
  def extract_pages_from_pdf
    reader = PDF::Reader.new(StringIO.new(pdf_content))
    reader.pages.map(&:text).reject(&:blank?)
  end
end
```
*Note: Include a strict JSON prompt asking for `date`, `activity_type`, `ticker`, `qty`, `price`, `amount`, and `name`.*

- [ ] **Step 2: Commit**
```bash
git add app/models/provider/gemini/investment_statement_extractor.rb
git commit -m "feat: add Gemini PDF extractor for investment statements"
```

---

### Task 3: Build InvestmentPdfImport Model

**Files:**
- Create: `app/models/investment_pdf_import.rb`
- Test: `test/models/investment_pdf_import_test.rb`

**Interfaces:**
- Consumes: `Provider::Gemini#extract_investment_statement`
- Produces: `Import::Row` objects, then `Trade` and `Transaction` records

- [ ] **Step 1: Write InvestmentPdfImport logic**

```ruby
# app/models/investment_pdf_import.rb
class InvestmentPdfImport < Import
  has_one_attached :pdf_file, dependent: :purge_later

  def extract_transactions
    provider = Provider::Registry.get_provider(:gemini)
    response = provider.extract_investment_statement(pdf_content: pdf_file.download)
    update!(extracted_data: response.data)
  end

  def generate_rows_from_extracted_data
    # Map extracted JSON to Import::Row records
  end

  def import!
    transaction do
      # For each row, if ticker present -> find_or_create_security -> Trade.new
      # If no ticker -> Transaction.new
      # Handle Trade qty negative for Sells, positive for Buys
    end
  end
end
```

- [ ] **Step 2: Add it to DOCUMENT_TYPES**
Ensure `"investment_statement"` is valid in `Import::TYPES` if needed, and update `app/controllers/imports_controller.rb` so the UI can create `InvestmentPdfImport` records.

- [ ] **Step 3: Commit**
```bash
git add app/models/investment_pdf_import.rb
git commit -m "feat: add InvestmentPdfImport model"
```
