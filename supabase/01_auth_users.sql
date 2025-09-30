-- =============================================
-- Authentication & User Management
-- =============================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- OTP verification table
CREATE TABLE otp_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone_number VARCHAR(20),
    email VARCHAR(100),
    code VARCHAR(6) NOT NULL,
    type SMALLINT NOT NULL DEFAULT 1, -- 1: registration, 2: login, 3: forgot_password
    is_verified BOOLEAN DEFAULT FALSE,
    attempts INTEGER DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User metadata table (extends auth.users)
CREATE TABLE user_metadata (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone_number VARCHAR(20) UNIQUE,
    is_phone_verified BOOLEAN DEFAULT FALSE,
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_profile_complete BOOLEAN DEFAULT FALSE,
    is_banned BOOLEAN DEFAULT FALSE,
    ban_reason TEXT,
    banned_until TIMESTAMP WITH TIME ZONE,
    last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User login logs
CREATE TABLE user_login_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ip_address INET,
    user_agent TEXT,
    device_info JSONB,
    login_method VARCHAR(20), -- phone, email
    success BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_otp_phone ON otp_verifications(phone_number);
CREATE INDEX idx_otp_email ON otp_verifications(email);
CREATE INDEX idx_otp_expires ON otp_verifications(expires_at);
CREATE INDEX idx_user_metadata_phone ON user_metadata(phone_number);
CREATE INDEX idx_user_login_logs_user ON user_login_logs(user_id);

-- Triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_metadata_updated_at 
    BEFORE UPDATE ON user_metadata 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to create user metadata on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_metadata (id, phone_number, is_email_verified)
    VALUES (
        NEW.id,
        NEW.phone,
        CASE WHEN NEW.email_confirmed_at IS NOT NULL THEN TRUE ELSE FALSE END
    );
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();