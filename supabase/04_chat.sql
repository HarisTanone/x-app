-- =============================================
-- Chat & Messaging System
-- =============================================

-- Chat messages
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT,
    message_type SMALLINT DEFAULT 1, -- 1: text, 2: image, 3: video, 4: sticker
    media_url TEXT,
    media_thumbnail TEXT,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Message status tracking
CREATE TABLE message_status (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    status SMALLINT DEFAULT 1, -- 1: sent, 2: delivered, 3: read
    status_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(message_id, user_id)
);

-- Typing indicators
CREATE TABLE typing_indicators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    is_typing BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(match_id, user_id)
);

-- Chat settings per match
CREATE TABLE chat_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    is_muted BOOLEAN DEFAULT FALSE,
    is_archived BOOLEAN DEFAULT FALSE,
    last_read_message_id UUID REFERENCES messages(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(match_id, user_id)
);

-- Screenshot detection logs
CREATE TABLE screenshot_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID REFERENCES matches(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_messages_match ON messages(match_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_created ON messages(created_at);
CREATE INDEX idx_message_status_message ON message_status(message_id);
CREATE INDEX idx_message_status_user ON message_status(user_id);
CREATE INDEX idx_typing_indicators_match ON typing_indicators(match_id);
CREATE INDEX idx_chat_settings_match ON chat_settings(match_id);
CREATE INDEX idx_chat_settings_user ON chat_settings(user_id);

-- Enable realtime for messages
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_indicators ENABLE ROW LEVEL SECURITY;

-- Triggers
CREATE TRIGGER update_messages_updated_at 
    BEFORE UPDATE ON messages 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_settings_updated_at 
    BEFORE UPDATE ON chat_settings 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update match last_message_at
CREATE OR REPLACE FUNCTION update_match_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE matches 
    SET last_message_at = NEW.created_at
    WHERE id = NEW.match_id;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_match_last_message_trigger
    AFTER INSERT ON messages
    FOR EACH ROW EXECUTE FUNCTION update_match_last_message();

-- Function to create message status for both users in match
CREATE OR REPLACE FUNCTION create_message_status()
RETURNS TRIGGER AS $$
DECLARE
    match_user1 UUID;
    match_user2 UUID;
    recipient_id UUID;
BEGIN
    -- Get both users from the match
    SELECT user1_id, user2_id INTO match_user1, match_user2
    FROM matches WHERE id = NEW.match_id;
    
    -- Determine recipient (the user who didn't send the message)
    IF NEW.sender_id = match_user1 THEN
        recipient_id := match_user2;
    ELSE
        recipient_id := match_user1;
    END IF;
    
    -- Create status for sender (sent)
    INSERT INTO message_status (message_id, user_id, status)
    VALUES (NEW.id, NEW.sender_id, 1);
    
    -- Create status for recipient (delivered)
    INSERT INTO message_status (message_id, user_id, status)
    VALUES (NEW.id, recipient_id, 2);
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER create_message_status_trigger
    AFTER INSERT ON messages
    FOR EACH ROW EXECUTE FUNCTION create_message_status();

-- Function to get chat history
CREATE OR REPLACE FUNCTION get_chat_messages(
    p_match_id UUID,
    p_user_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    message_id UUID,
    sender_id UUID,
    sender_name VARCHAR(100),
    content TEXT,
    message_type SMALLINT,
    media_url TEXT,
    media_thumbnail TEXT,
    is_deleted BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    status SMALLINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id,
        m.sender_id,
        p.full_name,
        m.content,
        m.message_type,
        m.media_url,
        m.media_thumbnail,
        m.is_deleted,
        m.created_at,
        ms.status
    FROM messages m
    JOIN profiles p ON m.sender_id = p.id
    LEFT JOIN message_status ms ON m.id = ms.message_id AND ms.user_id = p_user_id
    WHERE m.match_id = p_match_id
    ORDER BY m.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ language 'plpgsql';

-- Function to mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_as_read(
    p_match_id UUID,
    p_user_id UUID,
    p_message_ids UUID[]
)
RETURNS VOID AS $$
BEGIN
    UPDATE message_status 
    SET status = 3, status_at = NOW()
    WHERE user_id = p_user_id 
        AND message_id = ANY(p_message_ids)
        AND status < 3;
        
    -- Update chat settings with last read message
    UPDATE chat_settings 
    SET last_read_message_id = (
        SELECT MAX(message_id) FROM unnest(p_message_ids) AS message_id
    )
    WHERE match_id = p_match_id AND user_id = p_user_id;
END;
$$ language 'plpgsql';

-- Function to get unread message count
CREATE OR REPLACE FUNCTION get_unread_count(p_user_id UUID)
RETURNS TABLE (
    match_id UUID,
    unread_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.match_id,
        COUNT(*) as unread_count
    FROM messages m
    JOIN message_status ms ON m.id = ms.message_id
    WHERE ms.user_id = p_user_id 
        AND ms.status < 3 
        AND m.sender_id != p_user_id
    GROUP BY m.match_id;
END;
$$ language 'plpgsql';