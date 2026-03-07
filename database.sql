-- ============================================================
-- YouTube Trend Analysis - MySQL Database Schema
-- ============================================================

CREATE DATABASE IF NOT EXISTS yttrend_db_ CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE yttrend_db_;

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  avatar_url VARCHAR(255) DEFAULT NULL,
  region VARCHAR(10) DEFAULT 'US',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  last_login TIMESTAMP NULL,
  is_active TINYINT(1) DEFAULT 1
);

-- API Keys rotation table
CREATE TABLE IF NOT EXISTS api_keys (
  id INT AUTO_INCREMENT PRIMARY KEY,
  key_name VARCHAR(50) NOT NULL,
  api_key VARCHAR(100) NOT NULL,
  daily_quota INT DEFAULT 10000,
  used_quota INT DEFAULT 0,
  quota_reset_at DATE DEFAULT (CURDATE()),
  is_active TINYINT(1) DEFAULT 1,
  priority INT DEFAULT 1 COMMENT '1=primary, 2=secondary, 3=tertiary',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert your 3 API keys here
INSERT INTO api_keys (key_name, api_key, daily_quota, priority) VALUES
  ('Primary Key',   'AIzaSyDDQMsohbhGT86XOtsvHV-P60zwDnYj0zQ', 10000, 1),
  ('Secondary Key', 'AIzaSyAucp0HjIJBFW6gcBbpexw9dun9KcINl7s', 10000, 2),
  ('Tertiary Key',  'AIzaSyA-ibkA3K4W8cJuhss7AA7q94kszvBD6o4', 10000, 3);

-- Categories master table
CREATE TABLE IF NOT EXISTS categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  youtube_category_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) NOT NULL,
  icon VARCHAR(50) DEFAULT '🎬',
  color VARCHAR(20) DEFAULT '#FF0000'
);

INSERT INTO categories (youtube_category_id, name, slug, icon, color) VALUES
  (1,  'Film & Animation',       'film-animation',       '🎬', '#FF6B6B'),
  (2,  'Autos & Vehicles',       'autos-vehicles',       '🚗', '#4ECDC4'),
  (10, 'Music',                  'music',                '🎵', '#45B7D1'),
  (15, 'Pets & Animals',         'pets-animals',         '🐾', '#96CEB4'),
  (17, 'Sports',                 'sports',               '⚽', '#FFEAA7'),
  (18, 'Short Movies',           'short-movies',         '🎞️', '#DDA0DD'),
  (19, 'Travel & Events',        'travel-events',        '✈️', '#98D8C8'),
  (20, 'Gaming',                 'gaming',               '🎮', '#F7DC6F'),
  (21, 'Videoblogging',          'videoblogging',        '📹', '#82E0AA'),
  (22, 'People & Blogs',         'people-blogs',         '👤', '#F1948A'),
  (23, 'Comedy',                 'comedy',               '😂', '#FAD7A0'),
  (24, 'Entertainment',          'entertainment',        '🎭', '#A9CCE3'),
  (25, 'News & Politics',        'news-politics',        '📰', '#D5DBDB'),
  (26, 'Howto & Style',          'howto-style',          '💄', '#F9E79F'),
  (27, 'Education',              'education',            '📚', '#A9DFBF'),
  (28, 'Science & Technology',   'science-technology',   '🔬', '#AED6F1'),
  (29, 'Nonprofits & Activism',  'nonprofits-activism',  '🌍', '#A3E4D7'),
  (30, 'Movies',                 'movies',               '🍿', '#F5CBA7'),
  (31, 'Anime/Animation',        'anime-animation',      '🎌', '#F1948A'),
  (32, 'Action/Adventure',       'action-adventure',     '⚔️', '#E74C3C'),
  (33, 'Classics',               'classics',             '🏛️', '#BDC3C7'),
  (34, 'Comedy (Film)',          'comedy-film',          '🎪', '#E8DAEF'),
  (35, 'Documentary',            'documentary',          '🎥', '#D6EAF8'),
  (36, 'Drama',                  'drama',                '#9B59B6', '#9B59B6'),
  (37, 'Family',                 'family',               '👨‍👩‍👧‍👦', '#A9CCE3'),
  (38, 'Foreign',                'foreign',              '🌐', '#A2D9CE'),
  (39, 'Horror',                 'horror',               '👻', '#C0392B'),
  (40, 'Sci-Fi/Fantasy',         'sci-fi-fantasy',       '🚀', '#8E44AD'),
  (41, 'Thriller',               'thriller',             '🔪', '#2C3E50'),
  (42, 'Shorts',                 'shorts',               '⚡', '#F39C12'),
  (43, 'Shows',                  'shows',                '📺', '#27AE60'),
  (44, 'Trailers',               'trailers',             '🎬', '#E74C3C');

