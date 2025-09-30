-- =============================================
-- Premium Content & Albums System
-- =============================================

-- Album categories
CREATE TABLE album_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Premium albums
CREATE TABLE albums (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    category_id INTEGER REFERENCES album_categories(id),
    price INTEGER NOT NULL, -- in cents (10000 = Rp 100.00)
    thumbnail_url TEXT,
    preview_urls TEXT[], -- array of preview image URLs (blurred)
    is_free BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    total_sales INTEGER DEFAULT 0,
    total_revenue BIGINT DEFAULT 0, -- in cents
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Album content (photos/videos)
CREATE TABLE album_content (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    album_id UUID REFERENCES albums(id) ON DELETE CASCADE,
    content_url TEXT NOT NULL,
    content_type SMALLINT NOT NULL, -- 1: image, 2: video
    thumbnail_url TEXT,
    file_size BIGINT, -- in bytes
    duration INTEGER, -- for videos, in seconds
    position INTEGER NOT NULL,
    watermark_url TEXT, -- watermarked version for buyers
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Album purchases
CREATE TABLE album_purchases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    album_id UUID REFERENCES albums(id) ON DELETE CASCADE,
    buyer_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    price_paid INTEGER NOT NULL, -- in cents
    payment_method VARCHAR(20),
    transaction_id VARCHAR(100),
    purchased_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(album_id, buyer_id)
);

-- Album reviews
CREATE TABLE album_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    album_id UUID REFERENCES albums(id) ON DELETE CASCADE,
    reviewer_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    purchase_id UUID REFERENCES album_purchases(id) ON DELETE CASCADE,
    rating SMALLINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    is_anonymous BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(album_id, reviewer_id)
);

-- Album access logs (for analytics)
CREATE TABLE album_access_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    album_id UUID REFERENCES albums(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    access_type SMALLINT NOT NULL, -- 1: preview, 2: full_access, 3: download_attempt
    ip_address INET,
    user_agent TEXT,
    accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Creator earnings
CREATE TABLE creator_earnings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    album_id UUID REFERENCES albums(id) ON DELETE CASCADE,
    purchase_id UUID REFERENCES album_purchases(id) ON DELETE CASCADE,
    gross_amount INTEGER NOT NULL, -- in cents
    platform_fee INTEGER NOT NULL, -- in cents (5% of gross)
    net_amount INTEGER NOT NULL, -- in cents (gross - platform_fee)
    status SMALLINT DEFAULT 1, -- 1: pending, 2: available, 3: withdrawn
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default categories
INSERT INTO album_categories (name, description) VALUES 
('Personal', 'Personal photos and daily life content'),
('Professional', 'Professional photoshoot and modeling content'),
('Behind the Scenes', 'Behind the scenes and exclusive content'),
('Limited Edition', 'Exclusive and limited time content');

-- Indexes
CREATE INDEX idx_albums_creator ON albums(creator_id);
CREATE INDEX idx_albums_category ON albums(category_id);
CREATE INDEX idx_albums_active ON albums(is_active);
CREATE INDEX idx_albums_featured ON albums(is_featured);
CREATE INDEX idx_album_content_album ON album_content(album_id);
CREATE INDEX idx_album_purchases_album ON album_purchases(album_id);
CREATE INDEX idx_album_purchases_buyer ON album_purchases(buyer_id);
CREATE INDEX idx_album_reviews_album ON album_reviews(album_id);
CREATE INDEX idx_creator_earnings_creator ON creator_earnings(creator_id);
CREATE INDEX idx_creator_earnings_status ON creator_earnings(status);

-- Triggers
CREATE TRIGGER update_albums_updated_at 
    BEFORE UPDATE ON albums 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update album stats on purchase
CREATE OR REPLACE FUNCTION update_album_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update album sales and revenue
    UPDATE albums 
    SET 
        total_sales = total_sales + 1,
        total_revenue = total_revenue + NEW.price_paid
    WHERE id = NEW.album_id;
    
    -- Create creator earnings record
    INSERT INTO creator_earnings (
        creator_id, 
        album_id, 
        purchase_id, 
        gross_amount, 
        platform_fee, 
        net_amount
    )
    SELECT 
        a.creator_id,
        NEW.album_id,
        NEW.id,
        NEW.price_paid,
        ROUND(NEW.price_paid * 0.05), -- 5% platform fee
        NEW.price_paid - ROUND(NEW.price_paid * 0.05)
    FROM albums a
    WHERE a.id = NEW.album_id;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_album_stats_trigger
    AFTER INSERT ON album_purchases
    FOR EACH ROW EXECUTE FUNCTION update_album_stats();

-- Function to check if user has access to album
CREATE OR REPLACE FUNCTION has_album_access(
    p_album_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    is_creator BOOLEAN;
    has_purchased BOOLEAN;
    is_free_album BOOLEAN;
BEGIN
    -- Check if user is the creator
    SELECT EXISTS(
        SELECT 1 FROM albums WHERE id = p_album_id AND creator_id = p_user_id
    ) INTO is_creator;
    
    IF is_creator THEN
        RETURN TRUE;
    END IF;
    
    -- Check if album is free
    SELECT is_free INTO is_free_album FROM albums WHERE id = p_album_id;
    
    IF is_free_album THEN
        RETURN TRUE;
    END IF;
    
    -- Check if user has purchased the album
    SELECT EXISTS(
        SELECT 1 FROM album_purchases 
        WHERE album_id = p_album_id AND buyer_id = p_user_id
    ) INTO has_purchased;
    
    RETURN has_purchased;
END;
$$ language 'plpgsql';

-- Function to get album content with access control
CREATE OR REPLACE FUNCTION get_album_content(
    p_album_id UUID,
    p_user_id UUID
)
RETURNS TABLE (
    content_id UUID,
    content_url TEXT,
    content_type SMALLINT,
    thumbnail_url TEXT,
    "position" INTEGER,
    has_access BOOLEAN
) AS $$
DECLARE
    user_has_access BOOLEAN;
BEGIN
    -- Check if user has access
    SELECT has_album_access(p_album_id, p_user_id) INTO user_has_access;
    
    RETURN QUERY
    SELECT 
        ac.id,
        CASE 
            WHEN user_has_access THEN ac.watermark_url
            ELSE ac.thumbnail_url -- return blurred preview
        END,
        ac.content_type,
        ac.thumbnail_url,
        ac."position",
        user_has_access
    FROM album_content ac
    WHERE ac.album_id = p_album_id
    ORDER BY ac."position";
END;
$$ language 'plpgsql';

-- Function to get creator dashboard stats
CREATE OR REPLACE FUNCTION get_creator_stats(p_creator_id UUID)
RETURNS TABLE (
    total_albums INTEGER,
    total_sales INTEGER,
    total_revenue BIGINT,
    pending_earnings BIGINT,
    available_earnings BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT a.id)::INTEGER,
        COALESCE(SUM(a.total_sales), 0)::INTEGER,
        COALESCE(SUM(a.total_revenue), 0)::BIGINT,
        COALESCE(SUM(CASE WHEN ce.status = 1 THEN ce.net_amount ELSE 0 END), 0)::BIGINT,
        COALESCE(SUM(CASE WHEN ce.status = 2 THEN ce.net_amount ELSE 0 END), 0)::BIGINT
    FROM albums a
    LEFT JOIN creator_earnings ce ON a.id = ce.album_id
    WHERE a.creator_id = p_creator_id;
END;
$$ language 'plpgsql';