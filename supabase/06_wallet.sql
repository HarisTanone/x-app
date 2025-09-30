-- =============================================
-- Wallet & Payment System
-- =============================================

-- User wallets
CREATE TABLE wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
    balance BIGINT DEFAULT 0, -- in cents
    total_topup BIGINT DEFAULT 0, -- lifetime top-up amount
    total_spent BIGINT DEFAULT 0, -- lifetime spending
    total_earned BIGINT DEFAULT 0, -- for creators
    is_frozen BOOLEAN DEFAULT FALSE,
    frozen_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Wallet transactions
CREATE TABLE wallet_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id UUID REFERENCES wallets(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    transaction_type SMALLINT NOT NULL, -- 1: topup, 2: purchase, 3: earning, 4: withdrawal, 5: refund
    amount BIGINT NOT NULL, -- in cents, positive for credit, negative for debit
    balance_before BIGINT NOT NULL,
    balance_after BIGINT NOT NULL,
    description TEXT,
    reference_type VARCHAR(20), -- album_purchase, profile_boost, withdrawal, etc.
    reference_id UUID,
    payment_method VARCHAR(20), -- bank_transfer, gopay, ovo, dana, shopee_pay, qris
    external_transaction_id VARCHAR(100),
    status SMALLINT DEFAULT 1, -- 1: pending, 2: completed, 3: failed, 4: cancelled
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Top-up requests
CREATE TABLE topup_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    amount BIGINT NOT NULL, -- in cents
    payment_method VARCHAR(20) NOT NULL,
    payment_provider VARCHAR(20), -- midtrans, xendit
    external_id VARCHAR(100),
    payment_url TEXT,
    qr_code_url TEXT,
    virtual_account VARCHAR(50),
    status SMALLINT DEFAULT 1, -- 1: pending, 2: paid, 3: expired, 4: cancelled
    expires_at TIMESTAMP WITH TIME ZONE,
    paid_at TIMESTAMP WITH TIME ZONE,
    webhook_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Withdrawal requests (for creators)
CREATE TABLE withdrawal_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    amount BIGINT NOT NULL, -- in cents
    fee BIGINT NOT NULL, -- 5% fee in cents
    net_amount BIGINT NOT NULL, -- amount - fee
    bank_name VARCHAR(50) NOT NULL,
    account_number VARCHAR(30) NOT NULL,
    account_name VARCHAR(100) NOT NULL,
    status SMALLINT DEFAULT 1, -- 1: pending, 2: approved, 3: processed, 4: completed, 5: rejected
    admin_notes TEXT,
    processed_by UUID,
    processed_at TIMESTAMP WITH TIME ZONE,
    disbursement_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Payment methods configuration
CREATE TABLE payment_methods (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(50) NOT NULL,
    type VARCHAR(20) NOT NULL, -- bank_transfer, ewallet, qris
    provider VARCHAR(20) NOT NULL, -- midtrans, xendit
    is_active BOOLEAN DEFAULT TRUE,
    min_amount BIGINT DEFAULT 1000000, -- Rp 10,000 in cents
    max_amount BIGINT DEFAULT 500000000, -- Rp 5,000,000 in cents
    fee_percentage DECIMAL(5,4) DEFAULT 0,
    fee_fixed BIGINT DEFAULT 0,
    icon_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default payment methods
INSERT INTO payment_methods (code, name, type, provider, min_amount, max_amount) VALUES 
('bank_transfer', 'Transfer Bank', 'bank_transfer', 'midtrans', 1000000, 500000000),
('gopay', 'GoPay', 'ewallet', 'midtrans', 1000000, 200000000),
('ovo', 'OVO', 'ewallet', 'midtrans', 1000000, 200000000),
('dana', 'DANA', 'ewallet', 'midtrans', 1000000, 200000000),
('shopeepay', 'ShopeePay', 'ewallet', 'midtrans', 1000000, 200000000),
('qris', 'QRIS', 'qris', 'midtrans', 1000000, 200000000);

-- Indexes
CREATE INDEX idx_wallets_user ON wallets(user_id);
CREATE INDEX idx_wallet_transactions_wallet ON wallet_transactions(wallet_id);
CREATE INDEX idx_wallet_transactions_user ON wallet_transactions(user_id);
CREATE INDEX idx_wallet_transactions_type ON wallet_transactions(transaction_type);
CREATE INDEX idx_wallet_transactions_status ON wallet_transactions(status);
CREATE INDEX idx_topup_requests_user ON topup_requests(user_id);
CREATE INDEX idx_topup_requests_status ON topup_requests(status);
CREATE INDEX idx_withdrawal_requests_user ON withdrawal_requests(user_id);
CREATE INDEX idx_withdrawal_requests_status ON withdrawal_requests(status);

-- Triggers
CREATE TRIGGER update_wallets_updated_at 
    BEFORE UPDATE ON wallets 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wallet_transactions_updated_at 
    BEFORE UPDATE ON wallet_transactions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_topup_requests_updated_at 
    BEFORE UPDATE ON topup_requests 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_withdrawal_requests_updated_at 
    BEFORE UPDATE ON withdrawal_requests 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to create wallet on profile creation
CREATE OR REPLACE FUNCTION create_user_wallet()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO wallets (user_id) VALUES (NEW.id);
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER create_user_wallet_trigger
    AFTER INSERT ON profiles
    FOR EACH ROW EXECUTE FUNCTION create_user_wallet();

-- Function to update wallet balance
CREATE OR REPLACE FUNCTION update_wallet_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- Update wallet balance and stats
    UPDATE wallets 
    SET 
        balance = NEW.balance_after,
        total_topup = CASE 
            WHEN NEW.transaction_type = 1 AND NEW.amount > 0 THEN total_topup + NEW.amount 
            ELSE total_topup 
        END,
        total_spent = CASE 
            WHEN NEW.transaction_type = 2 AND NEW.amount < 0 THEN total_spent + ABS(NEW.amount)
            ELSE total_spent 
        END,
        total_earned = CASE 
            WHEN NEW.transaction_type = 3 AND NEW.amount > 0 THEN total_earned + NEW.amount
            ELSE total_earned 
        END,
        updated_at = NOW()
    WHERE id = NEW.wallet_id;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_wallet_balance_trigger
    AFTER INSERT ON wallet_transactions
    FOR EACH ROW EXECUTE FUNCTION update_wallet_balance();

-- Function to process wallet transaction
CREATE OR REPLACE FUNCTION process_wallet_transaction(
    p_user_id UUID,
    p_transaction_type SMALLINT,
    p_amount BIGINT,
    p_description TEXT,
    p_reference_type VARCHAR(20) DEFAULT NULL,
    p_reference_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_wallet_id UUID;
    v_current_balance BIGINT;
    v_new_balance BIGINT;
    v_transaction_id UUID;
BEGIN
    -- Get wallet info
    SELECT id, balance INTO v_wallet_id, v_current_balance
    FROM wallets WHERE user_id = p_user_id;
    
    IF v_wallet_id IS NULL THEN
        RAISE EXCEPTION 'Wallet not found for user %', p_user_id;
    END IF;
    
    -- Calculate new balance
    v_new_balance := v_current_balance + p_amount;
    
    -- Check for sufficient balance on debit transactions
    IF p_amount < 0 AND v_new_balance < 0 THEN
        RAISE EXCEPTION 'Insufficient balance. Current: %, Required: %', v_current_balance, ABS(p_amount);
    END IF;
    
    -- Create transaction record
    INSERT INTO wallet_transactions (
        wallet_id, user_id, transaction_type, amount, 
        balance_before, balance_after, description,
        reference_type, reference_id, status
    ) VALUES (
        v_wallet_id, p_user_id, p_transaction_type, p_amount,
        v_current_balance, v_new_balance, p_description,
        p_reference_type, p_reference_id, 2 -- completed
    ) RETURNING id INTO v_transaction_id;
    
    RETURN v_transaction_id;
END;
$$ language 'plpgsql';

-- Function to get wallet balance
CREATE OR REPLACE FUNCTION get_wallet_balance(p_user_id UUID)
RETURNS BIGINT AS $$
DECLARE
    v_balance BIGINT;
BEGIN
    SELECT balance INTO v_balance FROM wallets WHERE user_id = p_user_id;
    RETURN COALESCE(v_balance, 0);
END;
$$ language 'plpgsql';

-- Function to get transaction history
CREATE OR REPLACE FUNCTION get_transaction_history(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    transaction_id UUID,
    transaction_type SMALLINT,
    amount BIGINT,
    balance_after BIGINT,
    description TEXT,
    reference_type VARCHAR(20),
    status SMALLINT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        wt.id,
        wt.transaction_type,
        wt.amount,
        wt.balance_after,
        wt.description,
        wt.reference_type,
        wt.status,
        wt.created_at
    FROM wallet_transactions wt
    WHERE wt.user_id = p_user_id
    ORDER BY wt.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ language 'plpgsql';