# TrendPulse — YouTube Trend Analysis Website

## 📁 File Structure

```
yttrend/
├── index.html          ← Landing page (overview + auth modal)
├── dashboard.html      ← Main app dashboard
├── api/
│   └── index.php       ← Backend API (YouTube + Auth + DB)
├── database.sql        ← MySQL schema + seed data
└── README.md
```

---

## ⚡ Quick Start

### 1. Database Setup
```sql
mysql -u root -p < database.sql
```

### 2. Configure API (api/index.php)
Edit the top of `api/index.php`:
```php
define('DB_HOST', 'localhost');
define('DB_USER', 'your_mysql_user');
define('DB_PASS', 'your_mysql_password');
define('DB_NAME', 'yttrend_db');
define('JWT_SECRET', 'change_this_to_random_string');
```

### 3. Add YouTube API Keys (in database)
```sql
UPDATE api_keys SET api_key = 'YOUR_REAL_KEY' WHERE priority = 1;
UPDATE api_keys SET api_key = 'YOUR_BACKUP_KEY' WHERE priority = 2;
UPDATE api_keys SET api_key = 'YOUR_THIRD_KEY' WHERE priority = 3;
```

### 4. Get YouTube API Keys FREE
1. Go to https://console.cloud.google.com
2. Create a new project
3. Enable "YouTube Data API v3"
4. Create credentials → API Key
5. Repeat for 3 keys (each = 10,000 units/day free)

### 5. Deploy
- Put files on any PHP+MySQL web server (Apache/Nginx)
- Or use XAMPP/WAMP locally

---

## 🌐 Pure Frontend Mode (No Backend)
Just open `index.html` and `dashboard.html` directly in browser.
- Works fully with demo data
- Configure API keys via the 🔑 button in the dashboard
- Keys saved in browser localStorage for instant live data

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔥 Trending Videos | Top 50 YouTube trending per region |
| 🌍 100+ Regions | All YouTube-supported countries |
| 🏷️ 44 Categories | All YouTube content categories |
| 📊 Trend Charts | Views over time (7d/1m/3m/1y) |
| 🔑 3 API Keys | Auto-rotation when quota exceeded |
| 📺 Channel Analysis | Top channels by trending count |
| 🔖 Bookmarks | Save videos locally |
| 🔗 Direct Links | Click to open video on YouTube |
| 🔐 Auth | Login/Register with session |
| 📱 Responsive | Works on mobile, tablet, desktop |

---

## 🔑 API Key Rotation Logic

```
Request comes in
    ↓
Try Key 1 (Primary)
    ↓ 403/Quota error?
Try Key 2 (Secondary)  
    ↓ 403/Quota error?
Try Key 3 (Tertiary)
    ↓ All exhausted?
Show cached data / error
```

Keys reset daily at midnight. Each key = 10,000 units/day.
One trending request ≈ 100 units → ~100 refreshes/key/day.

---

## 📊 Database Tables

- `users` — Registered users
- `api_keys` — YouTube API keys with quota tracking  
- `categories` — All 44 YouTube categories
- `regions` — 100+ supported countries
- `trending_videos` — Cached trending data (refreshed hourly)
- `user_bookmarks` — User-saved videos
- `user_sessions` — Login sessions
- `trend_snapshots` — Historical data for graphs
- `search_history` — User search logs
