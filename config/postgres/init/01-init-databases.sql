-- Create Kong database
CREATE DATABASE kong;
GRANT ALL PRIVILEGES ON DATABASE kong TO nlapi;

-- Switch to native_languages database
\c native_languages;

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create languages table
CREATE TABLE IF NOT EXISTS languages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    native_name VARCHAR(100),
    iso_code VARCHAR(10),
    region VARCHAR(50),
    speakers_count INTEGER,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create words table
CREATE TABLE IF NOT EXISTS words (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    language_id UUID REFERENCES languages(id) ON DELETE CASCADE,
    word VARCHAR(200) NOT NULL,
    translation VARCHAR(200),
    phonetic VARCHAR(300),
    part_of_speech VARCHAR(50),
    category VARCHAR(100),
    difficulty_level INTEGER DEFAULT 1,
    usage_count INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create audio_files table
CREATE TABLE IF NOT EXISTS audio_files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    word_id UUID REFERENCES words(id) ON DELETE CASCADE,
    file_path VARCHAR(500) NOT NULL,
    file_size INTEGER,
    duration_ms INTEGER,
    format VARCHAR(10),
    quality_score DECIMAL(3,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role VARCHAR(50) DEFAULT 'user',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create api_keys table
CREATE TABLE IF NOT EXISTS api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key_hash VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(100),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    tier VARCHAR(20) DEFAULT 'free',
    rate_limit_per_minute INTEGER DEFAULT 60,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE
);

-- Create api_usage table
CREATE TABLE IF NOT EXISTS api_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    api_key_id UUID REFERENCES api_keys(id) ON DELETE CASCADE,
    endpoint VARCHAR(200),
    method VARCHAR(10),
    status_code INTEGER,
    response_time_ms INTEGER,
    ip_address INET,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_words_language_id ON words(language_id);
CREATE INDEX IF NOT EXISTS idx_words_category ON words(category);
CREATE INDEX IF NOT EXISTS idx_audio_files_word_id ON audio_files(word_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_user_id ON api_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_api_usage_created_at ON api_usage(created_at);

-- Insert sample languages
INSERT INTO languages (code, name, native_name, iso_code, region, speakers_count) VALUES
    ('swh', 'Swahili', 'Kiswahili', 'sw', 'East Africa', 150000000),
    ('yor', 'Yoruba', 'Yorùbá', 'yo', 'West Africa', 45000000),
    ('ibo', 'Igbo', 'Igbo', 'ig', 'West Africa', 24000000),
    ('hau', 'Hausa', 'Hausa', 'ha', 'West Africa', 70000000),
    ('amh', 'Amharic', 'አማርኛ', 'am', 'East Africa', 32000000)
ON CONFLICT (code) DO NOTHING;

-- Insert sample words
INSERT INTO words (language_id, word, translation, category) VALUES
    ((SELECT id FROM languages WHERE code = 'swh'), 'jambo', 'hello', 'greetings'),
    ((SELECT id FROM languages WHERE code = 'swh'), 'asante', 'thank you', 'greetings'),
    ((SELECT id FROM languages WHERE code = 'yor'), 'ẹ kú àárọ̀', 'good morning', 'greetings'),
    ((SELECT id FROM languages WHERE code = 'ibo'), 'ndewo', 'hello', 'greetings'),
    ((SELECT id FROM languages WHERE code = 'hau'), 'sannu', 'hello', 'greetings')
ON CONFLICT DO NOTHING;
