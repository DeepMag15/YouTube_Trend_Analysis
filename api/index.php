<?php
// ============================================================
// api/config.php - Database & YouTube API Configuration
// ============================================================

define('DB_HOST', 'localhost');
define('DB_USER', 'root');
define('DB_PASS', '123456');
define('DB_NAME', 'yttrend_db_');
define('SITE_URL', 'http://localhost/yttrend');
define('JWT_SECRET', 'your_super_secret_jwt_key_change_this');

function getDB() {
    static $pdo = null;
    if ($pdo === null) {
        $pdo = new PDO(
            "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
            DB_USER, DB_PASS,
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]
        );
    }
    return $pdo;
}

// ============================================================
// api/youtube.php - YouTube API with key rotation
// ============================================================

function getActiveApiKey() {
    $db = getDB();
    $today = date('Y-m-d');

    // Reset quota if new day
    $db->exec("UPDATE api_keys SET used_quota = 0, quota_reset_at = CURDATE() WHERE quota_reset_at < CURDATE()");

    // Get the key with lowest priority number that still has quota
    $stmt = $db->prepare("SELECT * FROM api_keys WHERE is_active = 1 AND used_quota < daily_quota ORDER BY priority ASC LIMIT 1");
    $stmt->execute();
    return $stmt->fetch();
}

function youtubeRequest($endpoint, $params) {
    $key = getActiveApiKey();
    if (!$key) {
        return ['error' => 'All API keys exhausted for today'];
    }

    $params['key'] = $key['api_key'];
    $url = "https://www.googleapis.com/youtube/v3/" . $endpoint . "?" . http_build_query($params);

    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL => $url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 10,
        CURLOPT_SSL_VERIFYPEER => true
    ]);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode === 403) {
        // Quota exceeded for this key, disable it and try next
        $db = getDB();
        $stmt = $db->prepare("UPDATE api_keys SET used_quota = daily_quota WHERE id = ?");
        $stmt->execute([$key['id']]);
        return youtubeRequest($endpoint, array_diff_key($params, ['key' => '']));
    }

    // Increment usage counter (approximate: 1 trending request = ~100 units)
    $db = getDB();
    $stmt = $db->prepare("UPDATE api_keys SET used_quota = used_quota + 100 WHERE id = ?");
    $stmt->execute([$key['id']]);

    return json_decode($response, true);
}

function getTrendingVideos($regionCode = 'US', $categoryId = '', $maxResults = 50) {
    $params = [
        'part'       => 'snippet,statistics,contentDetails',
        'chart'      => 'mostPopular',
        'regionCode' => $regionCode,
        'maxResults' => $maxResults,
        'hl'         => 'en_US'
    ];
    if ($categoryId) $params['videoCategoryId'] = $categoryId;

    $data = youtubeRequest('videos', $params);
    if (isset($data['error'])) return $data;

    $videos = [];
    foreach ($data['items'] ?? [] as $i => $item) {
        $videos[] = [
            'video_id'      => $item['id'],
            'title'         => $item['snippet']['title'],
            'channel_name'  => $item['snippet']['channelTitle'],
            'channel_id'    => $item['snippet']['channelId'],
            'thumbnail'     => $item['snippet']['thumbnails']['maxres']['url']
                            ?? $item['snippet']['thumbnails']['high']['url']
                            ?? $item['snippet']['thumbnails']['medium']['url'],
            'view_count'    => $item['statistics']['viewCount'] ?? 0,
            'like_count'    => $item['statistics']['likeCount'] ?? 0,
            'comment_count' => $item['statistics']['commentCount'] ?? 0,
            'duration'      => formatDuration($item['contentDetails']['duration'] ?? ''),
            'category_id'   => $item['snippet']['categoryId'] ?? 0,
            'published_at'  => $item['snippet']['publishedAt'],
            'description'   => substr($item['snippet']['description'], 0, 200),
            'tags'          => implode(', ', array_slice($item['snippet']['tags'] ?? [], 0, 5)),
            'rank'          => $i + 1,
            'url'           => "https://www.youtube.com/watch?v=" . $item['id']
        ];
    }

    // Cache to DB
    cacheTrendingVideos($videos, $regionCode);
    return ['videos' => $videos, 'total' => count($videos)];
}

