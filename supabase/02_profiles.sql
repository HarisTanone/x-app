-- =============================================
-- User Profiles & Onboarding
-- =============================================

-- Interest categories
CREATE TABLE interest_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    icon_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Individual interests
CREATE TABLE interests (
    id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES interest_categories(id),
    name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User profiles
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(100) NOT NULL,
    bio TEXT,
    headline VARCHAR(50),
    date_of_birth DATE NOT NULL,
    gender SMALLINT NOT NULL, -- 1: male, 2: female, 3: non-binary
    city VARCHAR(100),
    job_title VARCHAR(100),
    education VARCHAR(100),
    height INTEGER, -- in cm
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    location_privacy SMALLINT DEFAULT 1, -- 1: exact, 2: approximate, 3: city_only
    is_verified BOOLEAN DEFAULT FALSE,
    verification_photo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User photos
CREATE TABLE profile_photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    position INTEGER NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User interests (many-to-many)
CREATE TABLE user_interests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    interest_id INTEGER REFERENCES interests(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, interest_id)
);

-- User preferences for matching
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    min_age INTEGER DEFAULT 18,
    max_age INTEGER DEFAULT 60,
    max_distance INTEGER DEFAULT 50, -- in km
    interested_in SMALLINT[], -- array of gender preferences
    show_me SMALLINT DEFAULT 1, -- 1: everyone, 2: verified_only
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User reports
CREATE TABLE user_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    reported_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    reason SMALLINT NOT NULL, -- 1: fake_profile, 2: harassment, 3: inappropriate_content, 4: spam, 5: other
    description TEXT,
    status SMALLINT DEFAULT 1, -- 1: pending, 2: reviewed, 3: resolved
    reviewed_by UUID,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Blocked users
CREATE TABLE blocked_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blocker_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    blocked_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(blocker_id, blocked_id)
);

-- Insert default interest categories
INSERT INTO interest_categories (name) VALUES 
('Musik'), ('Olahraga'), ('Hobi'), ('Film & Series'), ('Lainnya');

-- Insert default interests
INSERT INTO interests (category_id, name) VALUES 
(1, 'Pop'), (1, 'Rock'), (1, 'Jazz'), (1, 'K-pop'), (1, 'Indie'),
(2, 'Futsal'), (2, 'Gym'), (2, 'Yoga'), (2, 'Berenang'), (2, 'Lari'),
(3, 'Fotografi'), (3, 'Traveling'), (3, 'Memasak'), (3, 'Gaming'), (3, 'Membaca'),
(4, 'Drama'), (4, 'Horror'), (4, 'Comedy'), (4, 'Action'), (4, 'Romance'),
(5, 'Teknologi'), (5, 'Fashion'), (5, 'Seni'), (5, 'Bisnis'), (5, 'Kesehatan');

-- Indexes
CREATE INDEX idx_profiles_gender ON profiles(gender);
CREATE INDEX idx_profiles_city ON profiles(city);
CREATE INDEX idx_profiles_location ON profiles(latitude, longitude);
CREATE INDEX idx_profile_photos_user ON profile_photos(user_id);
CREATE INDEX idx_user_interests_user ON user_interests(user_id);
CREATE INDEX idx_user_reports_reported ON user_reports(reported_id);
CREATE INDEX idx_blocked_users_blocker ON blocked_users(blocker_id);
CREATE INDEX idx_blocked_users_blocked ON blocked_users(blocked_id);

-- Triggers
CREATE TRIGGER update_profiles_updated_at 
    BEFORE UPDATE ON profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at 
    BEFORE UPDATE ON user_preferences 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to ensure only one primary photo per user
CREATE OR REPLACE FUNCTION ensure_single_primary_photo()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_primary = TRUE THEN
        UPDATE profile_photos 
        SET is_primary = FALSE 
        WHERE user_id = NEW.user_id AND id != NEW.id;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER ensure_single_primary_photo_trigger
    BEFORE INSERT OR UPDATE ON profile_photos
    FOR EACH ROW EXECUTE FUNCTION ensure_single_primary_photo();

-- Function to create default preferences on profile creation
CREATE OR REPLACE FUNCTION create_default_preferences()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_preferences (user_id, interested_in)
    VALUES (NEW.id, ARRAY[1,2,3]); -- interested in all genders by default
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER create_default_preferences_trigger
    AFTER INSERT ON profiles
    FOR EACH ROW EXECUTE FUNCTION create_default_preferences();