-- =============================================
-- Admin & Moderation System
-- =============================================

-- Admin users
CREATE TABLE admin_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL, -- super_admin, admin, moderator
    permissions JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Content moderation queue
CREATE TABLE moderation_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_type VARCHAR(20) NOT NULL, -- profile, photo, album, message
    content_id UUID NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    reason VARCHAR(50) NOT NULL, -- ai_flagged, user_reported, manual_review
    priority SMALLINT DEFAULT 1, -- 1: low, 2: medium, 3: high, 4: urgent
    status SMALLINT DEFAULT 1, -- 1: pending, 2: approved, 3: rejected, 4: escalated
    ai_confidence DECIMAL(3,2), -- AI confidence score 0.00-1.00
    ai_flags JSONB, -- AI detected issues
    moderator_id UUID REFERENCES admin_users(id),
    moderator_notes TEXT,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User verification requests
CREATE TABLE verification_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    verification_photo_url TEXT NOT NULL,
    status SMALLINT DEFAULT 1, -- 1: pending, 2: approved, 3: rejected
    rejection_reason TEXT,
    reviewed_by UUID REFERENCES admin_users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- System notifications
CREATE TABLE system_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(20) NOT NULL, -- info, warning, maintenance, update
    target_audience VARCHAR(20) DEFAULT 'all', -- all, premium, creators, specific_users
    target_user_ids UUID[],
    is_active BOOLEAN DEFAULT TRUE,
    starts_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ends_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES admin_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Analytics events
CREATE TABLE analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB,
    session_id VARCHAR(100),
    ip_address INET,
    user_agent TEXT,
    platform VARCHAR(20), -- ios, android, web
    app_version VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Daily analytics summary
CREATE TABLE daily_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL UNIQUE,
    total_users BIGINT DEFAULT 0,
    new_users BIGINT DEFAULT 0,
    active_users BIGINT DEFAULT 0,
    total_matches BIGINT DEFAULT 0,
    total_messages BIGINT DEFAULT 0,
    total_swipes BIGINT DEFAULT 0,
    total_albums BIGINT DEFAULT 0,
    total_purchases BIGINT DEFAULT 0,
    total_revenue BIGINT DEFAULT 0, -- in cents
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_admin_users_role ON admin_users(role);
CREATE INDEX idx_moderation_queue_status ON moderation_queue(status);
CREATE INDEX idx_moderation_queue_priority ON moderation_queue(priority);
CREATE INDEX idx_moderation_queue_content ON moderation_queue(content_type, content_id);
CREATE INDEX idx_verification_requests_status ON verification_requests(status);
CREATE INDEX idx_system_notifications_active ON system_notifications(is_active);
CREATE INDEX idx_analytics_events_type ON analytics_events(event_type);
CREATE INDEX idx_analytics_events_date ON analytics_events(created_at);
CREATE INDEX idx_daily_analytics_date ON daily_analytics(date);

-- Triggers
CREATE TRIGGER update_admin_users_updated_at 
    BEFORE UPDATE ON admin_users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to generate daily analytics
