-- =============================================
-- Row Level Security (RLS) Policies
-- =============================================

-- Enable RLS on all tables
ALTER TABLE user_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE swipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE albums ENABLE ROW LEVEL SECURITY;
ALTER TABLE album_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE album_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocked_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_reports ENABLE ROW LEVEL SECURITY;

-- User Metadata Policies
CREATE POLICY "Users can view own metadata" ON user_metadata
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own metadata" ON user_metadata
    FOR UPDATE USING (auth.uid() = id);

-- Profile Policies
CREATE POLICY "Users can view profiles" ON profiles
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND (
            auth.uid() = id OR
            id NOT IN (
                SELECT blocked_id FROM blocked_users WHERE blocker_id = auth.uid()
                UNION
                SELECT blocker_id FROM blocked_users WHERE blocked_id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Profile Photos Policies
CREATE POLICY "Users can view profile photos" ON profile_photos
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND (
            auth.uid() = user_id OR
            user_id NOT IN (
                SELECT blocked_id FROM blocked_users WHERE blocker_id = auth.uid()
                UNION
                SELECT blocker_id FROM blocked_users WHERE blocked_id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can manage own photos" ON profile_photos
    FOR ALL USING (auth.uid() = user_id);

-- User Interests Policies
CREATE POLICY "Users can view interests" ON user_interests
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND (
            auth.uid() = user_id OR
            user_id NOT IN (
                SELECT blocked_id FROM blocked_users WHERE blocker_id = auth.uid()
                UNION
                SELECT blocker_id FROM blocked_users WHERE blocked_id = auth.uid()
            )
        )
    );

CREATE POLICY "Users can manage own interests" ON user_interests
    FOR ALL USING (auth.uid() = user_id);

-- User Preferences Policies
CREATE POLICY "Users can manage own preferences" ON user_preferences
    FOR ALL USING (auth.uid() = user_id);

-- Swipes Policies
CREATE POLICY "Users can view own swipes" ON swipes
    FOR SELECT USING (auth.uid() = swiper_id);

CREATE POLICY "Users can create swipes" ON swipes
    FOR INSERT WITH CHECK (
        auth.uid() = swiper_id AND
        swiper_id != swiped_id AND
        swiped_id NOT IN (
            SELECT blocked_id FROM blocked_users WHERE blocker_id = auth.uid()
            UNION
            SELECT blocker_id FROM blocked_users WHERE blocked_id = auth.uid()
        )
    );

-- Matches Policies
CREATE POLICY "Users can view own matches" ON matches
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND (
            auth.uid() = user1_id OR auth.uid() = user2_id
        )
    );

-- Messages Policies (already enabled above)
CREATE POLICY "Users can view messages in their matches" ON messages
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND
        match_id IN (
            SELECT id FROM matches 
            WHERE user1_id = auth.uid() OR user2_id = auth.uid()
        )
    );

CREATE POLICY "Users can send messages in their matches" ON messages
    FOR INSERT WITH CHECK (
        auth.uid() = sender_id AND
        match_id IN (
            SELECT id FROM matches 
            WHERE user1_id = auth.uid() OR user2_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own messages" ON messages
    FOR UPDATE USING (auth.uid() = sender_id);

-- Message Status Policies (already enabled above)
CREATE POLICY "Users can view message status" ON message_status
    FOR SELECT USING (
        auth.uid() = user_id OR
        message_id IN (
            SELECT id FROM messages WHERE sender_id = auth.uid()
        )
    );

CREATE POLICY "Users can update message status" ON message_status
    FOR UPDATE USING (auth.uid() = user_id);

-- Typing Indicators Policies (already enabled above)
CREATE POLICY "Users can manage typing indicators" ON typing_indicators
    FOR ALL USING (
        auth.uid() = user_id OR
        match_id IN (
            SELECT id FROM matches 
            WHERE user1_id = auth.uid() OR user2_id = auth.uid()
        )
    );

-- Albums Policies
CREATE POLICY "Users can view active albums" ON albums
    FOR SELECT USING (
        is_active = true AND (
            auth.uid() = creator_id OR
            auth.uid() IS NOT NULL
        )
    );

CREATE POLICY "Users can manage own albums" ON albums
    FOR ALL USING (auth.uid() = creator_id);

-- Album Content Policies
CREATE POLICY "Users can view album content" ON album_content
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND
        album_id IN (
            SELECT id FROM albums WHERE is_active = true
        )
    );

CREATE POLICY "Creators can manage album content" ON album_content
    FOR ALL USING (
        album_id IN (
            SELECT id FROM albums WHERE creator_id = auth.uid()
        )
    );

-- Album Purchases Policies
CREATE POLICY "Users can view own purchases" ON album_purchases
    FOR SELECT USING (
        auth.uid() = buyer_id OR
        album_id IN (
            SELECT id FROM albums WHERE creator_id = auth.uid()
        )
    );

CREATE POLICY "Users can create purchases" ON album_purchases
    FOR INSERT WITH CHECK (auth.uid() = buyer_id);

-- Wallets Policies
CREATE POLICY "Users can view own wallet" ON wallets
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own wallet" ON wallets
    FOR UPDATE USING (auth.uid() = user_id);

-- Wallet Transactions Policies
CREATE POLICY "Users can view own transactions" ON wallet_transactions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can create transactions" ON wallet_transactions
    FOR INSERT WITH CHECK (true); -- Handled by functions

-- Blocked Users Policies
CREATE POLICY "Users can view own blocks" ON blocked_users
    FOR SELECT USING (auth.uid() = blocker_id);

CREATE POLICY "Users can manage own blocks" ON blocked_users
    FOR ALL USING (auth.uid() = blocker_id);

-- User Reports Policies
CREATE POLICY "Users can view own reports" ON user_reports
    FOR SELECT USING (
        auth.uid() = reporter_id OR
        auth.uid() = reported_id
    );

CREATE POLICY "Users can create reports" ON user_reports
    FOR INSERT WITH CHECK (
        auth.uid() = reporter_id AND
        reporter_id != reported_id
    );

-- Public read policies for reference tables
CREATE POLICY "Anyone can view interest categories" ON interest_categories
    FOR SELECT USING (is_active = true);

CREATE POLICY "Anyone can view interests" ON interests
    FOR SELECT USING (is_active = true);

CREATE POLICY "Anyone can view album categories" ON album_categories
    FOR SELECT USING (is_active = true);

CREATE POLICY "Anyone can view payment methods" ON payment_methods
    FOR SELECT USING (is_active = true);

-- Admin policies (for admin users only)
CREATE POLICY "Admins can view all data" ON profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_users 
            WHERE user_id = auth.uid() AND is_active = true
        )
    );

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin(user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM admin_users 
        WHERE admin_users.user_id = is_admin.user_id AND is_active = true
    );
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- Function to check if user is premium
CREATE OR REPLACE FUNCTION is_premium_user(user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    -- Add premium subscription logic here
    -- For now, return false (no premium subscriptions implemented)
    RETURN false;
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;