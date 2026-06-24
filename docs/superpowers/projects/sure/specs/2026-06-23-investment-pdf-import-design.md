# Investment PDF Import Feature Design

## Overview
A new feature to parse E*TRADE (and eventually other) brokerage account statements from PDF uploads. It will extract both trade activities (Buys/Sells) and cash flows (Dividends, Deposits) and map them to `Trade` and `Transaction` records. This ensures seamless integration with the Personal ROI and Net Cash Invested metrics.

## Architecture & Core Models

1. **`InvestmentPdfImport < Import`**
   * A dedicated ActiveRecord model for handling brokerage statement imports.
   * `has_one_attached :pdf_file`.
   * Will have its own `import!` implementation to handle the split between Trades and Cash Flows.

2. **`Provider::Gemini` (or `Provider::Claude`)**
   * Per requirements, we will **NOT** use OpenAI.
   * We will create a new AI provider class (`app/models/provider/gemini.rb`) that implements the `LlmConcept`.
   * It will include an `InvestmentStatementExtractor` to parse the PDF text chunks and return structured JSON.

## Data Flow & Extraction Schema

1. **Upload:** User uploads the E*TRADE PDF.
2. **AI Extraction:** 
   * The PDF text is extracted (using the existing `PDF::Reader` logic) and chunked.
   * It is sent to the Gemini/Claude API endpoint with strict JSON schema instructions.
   * The LLM extracts an array of `activities`:
     * *Trades:* `{ date, activity_type: "Buy"|"Sell", ticker, qty, price, total_amount }`
     * *Cash Flows:* `{ date, activity_type: "Dividend"|"Deposit"|"Withdrawal"|"Interest", name, total_amount }`
3. **Row Generation:** 
   * The structured JSON is saved into the staging table (`Import::Row`).
4. **Final Import (`import!`):**
   * Loop through the rows.
   * If `ticker` is present, resolve the `Security` and create a `Trade` record (which natively links to an `Entry`).
   * If `ticker` is blank, create a standard `Transaction` record for cash flows.

## Error Handling & Validation

*   **Missing Tickers:** If the AI extracts a trade but the ticker symbol cannot be resolved via our market data provider, the import will halt for that row and flag it for user review.
*   **Deduplication:** The extractor will implement chunk-overlap deduplication so that trades falling on the boundary of text chunks are not double-counted.
*   **Validation:** Math checks will be performed on trades (`qty * price ≈ total_amount`) to catch AI hallucinations.

## API Keys & Configuration
* A new environment variable (e.g., `GEMINI_API_KEY` or `ANTHROPIC_API_KEY`) will need to be added to `.env.local` to support the new provider.

---
*Status: Pending User Review*