-- Regions table
CREATE TABLE IF NOT EXISTS regions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(5) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  flag VARCHAR(10) DEFAULT '🌍'
);

INSERT INTO regions (code, name, flag) VALUES
  ('AR', 'Argentina', '🇦🇷'), ('AU', 'Australia', '🇦🇺'), ('AT', 'Austria', '🇦🇹'),
  ('AZ', 'Azerbaijan', '🇦🇿'), ('BH', 'Bahrain', '🇧🇭'), ('BY', 'Belarus', '🇧🇾'),
  ('BE', 'Belgium', '🇧🇪'), ('BO', 'Bolivia', '🇧🇴'), ('BA', 'Bosnia and Herzegovina', '🇧🇦'),
  ('BR', 'Brazil', '🇧🇷'), ('BG', 'Bulgaria', '🇧🇬'), ('CA', 'Canada', '🇨🇦'),
  ('CL', 'Chile', '🇨🇱'), ('CO', 'Colombia', '🇨🇴'), ('CR', 'Costa Rica', '🇨🇷'),
  ('HR', 'Croatia', '🇭🇷'), ('CY', 'Cyprus', '🇨🇾'), ('CZ', 'Czech Republic', '🇨🇿'),
  ('DK', 'Denmark', '🇩🇰'), ('DO', 'Dominican Republic', '🇩🇴'), ('EC', 'Ecuador', '🇪🇨'),
  ('EG', 'Egypt', '🇪🇬'), ('SV', 'El Salvador', '🇸🇻'), ('EE', 'Estonia', '🇪🇪'),
  ('FI', 'Finland', '🇫🇮'), ('FR', 'France', '🇫🇷'), ('GE', 'Georgia', '🇬🇪'),
  ('DE', 'Germany', '🇩🇪'), ('GH', 'Ghana', '🇬🇭'), ('GR', 'Greece', '🇬🇷'),
  ('GT', 'Guatemala', '🇬🇹'), ('HN', 'Honduras', '🇭🇳'), ('HK', 'Hong Kong', '🇭🇰'),
  ('HU', 'Hungary', '🇭🇺'), ('IN', 'India', '🇮🇳'), ('ID', 'Indonesia', '🇮🇩'),
  ('IQ', 'Iraq', '🇮🇶'), ('IE', 'Ireland', '🇮🇪'), ('IL', 'Israel', '🇮🇱'),
  ('IT', 'Italy', '🇮🇹'), ('JM', 'Jamaica', '🇯🇲'), ('JP', 'Japan', '🇯🇵'),
  ('JO', 'Jordan', '🇯🇴'), ('KZ', 'Kazakhstan', '🇰🇿'), ('KE', 'Kenya', '🇰🇪'),
  ('KW', 'Kuwait', '🇰🇼'), ('LV', 'Latvia', '🇱🇻'), ('LB', 'Lebanon', '🇱🇧'),
  ('LY', 'Libya', '🇱🇾'), ('LT', 'Lithuania', '🇱🇹'), ('LU', 'Luxembourg', '🇱🇺'),
  ('MY', 'Malaysia', '🇲🇾'), ('MT', 'Malta', '🇲🇹'), ('MX', 'Mexico', '🇲🇽'),
  ('MD', 'Moldova', '🇲🇩'), ('ME', 'Montenegro', '🇲🇪'), ('MA', 'Morocco', '🇲🇦'),
  ('NP', 'Nepal', '🇳🇵'), ('NL', 'Netherlands', '🇳🇱'), ('NZ', 'New Zealand', '🇳🇿'),
  ('NI', 'Nicaragua', '🇳🇮'), ('NG', 'Nigeria', '🇳🇬'), ('MK', 'North Macedonia', '🇲🇰'),
  ('NO', 'Norway', '🇳🇴'), ('OM', 'Oman', '🇴🇲'), ('PK', 'Pakistan', '🇵🇰'),
  ('PA', 'Panama', '🇵🇦'), ('PG', 'Papua New Guinea', '🇵🇬'), ('PY', 'Paraguay', '🇵🇾'),
  ('PE', 'Peru', '🇵🇪'), ('PH', 'Philippines', '🇵🇭'), ('PL', 'Poland', '🇵🇱'),
  ('PT', 'Portugal', '🇵🇹'), ('PR', 'Puerto Rico', '🇵🇷'), ('QA', 'Qatar', '🇶🇦'),
  ('RO', 'Romania', '🇷🇴'), ('RU', 'Russia', '🇷🇺'), ('SA', 'Saudi Arabia', '🇸🇦'),
  ('SN', 'Senegal', '🇸🇳'), ('RS', 'Serbia', '🇷🇸'), ('SG', 'Singapore', '🇸🇬'),
  ('SK', 'Slovakia', '🇸🇰'), ('SI', 'Slovenia', '🇸🇮'), ('ZA', 'South Africa', '🇿🇦'),
  ('KR', 'South Korea', '🇰🇷'), ('ES', 'Spain', '🇪🇸'), ('LK', 'Sri Lanka', '🇱🇰'),
  ('SE', 'Sweden', '🇸🇪'), ('CH', 'Switzerland', '🇨🇭'), ('TW', 'Taiwan', '🇹🇼'),
  ('TZ', 'Tanzania', '🇹🇿'), ('TH', 'Thailand', '🇹🇭'), ('TN', 'Tunisia', '🇹🇳'),
  ('TR', 'Turkey', '🇹🇷'), ('UG', 'Uganda', '🇺🇬'), ('UA', 'Ukraine', '🇺🇦'),
  ('AE', 'United Arab Emirates', '🇦🇪'), ('GB', 'United Kingdom', '🇬🇧'),
  ('US', 'United States', '🇺🇸'), ('UY', 'Uruguay', '🇺🇾'), ('UZ', 'Uzbekistan', '🇺🇿'),
  ('VE', 'Venezuela', '🇻🇪'), ('VN', 'Vietnam', '🇻🇳'), ('YE', 'Yemen', '🇾🇪'),
  ('ZW', 'Zimbabwe', '🇿🇼');