CREATE OR REPLACE FUNCTION generate_daily_analytics(p_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 day')
RETURNS VOID AS $$
DECLARE
    v_total_users BIGINT;
    v_new_users BIGINT;
    v_active_users BIGINT;
    v_total_matches BIGINT;
    v_total_messages BIGINT;
    v_total_swipes BIGINT;
    v_total_albums BIGINT;
    v_total_purchases BIGINT;
    v_total_revenue BIGINT;
BEGIN
    -- Total users
    SELECT COUNT(*) INTO v_total_users FROM profiles WHERE DATE(created_at) <= p_date;
    
    -- New users
    SELECT COUNT(*) INTO v_new_users FROM profiles WHERE DATE(created_at) = p_date;
    
    -- Active users (users who swiped, messaged, or purchased on that day)
    SELECT COUNT(DISTINCT user_id) INTO v_active_users
    FROM (
        SELECT swiper_id as user_id FROM swipes WHERE DATE(created_at) = p_date
        UNION
        SELECT sender_id as user_id FROM messages WHERE DATE(created_at) = p_date
        UNION
        SELECT buyer_id as user_id FROM album_purchases WHERE DATE(purchased_at) = p_date
    ) active;
    
    -- Total matches created on that day
    SELECT COUNT(*) INTO v_total_matches FROM matches WHERE DATE(matched_at) = p_date;
    
    -- Total messages sent on that day
    SELECT COUNT(*) INTO v_total_messages FROM messages WHERE DATE(created_at) = p_date;
    
    -- Total swipes on that day
    SELECT COUNT(*) INTO v_total_swipes FROM swipes WHERE DATE(created_at) = p_date;
    
    -- Total albums created on that day
    SELECT COUNT(*) INTO v_total_albums FROM albums WHERE DATE(created_at) = p_date;
    
    -- Total purchases on that day
    SELECT COUNT(*) INTO v_total_purchases FROM album_purchases WHERE DATE(purchased_at) = p_date;
    
    -- Total revenue on that day
    SELECT COALESCE(SUM(price_paid), 0) INTO v_total_revenue 
    FROM album_purchases WHERE DATE(purchased_at) = p_date;
    
    -- Insert or update daily analytics
    INSERT INTO daily_analytics (
        date, total_users, new_users, active_users, total_matches,
        total_messages, total_swipes, total_albums, total_purchases, total_revenue
    ) VALUES (
        p_date, v_total_users, v_new_users, v_active_users, v_total_matches,
        v_total_messages, v_total_swipes, v_total_albums, v_total_purchases, v_total_revenue
    )
    ON CONFLICT (date) DO UPDATE SET
        total_users = EXCLUDED.total_users,
        new_users = EXCLUDED.new_users,
        active_users = EXCLUDED.active_users,
        total_matches = EXCLUDED.total_matches,
        total_messages = EXCLUDED.total_messages,
        total_swipes = EXCLUDED.total_swipes,
        total_albums = EXCLUDED.total_albums,
        total_purchases = EXCLUDED.total_purchases,
        total_revenue = EXCLUDED.total_revenue;
END;
$$ language 'plpgsql';

-- Function to get admin dashboard stats
CREATE OR REPLACE FUNCTION get_admin_dashboard_stats()
RETURNS TABLE (
    total_users BIGINT,
    active_users_today BIGINT,
    new_users_today BIGINT,
    total_matches BIGINT,
    total_messages BIGINT,
    total_albums BIGINT,
    total_revenue BIGINT,
    pending_reports BIGINT,
    pending_verifications BIGINT,
    pending_withdrawals BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM profiles)::BIGINT,
        (SELECT COUNT(DISTINCT user_id) FROM (
            SELECT swiper_id as user_id FROM swipes WHERE DATE(created_at) = CURRENT_DATE
            UNION
            SELECT sender_id as user_id FROM messages WHERE DATE(created_at) = CURRENT_DATE
        ) active)::BIGINT,
        (SELECT COUNT(*) FROM profiles WHERE DATE(created_at) = CURRENT_DATE)::BIGINT,
        (SELECT COUNT(*) FROM matches)::BIGINT,
        (SELECT COUNT(*) FROM messages)::BIGINT,
        (SELECT COUNT(*) FROM albums)::BIGINT,
        (SELECT COALESCE(SUM(total_revenue), 0) FROM albums)::BIGINT,
        (SELECT COUNT(*) FROM user_reports WHERE status = 1)::BIGINT,
        (SELECT COUNT(*) FROM verification_requests WHERE status = 1)::BIGINT,
        (SELECT COUNT(*) FROM withdrawal_requests WHERE status IN (1, 2))::BIGINT;
END;
$$ language 'plpgsql';

-- Function to track analytics event
CREATE OR REPLACE FUNCTION track_analytics_event(
    p_user_id UUID,
    p_event_type VARCHAR(50),
    p_event_data JSONB DEFAULT NULL,
    p_session_id VARCHAR(100) DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_platform VARCHAR(20) DEFAULT NULL,
    p_app_version VARCHAR(20) DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_event_id UUID;
BEGIN
    INSERT INTO analytics_events (
        user_id, event_type, event_data, session_id,
        ip_address, user_agent, platform, app_version
    ) VALUES (
        p_user_id, p_event_type, p_event_data, p_session_id,
        p_ip_address, p_user_agent, p_platform, p_app_version
    ) RETURNING id INTO v_event_id;
    
    RETURN v_event_id;
END;
$$ language 'plpgsql';

-- Function to get user activity summary
CREATE OR REPLACE FUNCTION get_user_activity_summary(p_user_id UUID)
RETURNS TABLE (
    total_swipes BIGINT,
    total_matches BIGINT,
    total_messages BIGINT,
    albums_created BIGINT,
    albums_purchased BIGINT,
    total_spent BIGINT,
    total_earned BIGINT,
    last_active TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM swipes WHERE swiper_id = p_user_id)::BIGINT,
        (SELECT COUNT(*) FROM matches WHERE user1_id = p_user_id OR user2_id = p_user_id)::BIGINT,
        (SELECT COUNT(*) FROM messages WHERE sender_id = p_user_id)::BIGINT,
        (SELECT COUNT(*) FROM albums WHERE creator_id = p_user_id)::BIGINT,
        (SELECT COUNT(*) FROM album_purchases WHERE buyer_id = p_user_id)::BIGINT,
        (SELECT COALESCE(total_spent, 0) FROM wallets WHERE user_id = p_user_id)::BIGINT,
        (SELECT COALESCE(total_earned, 0) FROM wallets WHERE user_id = p_user_id)::BIGINT,
        (SELECT last_active FROM user_metadata WHERE id = p_user_id);
END;
$$ language 'plpgsql';