-- =============================================
-- Swipe & Matching System
-- =============================================

-- User swipes
CREATE TABLE swipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    swiper_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    swiped_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    is_like BOOLEAN NOT NULL, -- true: like, false: pass
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(swiper_id, swiped_id)
);

-- Matches (when both users like each other)
CREATE TABLE matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user1_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    user2_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    matched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    last_message_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user1_id, user2_id),
    CHECK (user1_id < user2_id) -- ensure consistent ordering
);

-- Undo swipes (premium feature tracking)
CREATE TABLE undo_swipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    original_swipe_id UUID REFERENCES swipes(id) ON DELETE CASCADE,
    used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Daily swipe limits
CREATE TABLE daily_swipe_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    swipe_count INTEGER DEFAULT 0,
    is_premium BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- Profile boosts (premium feature)
CREATE TABLE profile_boosts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    boost_type SMALLINT NOT NULL, -- 1: 30min, 2: 1hour, 3: 3hours
    price INTEGER NOT NULL, -- in cents
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Who likes me (premium feature tracking)
CREATE TABLE profile_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    liker_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    liked_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    is_viewed BOOLEAN DEFAULT FALSE, -- if premium user viewed this like
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(liker_id, liked_id)
);

-- Indexes
CREATE INDEX idx_swipes_swiper ON swipes(swiper_id);
CREATE INDEX idx_swipes_swiped ON swipes(swiped_id);
CREATE INDEX idx_swipes_created ON swipes(created_at);
CREATE INDEX idx_matches_user1 ON matches(user1_id);
CREATE INDEX idx_matches_user2 ON matches(user2_id);
CREATE INDEX idx_matches_active ON matches(is_active);
CREATE INDEX idx_daily_limits_user_date ON daily_swipe_limits(user_id, date);
CREATE INDEX idx_profile_boosts_user ON profile_boosts(user_id);
CREATE INDEX idx_profile_boosts_active ON profile_boosts(is_active, expires_at);
CREATE INDEX idx_profile_likes_liked ON profile_likes(liked_id);

-- Function to create match when both users like each other
CREATE OR REPLACE FUNCTION check_for_match()
RETURNS TRIGGER AS $$
DECLARE
    mutual_like_exists BOOLEAN;
    user1 UUID;
    user2 UUID;
BEGIN
    -- Only process likes, not passes
    IF NEW.is_like = FALSE THEN
        RETURN NEW;
    END IF;
    
    -- Check if the other user already liked this user
    SELECT EXISTS(
        SELECT 1 FROM swipes 
        WHERE swiper_id = NEW.swiped_id 
        AND swiped_id = NEW.swiper_id 
        AND is_like = TRUE
    ) INTO mutual_like_exists;
    
    -- If mutual like exists, create a match
    IF mutual_like_exists THEN
        -- Ensure consistent ordering (smaller UUID first)
        IF NEW.swiper_id < NEW.swiped_id THEN
            user1 := NEW.swiper_id;
            user2 := NEW.swiped_id;
        ELSE
            user1 := NEW.swiped_id;
            user2 := NEW.swiper_id;
        END IF;
        
        -- Insert match (ignore if already exists)
        INSERT INTO matches (user1_id, user2_id)
        VALUES (user1, user2)
        ON CONFLICT (user1_id, user2_id) DO NOTHING;
        
        -- Add to profile_likes for "who likes me" feature
        INSERT INTO profile_likes (liker_id, liked_id)
        VALUES (NEW.swiper_id, NEW.swiped_id)
        ON CONFLICT (liker_id, liked_id) DO NOTHING;
        
        INSERT INTO profile_likes (liker_id, liked_id)
        VALUES (NEW.swiped_id, NEW.swiper_id)
        ON CONFLICT (liker_id, liked_id) DO NOTHING;
    ELSE
        -- Just add to profile_likes for "who likes me" feature
        INSERT INTO profile_likes (liker_id, liked_id)
        VALUES (NEW.swiper_id, NEW.swiped_id)
        ON CONFLICT (liker_id, liked_id) DO NOTHING;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER check_for_match_trigger
    AFTER INSERT ON swipes
    FOR EACH ROW EXECUTE FUNCTION check_for_match();

-- Function to update daily swipe count
CREATE OR REPLACE FUNCTION update_swipe_count()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO daily_swipe_limits (user_id, date, swipe_count)
    VALUES (NEW.swiper_id, CURRENT_DATE, 1)
    ON CONFLICT (user_id, date) 
    DO UPDATE SET swipe_count = daily_swipe_limits.swipe_count + 1;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_swipe_count_trigger
    AFTER INSERT ON swipes
    FOR EACH ROW EXECUTE FUNCTION update_swipe_count();

-- Function to get potential matches (excluding already swiped users)
CREATE OR REPLACE FUNCTION get_potential_matches(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    user_id UUID,
    full_name VARCHAR(100),
    bio TEXT,
    primary_photo_url TEXT,
    age INTEGER,
    distance_km DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.full_name,
        p.bio,
        pp.photo_url,
        EXTRACT(YEAR FROM AGE(p.date_of_birth))::INTEGER,
        CASE 
            WHEN up.latitude IS NOT NULL AND up.longitude IS NOT NULL 
                AND p.latitude IS NOT NULL AND p.longitude IS NOT NULL
            THEN ROUND(
                6371 * acos(
                    cos(radians(up.latitude)) * cos(radians(p.latitude)) * 
                    cos(radians(p.longitude) - radians(up.longitude)) + 
                    sin(radians(up.latitude)) * sin(radians(p.latitude))
                )::DECIMAL, 1
            )
            ELSE NULL
        END
    FROM profiles p
    LEFT JOIN profile_photos pp ON p.id = pp.user_id AND pp.is_primary = TRUE
    LEFT JOIN profiles up ON up.id = p_user_id
    LEFT JOIN user_preferences pref ON pref.user_id = p_user_id
    WHERE p.id != p_user_id
        AND p.id NOT IN (
            SELECT swiped_id FROM swipes WHERE swiper_id = p_user_id
        )
        AND p.id NOT IN (
            SELECT blocked_id FROM blocked_users WHERE blocker_id = p_user_id
        )
        AND p_user_id NOT IN (
            SELECT blocked_id FROM blocked_users WHERE blocker_id = p.id
        )
        AND (pref.min_age IS NULL OR EXTRACT(YEAR FROM AGE(p.date_of_birth)) >= pref.min_age)
        AND (pref.max_age IS NULL OR EXTRACT(YEAR FROM AGE(p.date_of_birth)) <= pref.max_age)
        AND (pref.interested_in IS NULL OR p.gender = ANY(pref.interested_in))
    ORDER BY RANDOM()
    LIMIT p_limit;
END;
$$ language 'plpgsql';