-- Cached trending videos
CREATE TABLE IF NOT EXISTS trending_videos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  video_id VARCHAR(20) NOT NULL,
  title VARCHAR(500) NOT NULL,
  channel_name VARCHAR(200) NOT NULL,
  channel_id VARCHAR(50) NOT NULL,
  thumbnail_url VARCHAR(500),
  view_count BIGINT DEFAULT 0,
  like_count BIGINT DEFAULT 0,
  comment_count BIGINT DEFAULT 0,
  duration VARCHAR(20),
  category_id INT,
  region_code VARCHAR(5),
  published_at TIMESTAMP NULL,
  fetched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  rank_position INT DEFAULT 0,
  INDEX idx_region_category (region_code, category_id),
  INDEX idx_fetched (fetched_at),
  INDEX idx_video_id (video_id)
);

-- User saved/bookmarked videos
CREATE TABLE IF NOT EXISTS user_bookmarks (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  video_id VARCHAR(20) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY unique_bookmark (user_id, video_id)
);

-- User sessions
CREATE TABLE IF NOT EXISTS user_sessions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  session_token VARCHAR(255) NOT NULL UNIQUE,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Trend snapshots for graph history
CREATE TABLE IF NOT EXISTS trend_snapshots (
  id INT AUTO_INCREMENT PRIMARY KEY,
  region_code VARCHAR(5) NOT NULL,
  category_id INT,
  snapshot_date DATE NOT NULL,
  total_views BIGINT DEFAULT 0,
  video_count INT DEFAULT 0,
  avg_views BIGINT DEFAULT 0,
  top_video_id VARCHAR(20),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_snapshot (region_code, category_id, snapshot_date)
);

-- Search history
CREATE TABLE IF NOT EXISTS search_history (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  query VARCHAR(255) NOT NULL,
  region_code VARCHAR(5),
  category_id INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_user (user_id)
);