function formatDuration($iso) {
    preg_match('/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/', $iso, $m);
    $h = intval($m[1] ?? 0);
    $m2 = intval($m[2] ?? 0);
    $s = intval($m[3] ?? 0);
    if ($h > 0) return sprintf("%d:%02d:%02d", $h, $m2, $s);
    return sprintf("%d:%02d", $m2, $s);
}

function cacheTrendingVideos($videos, $regionCode) {
    $db = getDB();
    $db->prepare("DELETE FROM trending_videos WHERE region_code = ? AND fetched_at < DATE_SUB(NOW(), INTERVAL 1 HOUR)")->execute([$regionCode]);
    $stmt = $db->prepare("INSERT INTO trending_videos (video_id, title, channel_name, channel_id, thumbnail_url, view_count, like_count, comment_count, duration, category_id, region_code, published_at, rank_position) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE view_count=VALUES(view_count), rank_position=VALUES(rank_position), fetched_at=NOW()");
    foreach ($videos as $v) {
        $stmt->execute([$v['video_id'], $v['title'], $v['channel_name'], $v['channel_id'], $v['thumbnail'], $v['view_count'], $v['like_count'], $v['comment_count'], $v['duration'], $v['category_id'], $regionCode, $v['published_at'], $v['rank']]);
    }
}

// ============================================================
// api/auth.php - User Authentication
// ============================================================

function registerUser($username, $email, $password) {
    $db = getDB();
    $hash = password_hash($password, PASSWORD_BCRYPT);
    try {
        $stmt = $db->prepare("INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)");
        $stmt->execute([$username, $email, $hash]);
        return ['success' => true, 'user_id' => $db->lastInsertId()];
    } catch (PDOException $e) {
        if ($e->getCode() == 23000) return ['error' => 'Username or email already exists'];
        return ['error' => 'Registration failed'];
    }
}

function loginUser($email, $password) {
    $db = getDB();
    $stmt = $db->prepare("SELECT * FROM users WHERE email = ? AND is_active = 1");
    $stmt->execute([$email]);
    $user = $stmt->fetch();
    if (!$user || !password_verify($password, $user['password_hash'])) {
        return ['error' => 'Invalid email or password'];
    }
    $token = bin2hex(random_bytes(32));
    $expires = date('Y-m-d H:i:s', strtotime('+7 days'));
    $db->prepare("INSERT INTO user_sessions (user_id, session_token, expires_at) VALUES (?,?,?)")->execute([$user['id'], $token, $expires]);
    $db->prepare("UPDATE users SET last_login = NOW() WHERE id = ?")->execute([$user['id']]);
    unset($user['password_hash']);
    return ['success' => true, 'token' => $token, 'user' => $user];
}

function validateSession($token) {
    $db = getDB();
    $stmt = $db->prepare("SELECT u.* FROM users u JOIN user_sessions s ON u.id = s.user_id WHERE s.session_token = ? AND s.expires_at > NOW() AND u.is_active = 1");
    $stmt->execute([$token]);
    return $stmt->fetch();
}

// API Router
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

$action = $_GET['action'] ?? $_POST['action'] ?? '';

switch ($action) {
    case 'trending':
        $region = strtoupper($_GET['region'] ?? 'US');
        $cat    = $_GET['category'] ?? '';
        echo json_encode(getTrendingVideos($region, $cat));
        break;

    case 'register':
        $data = json_decode(file_get_contents('php://input'), true);
        echo json_encode(registerUser($data['username'], $data['email'], $data['password']));
        break;

    case 'login':
        $data = json_decode(file_get_contents('php://input'), true);
        echo json_encode(loginUser($data['email'], $data['password']));
        break;

    case 'validate':
        $token = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
        $token = str_replace('Bearer ', '', $token);
        $user  = validateSession($token);
        echo json_encode($user ? ['valid' => true, 'user' => $user] : ['valid' => false]);
        break;

    case 'categories':
        $db   = getDB();
        $cats = $db->query("SELECT * FROM categories ORDER BY name")->fetchAll();
        echo json_encode($cats);
        break;

    case 'regions':
        $db      = getDB();
        $regions = $db->query("SELECT * FROM regions ORDER BY name")->fetchAll();
        echo json_encode($regions);
        break;

    default:
        echo json_encode(['error' => 'Unknown action']);
}
?>
