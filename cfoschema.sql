# SQL Code for the Comprehensive Finance Database

```sql
/* =====================================================
   Comprehensive Finance Database Schema
   ===================================================== */

/* -----------------------------------------------------
   1. ENTITIES – master reference table
   ----------------------------------------------------- */
CREATE TABLE entities (
    entity_id               BIGINT PRIMARY KEY AUTO_INCREMENT,
    entity_type             ENUM('Person','Company','Bank','Government','Investment_Fund','Other') NOT NULL,
    entity_name             VARCHAR(255) NOT NULL,
    entity_code             VARCHAR(50) UNIQUE,
    tax_identification_number VARCHAR(50),
    address_line1           VARCHAR(255),
    address_line2           VARCHAR(255),
    city                    VARCHAR(100),
    state                   VARCHAR(100),
    country                 VARCHAR(100),
    postal_code             VARCHAR(20),
    phone                   VARCHAR(20),
    email                   VARCHAR(255),
    website                 VARCHAR(255),
    is_active               BOOLEAN DEFAULT TRUE,
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by              VARCHAR(100),
    updated_by              VARCHAR(100),

    INDEX idx_entity_type (entity_type),
    INDEX idx_entity_name (entity_name),
    INDEX idx_tax_id (tax_identification_number),
    INDEX idx_active (is_active)
);

/* -----------------------------------------------------
   2. BANK_ACCOUNTS – cash & bank balances
   ----------------------------------------------------- */
CREATE TABLE bank_accounts (
    account_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
    entity_id       BIGINT NOT NULL,
    account_number  VARCHAR(50) NOT NULL,
    account_name    VARCHAR(255) NOT NULL,
    bank_name       VARCHAR(255) NOT NULL,
    bank_code       VARCHAR(20),                     -- SWIFT / IFSC / routing
    account_type    ENUM('Savings','Checking','Credit','Investment','Loan','Other') NOT NULL,
    currency_code   VARCHAR(3) DEFAULT 'USD',
    opening_balance DECIMAL(20,4) DEFAULT 0.0000,
    current_balance DECIMAL(20,4) DEFAULT 0.0000,
    opening_date    DATE,
    closing_date    DATE,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by      VARCHAR(100),
    updated_by      VARCHAR(100),

    FOREIGN KEY (entity_id) REFERENCES entities(entity_id),
    UNIQUE KEY  uk_entity_account (entity_id, account_number),
    INDEX idx_account_type (account_type),
    INDEX idx_bank_name (bank_name),
    INDEX idx_currency (currency_code),
    INDEX idx_active_accounts (is_active, entity_id)
);

/* -----------------------------------------------------
   3. HOLDINGS – investment portfolio
   ----------------------------------------------------- */
CREATE TABLE holdings (
    holding_id           BIGINT PRIMARY KEY AUTO_INCREMENT,
    entity_id            BIGINT NOT NULL,
    symbol               VARCHAR(20) NOT NULL,
    isin_code            VARCHAR(12),
    security_name        VARCHAR(255) NOT NULL,
    security_type        ENUM('Stock','Bond','MutualFund','ETF','Crypto','Commodity','Option','Future','Other') NOT NULL,
    exchange             VARCHAR(50),
    currency_code        VARCHAR(3)  DEFAULT 'USD',
    quantity             DECIMAL(18,8) NOT NULL DEFAULT 0.00000000,
    average_cost_price   DECIMAL(20,4) DEFAULT 0.0000,
    current_market_price DECIMAL(20,4) DEFAULT 0.0000,
    current_market_value DECIMAL(20,4) GENERATED ALWAYS AS (quantity * current_market_price) STORED,
    unrealized_gain_loss DECIMAL(20,4) GENERATED ALWAYS AS (current_market_value - (quantity * average_cost_price)) STORED,
    purchase_date        DATE,
    maturity_date        DATE,
    dividend_yield       DECIMAL(8,4),
    is_active            BOOLEAN DEFAULT TRUE,
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by           VARCHAR(100),
    updated_by           VARCHAR(100),

    FOREIGN KEY (entity_id) REFERENCES entities(entity_id),
    UNIQUE KEY uk_entity_symbol (entity_id, symbol, security_type),
    INDEX idx_security_type (security_type),
    INDEX idx_symbol (symbol),
    INDEX idx_exchange (exchange),
    INDEX idx_active_holdings (is_active, entity_id)
);

/* -----------------------------------------------------
   4. ASSETS_AND_LIABILITIES – non-investment items
   ----------------------------------------------------- */
CREATE TABLE assets_and_liabilities (
    asset_liability_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    entity_id          BIGINT NOT NULL,
    category           ENUM('Asset','Liability') NOT NULL,
    subcategory        VARCHAR(100) NOT NULL,                   -- Real Estate, Vehicle, etc.
    item_name          VARCHAR(255) NOT NULL,
    description        TEXT,
    original_value     DECIMAL(20,4) DEFAULT 0.0000,
    current_value      DECIMAL(20,4) DEFAULT 0.0000,
    depreciation_rate  DECIMAL(8,4),                           -- annual %
    purchase_date      DATE,
    estimated_life_years INT,
    currency_code      VARCHAR(3) DEFAULT 'USD',
    valuation_method   ENUM('Cost','Market','Appraisal','Depreciated') DEFAULT 'Cost',
    last_valuation_date DATE,
    is_active          BOOLEAN DEFAULT TRUE,
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by         VARCHAR(100),
    updated_by         VARCHAR(100),

    FOREIGN KEY (entity_id) REFERENCES entities(entity_id),
    INDEX idx_category (category),
    INDEX idx_subcategory (subcategory),
    INDEX idx_valuation_method (valuation_method),
    INDEX idx_active_assets (is_active, entity_id, category)
);

/* -----------------------------------------------------
   5. TRANSACTIONS – master ledger
   ----------------------------------------------------- */
CREATE TABLE transactions (
    transaction_id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    transaction_reference   VARCHAR(100) UNIQUE,
    transaction_date        DATE NOT NULL,
    value_date              DATE,
    entity_id               BIGINT NOT NULL,
    counterparty_entity_id  BIGINT,
    account_id              BIGINT,                               -- optional bank account
    transaction_category    ENUM('Purchase','Sale','Transfer','Dividend','Interest','Fee','Deposit','Withdrawal','Payment','Other') NOT NULL,
    transaction_type        ENUM('Income','Expense','Investment','Loan','Transfer','Tax','Other') NOT NULL,
    transaction_subcategory VARCHAR(100),
    amount                  DECIMAL(20,4) NOT NULL,
    currency_code           VARCHAR(3)  DEFAULT 'USD',
    exchange_rate           DECIMAL(12,6) DEFAULT 1.000000,
    amount_base_currency    DECIMAL(20,4) GENERATED ALWAYS AS (amount * exchange_rate) STORED,
    description             VARCHAR(500),
    notes                   TEXT,
    source_document_reference VARCHAR(200),
    reconciliation_status   ENUM('Unreconciled','Reconciled','Disputed') DEFAULT 'Unreconciled',
    is_reconciled           BOOLEAN DEFAULT FALSE,
    reconciled_date         DATE,
    tax_applicable          BOOLEAN DEFAULT FALSE,
    tax_amount              DECIMAL(20,4) DEFAULT 0.0000,
    net_amount              DECIMAL(20,4) GENERATED ALWAYS AS (amount - tax_amount) STORED,
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by              VARCHAR(100),
    updated_by              VARCHAR(100),

    FOREIGN KEY (entity_id)              REFERENCES entities(entity_id),
    FOREIGN KEY (counterparty_entity_id) REFERENCES entities(entity_id),
    FOREIGN KEY (account_id)             REFERENCES bank_accounts(account_id),
    INDEX idx_transaction_date (transaction_date),
    INDEX idx_entity_date (entity_id, transaction_date),
    INDEX idx_transaction_type (transaction_type),
    INDEX idx_transaction_category (transaction_category),
    INDEX idx_reconciliation (reconciliation_status),
    INDEX idx_amount (amount),
    INDEX idx_counterparty (counterparty_entity_id)
);

/* -----------------------------------------------------
   6. ASSET_TRANSACTIONS – investment trade details
   ----------------------------------------------------- */
CREATE TABLE asset_transactions (
    asset_transaction_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    transaction_id       BIGINT NOT NULL,
    holding_id           BIGINT,
    asset_liability_id   BIGINT,
    transaction_type     ENUM('Buy','Sell','Split','Bonus','Dividend','Rights','Merger','Spinoff','Other') NOT NULL,
    quantity             DECIMAL(18,8) NOT NULL DEFAULT 0.00000000,
    price_per_unit       DECIMAL(20,4) DEFAULT 0.0000,
    total_amount         DECIMAL(20,4) NOT NULL,
    fees_and_charges     DECIMAL(20,4) DEFAULT 0.0000,
    net_amount           DECIMAL(20,4) GENERATED ALWAYS AS (total_amount - fees_and_charges) STORED,
    realized_gain_loss   DECIMAL(20,4) DEFAULT 0.0000,
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (transaction_id)     REFERENCES transactions(transaction_id),
    FOREIGN KEY (holding_id)         REFERENCES holdings(holding_id),
    FOREIGN KEY (asset_liability_id) REFERENCES assets_and_liabilities(asset_liability_id),
    INDEX idx_transaction_type (transaction_type),
    INDEX idx_holding (holding_id),
    INDEX idx_asset_liability (asset_liability_id)
);

/* -----------------------------------------------------
   7. LIABILITIES – loans, mortgages, credit cards
   ----------------------------------------------------- */
CREATE TABLE liabilities (
    liability_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
    entity_id           BIGINT NOT NULL,
    liability_type      ENUM('Mortgage','PersonalLoan','CreditCard','AutoLoan','StudentLoan','BusinessLoan','Other') NOT NULL,
    liability_name      VARCHAR(255) NOT NULL,
    principal_amount    DECIMAL(20,4) NOT NULL,
    outstanding_balance DECIMAL(20,4) NOT NULL,
    interest_rate       DECIMAL(8,4),
    emi_amount          DECIMAL(20,4),
    start_date          DATE NOT NULL,
    maturity_date       DATE,
    payment_frequency   ENUM('Monthly','Quarterly','SemiAnnually','Annually','Other') DEFAULT 'Monthly',
    next_payment_date   DATE,
    lender_entity_id    BIGINT,
    currency_code       VARCHAR(3) DEFAULT 'USD',
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by          VARCHAR(100),
    updated_by          VARCHAR(100),

    FOREIGN KEY (entity_id)        REFERENCES entities(entity_id),
    FOREIGN KEY (lender_entity_id) REFERENCES entities(entity_id),
    INDEX idx_liability_type (liability_type),
    INDEX idx_maturity_date (maturity_date),
    INDEX idx_next_payment (next_payment_date),
    INDEX idx_active_liabilities (is_active, entity_id)
);

/* -----------------------------------------------------
   8. TAXES – multi-jurisdiction tax tracking
   ----------------------------------------------------- */
CREATE TABLE taxes (
    tax_id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    entity_id       BIGINT NOT NULL,
    tax_year        INT NOT NULL,
    tax_type        ENUM('IncomeTax','CapitalGainsTax','PropertyTax','SalesTax','CorporateTax','Other') NOT NULL,
    tax_category    VARCHAR(100),
    taxable_income  DECIMAL(20,4) DEFAULT 0.0000,
    tax_rate        DECIMAL(8,4),
    tax_amount      DECIMAL(20,4) NOT NULL DEFAULT 0.0000,
    tax_paid        DECIMAL(20,4) DEFAULT 0.0000,
    tax_due         DECIMAL(20,4) GENERATED ALWAYS AS (tax_amount - tax_paid) STORED,
    due_date        DATE,
    payment_status  ENUM('Pending','Paid','Overdue','Disputed') DEFAULT 'Pending',
    return_filed_date DATE,
    assessment_status ENUM('Not_Filed','Filed','Assessed','Disputed','Closed') DEFAULT 'Not_Filed',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by      VARCHAR(100),
    updated_by      VARCHAR(100),

    FOREIGN KEY (entity_id) REFERENCES entities(entity_id),
    UNIQUE KEY  uk_entity_year_type (entity_id, tax_year, tax_type),
    INDEX idx_tax_year (tax_year),
    INDEX idx_tax_type (tax_type),
    INDEX idx_payment_status (payment_status),
    INDEX idx_due_date (due_date)
);

/* -----------------------------------------------------
   9. NETWORTH – historical wealth snapshots
   ----------------------------------------------------- */
CREATE TABLE networth (
    networth_id            BIGINT PRIMARY KEY AUTO_INCREMENT,
    entity_id              BIGINT NOT NULL,
    calculation_date       DATE NOT NULL,
    total_assets           DECIMAL(20,4) NOT NULL DEFAULT 0.0000,
    total_liabilities      DECIMAL(20,4) NOT NULL DEFAULT 0.0000,
    net_worth              DECIMAL(20,4) GENERATED ALWAYS AS (total_assets - total_liabilities) STORED,
    currency_code          VARCHAR(3) DEFAULT 'USD',
    calculation_method     ENUM('Manual','Automatic','Hybrid') DEFAULT 'Automatic',
    includes_unrealized_gains BOOLEAN DEFAULT TRUE,
    notes                  TEXT,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by             VARCHAR(100),
    updated_by             VARCHAR(100),

    FOREIGN KEY (entity_id) REFERENCES entities(entity_id),
    UNIQUE KEY uk_entity_date (entity_id, calculation_date),
    INDEX idx_calculation_date (calculation_date),
    INDEX idx_net_worth (net_worth)
);

/* -----------------------------------------------------
   10. EXCHANGE_RATES – currency conversions
   ----------------------------------------------------- */
CREATE TABLE exchange_rates (
    rate_id       BIGINT PRIMARY KEY AUTO_INCREMENT,
    from_currency VARCHAR(3) NOT NULL,
    to_currency   VARCHAR(3) NOT NULL,
    exchange_rate DECIMAL(12,6) NOT NULL,
    rate_date     DATE NOT NULL,
    source        VARCHAR(100),
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uk_currencies_date (from_currency, to_currency, rate_date),
    INDEX idx_rate_date (rate_date),
    INDEX idx_currency_pair (from_currency, to_currency)
);

/* -----------------------------------------------------
   11. AUDIT_LOG – immutable change history
   ----------------------------------------------------- */
CREATE TABLE audit_log (
    audit_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
    table_name    VARCHAR(100) NOT NULL,
    record_id     BIGINT NOT NULL,
    action_type   ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    old_values    JSON,
    new_values    JSON,
    changed_by    VARCHAR(100) NOT NULL,
    change_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address    VARCHAR(45),
    user_agent    TEXT,
    session_id    VARCHAR(100),

    INDEX idx_table_record  (table_name, record_id),
    INDEX idx_action_type   (action_type),
    INDEX idx_changed_by    (changed_by),
    INDEX idx_timestamp     (change_timestamp)
);

/* -----------------------------------------------------
   12. DOCUMENT_ATTACHMENTS – file repository
   ----------------------------------------------------- */
CREATE TABLE document_attachments (
    attachment_id    BIGINT PRIMARY KEY AUTO_INCREMENT,
    reference_table  VARCHAR(100) NOT NULL,
    reference_id     BIGINT NOT NULL,
    document_type    ENUM('Invoice','Receipt','Statement','Contract','Photo','PDF','Other') NOT NULL,
    file_name        VARCHAR(255) NOT NULL,
    file_path        VARCHAR(500) NOT NULL,
    file_size        BIGINT,
    mime_type        VARCHAR(100),
    uploaded_date    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by       VARCHAR(100),

    INDEX idx_reference (reference_table, reference_id),
    INDEX idx_document_type (document_type),
    INDEX idx_uploaded_date (uploaded_date)
);

/* =====================================================
   VIEWS FOR REPORTING & ANALYSIS
   ===================================================== */

/* 1. Entity-level portfolio summary */
CREATE VIEW v_entity_portfolio_summary AS
SELECT
    e.entity_id,
    e.entity_name,
    COALESCE(SUM(CASE WHEN ba.is_active = TRUE THEN ba.current_balance           ELSE 0 END),0) AS total_cash,
    COALESCE(SUM(CASE WHEN h.is_active  = TRUE THEN h.current_market_value       ELSE 0 END),0) AS total_investments,
    COALESCE(SUM(CASE WHEN al.category  = 'Asset'    AND al.is_active = TRUE THEN al.current_value ELSE 0 END),0) AS total_other_assets,
    COALESCE(SUM(CASE WHEN al.category  = 'Liability'AND al.is_active = TRUE THEN al.current_value ELSE 0 END),0) AS total_other_liabilities,
    COALESCE(SUM(l.outstanding_balance),0) AS total_loans,
    (  COALESCE(SUM(CASE WHEN ba.is_active = TRUE THEN ba.current_balance ELSE 0 END),0)
     + COALESCE(SUM(CASE WHEN h.is_active  = TRUE THEN h.current_market_value ELSE 0 END),0)
     + COALESCE(SUM(CASE WHEN al.category  = 'Asset'    AND al.is_active = TRUE THEN al.current_value ELSE 0 END),0)
     - COALESCE(SUM(CASE WHEN al.category  = 'Liability'AND al.is_active = TRUE THEN al.current_value ELSE 0 END),0)
     - COALESCE(SUM(l.outstanding_balance),0)
    ) AS calculated_net_worth,
    CURRENT_DATE AS as_of_date
FROM entities e
LEFT JOIN bank_accounts         ba ON ba.entity_id = e.entity_id
LEFT JOIN holdings              h  ON h.entity_id  = e.entity_id
LEFT JOIN assets_and_liabilities al ON al.entity_id = e.entity_id
LEFT JOIN liabilities           l  ON l.entity_id  = e.entity_id AND l.is_active=TRUE
WHERE e.is_active = TRUE
GROUP BY e.entity_id,e.entity_name;

/* 2. Transaction summary (category x month) */
CREATE VIEW v_transaction_summary_by_category AS
SELECT
    t.entity_id,
    e.entity_name,
    t.transaction_category,
    t.transaction_subcategory,
    YEAR(t.transaction_date)  AS transaction_year,
    MONTH(t.transaction_date) AS transaction_month,
    COUNT(*)                  AS transaction_count,
    SUM(t.amount)             AS total_amount,
    AVG(t.amount)             AS average_amount,
    MIN(t.amount)             AS min_amount,
    MAX(t.amount)             AS max_amount
FROM transactions t
JOIN entities e ON e.entity_id = t.entity_id
GROUP BY t.entity_id,e.entity_name,t.transaction_category,t.transaction_subcategory,
         YEAR(t.transaction_date),MONTH(t.transaction_date);

/* 3. Holdings performance */
CREATE VIEW v_holdings_performance AS
SELECT
    h.holding_id,
    h.entity_id,
    e.entity_name,
    h.symbol,
    h.security_name,
    h.security_type,
    h.quantity,
    h.average_cost_price,
    h.current_market_price,
    h.current_market_value,
    h.unrealized_gain_loss,
    CASE WHEN h.average_cost_price>0
         THEN ((h.current_market_price-h.average_cost_price)/h.average_cost_price)*100
         ELSE 0 END                             AS percentage_gain_loss,
    (h.quantity*h.average_cost_price)            AS total_cost_basis,
    h.purchase_date,
    DATEDIFF(CURRENT_DATE,h.purchase_date)       AS days_held
FROM holdings h
JOIN entities e ON e.entity_id = h.entity_id
WHERE h.is_active=TRUE AND h.quantity>0;

/* 4. Monthly cash-flow */
CREATE VIEW v_monthly_cash_flow AS
SELECT
    t.entity_id,
    e.entity_name,
    YEAR(t.transaction_date)  AS year,
    MONTH(t.transaction_date) AS month,
    CONCAT(YEAR(t.transaction_date),'-',LPAD(MONTH(t.transaction_date),2,'0')) AS year_month,
    SUM(CASE WHEN t.transaction_category='Income'    THEN t.amount ELSE 0 END) AS total_income,
    SUM(CASE WHEN t.transaction_category='Expense'   THEN t.amount ELSE 0 END) AS total_expenses,
    SUM(CASE WHEN t.transaction_category='Investment'THEN t.amount ELSE 0 END) AS total_investments,
    SUM(CASE WHEN t.transaction_category='Income'    THEN t.amount ELSE 0 END)
  - SUM(CASE WHEN t.transaction_category='Expense'   THEN t.amount ELSE 0 END) AS net_cash_flow
FROM transactions t
JOIN entities e ON e.entity_id = t.entity_id
GROUP BY t.entity_id,e.entity_name,YEAR(t.transaction_date),MONTH(t.transaction_date)
ORDER BY t.entity_id,year,month;

/* 5. Tax summary */
CREATE VIEW v_tax_summary AS
SELECT
    tx.entity_id,
    e.entity_name,
    tx.tax_year,
    SUM(CASE WHEN tx.tax_type='IncomeTax'       THEN tx.tax_amount ELSE 0 END) AS income_tax,
    SUM(CASE WHEN tx.tax_type='CapitalGainsTax' THEN tx.tax_amount ELSE 0 END) AS capital_gains_tax,
    SUM(CASE WHEN tx.tax_type='PropertyTax'     THEN tx.tax_amount ELSE 0 END) AS property_tax,
    SUM(tx.tax_amount) AS total_tax_amount,
    SUM(tx.tax_paid)   AS total_tax_paid,
    SUM(tx.tax_due)    AS total_tax_due,
    COUNT(CASE WHEN tx.payment_status='Pending' THEN 1 END)  AS pending_payments,
    COUNT(CASE WHEN tx.payment_status='Overdue' THEN 1 END)  AS overdue_payments
FROM taxes tx
JOIN entities e ON e.entity_id = tx.entity_id
GROUP BY tx.entity_id,e.entity_name,tx.tax_year;

/* =====================================================
   STORED PROCEDURES
   ===================================================== */

DELIMITER //

/* 1. Calculate & store net worth */
CREATE PROCEDURE sp_calculate_networth (
    IN p_entity_id          BIGINT,
    IN p_calculation_date   DATE,
    IN p_include_unrealized BOOLEAN DEFAULT TRUE
)
BEGIN
    DECLARE v_assets   DECIMAL(20,4) DEFAULT 0;
    DECLARE v_liabs    DECIMAL(20,4) DEFAULT 0;

    /*  cash  */
    SELECT COALESCE(SUM(current_balance),0)
      INTO @cash
      FROM bank_accounts
     WHERE entity_id=p_entity_id AND is_active=TRUE;

    /*  investments  */
    SELECT COALESCE(SUM(current_market_value),0)
      INTO @invest
      FROM holdings
     WHERE entity_id=p_entity_id AND is_active=TRUE;

    /*  other assets  */
    SELECT COALESCE(SUM(current_value),0)
      INTO @o_assets
      FROM assets_and_liabilities
     WHERE entity_id=p_entity_id AND category='Asset' AND is_active=TRUE;

    /*  liabilities from A/L table  */
    SELECT COALESCE(SUM(current_value),0)
      INTO @o_liabs
      FROM assets_and_liabilities
     WHERE entity_id=p_entity_id AND category='Liability' AND is_active=TRUE;

    /*  loans  */
    SELECT COALESCE(SUM(outstanding_balance),0)
      INTO @loans
      FROM liabilities
     WHERE entity_id=p_entity_id AND is_active=TRUE;

    SET v_assets = @cash + @invest + @o_assets;
    SET v_liabs  = @o_liabs + @loans;

    INSERT INTO networth (
        entity_id, calculation_date, total_assets, total_liabilities,
        includes_unrealized_gains, calculation_method, created_by
    )
    VALUES (
        p_entity_id, p_calculation_date, v_assets, v_liabs,
        p_include_unrealized, 'Automatic', USER()
    )
    ON DUPLICATE KEY UPDATE
        total_assets            = v_assets,
        total_liabilities       = v_liabs,
        includes_unrealized_gains = p_include_unrealized,
        updated_at              = CURRENT_TIMESTAMP,
        updated_by              = USER();

    SELECT v_assets AS total_assets,
           v_liabs  AS total_liabilities,
           v_assets - v_liabs AS net_worth;
END //

/* 2. Update holding after trade */
CREATE PROCEDURE sp_update_holding_after_transaction (
    IN p_holding_id     BIGINT,
    IN p_transaction_type ENUM('Buy','Sell','Split','Bonus','Dividend','Rights','Merger','Spinoff','Other'),
    IN p_quantity       DECIMAL(18,8),
    IN p_price_per_unit DECIMAL(20,4)
)
BEGIN
    DECLARE v_qty DECIMAL(18,8);
    DECLARE v_avg DECIMAL(20,4);
    DECLARE v_new_qty DECIMAL(18,8);
    DECLARE v_new_avg DECIMAL(20,4);

    SELECT quantity,average_cost_price
      INTO v_qty,v_avg
      FROM holdings
     WHERE holding_id=p_holding_id;

    CASE p_transaction_type
        WHEN 'Buy' THEN
            SET v_new_qty = v_qty + p_quantity;
            IF v_new_qty>0 THEN
                SET v_new_avg = ((v_qty*v_avg)+(p_quantity*p_price_per_unit))/v_new_qty;
            END IF;
        WHEN 'Sell' THEN
            SET v_new_qty = v_qty - p_quantity;
            SET v_new_avg = v_avg;
        WHEN 'Split' THEN
            SET v_new_qty = v_qty * p_quantity;            -- p_quantity = split ratio
            SET v_new_avg = v_avg / p_quantity;
        WHEN 'Bonus' THEN
            SET v_new_qty = v_qty + p_quantity;
            SET v_new_avg = (v_qty*v_avg)/v_new_qty;
        ELSE
            SET v_new_qty = v_qty;
            SET v_new_avg = v_avg;
    END CASE;

    UPDATE holdings
       SET quantity           = v_new_qty,
           average_cost_price = v_new_avg,
           updated_at         = CURRENT_TIMESTAMP,
           updated_by         = USER()
     WHERE holding_id = p_holding_id;
END //

DELIMITER ;

/* =====================================================
   TRIGGERS – audit & integrity
   ===================================================== */

/* 1. ENTITIES audit */
DELIMITER //
CREATE TRIGGER tr_entities_audit_insert
AFTER INSERT ON entities
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name,record_id,action_type,new_values,changed_by)
    VALUES ('entities',NEW.entity_id,'INSERT',
            JSON_OBJECT('entity_type',NEW.entity_type,'entity_name',NEW.entity_name,
                        'entity_code',NEW.entity_code,'is_active',NEW.is_active),
            NEW.created_by);
END //

CREATE TRIGGER tr_entities_audit_update
AFTER UPDATE ON entities
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name,record_id,action_type,old_values,new_values,changed_by)
    VALUES ('entities',NEW.entity_id,'UPDATE',
            JSON_OBJECT('entity_type',OLD.entity_type,'entity_name',OLD.entity_name,
                        'entity_code',OLD.entity_code,'is_active',OLD.is_active),
            JSON_OBJECT('entity_type',NEW.entity_type,'entity_name',NEW.entity_name,
                        'entity_code',NEW.entity_code,'is_active',NEW.is_active),
            NEW.updated_by);
END //
DELIMITER ;

/* 2. TRANSACTIONS audit */
DELIMITER //
CREATE TRIGGER tr_transactions_audit_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name,record_id,action_type,new_values,changed_by)
    VALUES ('transactions',NEW.transaction_id,'INSERT',
            JSON_OBJECT('transaction_reference',NEW.transaction_reference,
                        'transaction_date',NEW.transaction_date,
                        'entity_id',NEW.entity_id,
                        'amount',NEW.amount,
                        'transaction_type',NEW.transaction_type),
            NEW.created_by);
END //
DELIMITER ;

/* 3. Auto-update bank balance */
DELIMITER //
CREATE TRIGGER tr_update_account_balance_after_transaction
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    IF NEW.account_id IS NOT NULL THEN
        UPDATE bank_accounts
           SET current_balance = current_balance +
               CASE
                   WHEN NEW.transaction_type IN ('Deposit','Interest','Dividend') THEN  NEW.amount
                   WHEN NEW.transaction_type IN ('Withdrawal','Fee','Payment')     THEN -NEW.amount
                   ELSE 0
               END,
               updated_at      = CURRENT_TIMESTAMP,
               updated_by      = NEW.created_by
         WHERE account_id = NEW.account_id;
    END IF;
END //
DELIMITER ;
```