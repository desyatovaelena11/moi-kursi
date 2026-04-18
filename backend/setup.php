<?php
/**
 * Moi-Kursi Setup Script
 * Auto-detects domain and initializes database
 */

// Get current domain from request
$protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http';
$domain = $_SERVER['HTTP_HOST'];
$base_path = str_replace('/backend/setup.php', '', $_SERVER['REQUEST_URI']);
if ($base_path === '') {
    $base_path = '/';
}

// Extract subdomain
$domain_clean = explode(':', $domain)[0];

// Build URLs
$api_url = $protocol . '://' . $domain_clean . $base_path . 'backend/api/v1';
$frontend_url = $protocol . '://' . $domain_clean . $base_path;

echo "<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'>
    <title>Moi-Kursi Setup</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #1a1a1a; color: #fff; }
        .container { max-width: 800px; margin: 0 auto; background: #2a2a2a; padding: 30px; border-radius: 8px; border-left: 4px solid #ff9900; }
        h1 { color: #ff9900; }
        .success { background: #1a3a1a; padding: 15px; border-radius: 4px; margin: 20px 0; color: #4ade80; border-left: 3px solid #4ade80; }
        .error { background: #3a1a1a; padding: 15px; border-radius: 4px; margin: 20px 0; color: #ef4444; border-left: 3px solid #ef4444; }
        .info { background: #1a2a3a; padding: 15px; border-radius: 4px; margin: 20px 0; color: #60a5fa; border-left: 3px solid #60a5fa; }
        pre { background: #1a1a1a; padding: 15px; border-radius: 4px; overflow-x: auto; color: #4ade80; border: 1px solid #444; }
        code { color: #ff9900; }
        hr { margin: 30px 0; border: 1px solid #444; }
    </style>
</head>
<body>
    <div class='container'>
        <h1>🚀 Moi-Kursi Setup</h1>";

// Step 1: Check .env exists
echo "<h2>Step 1: Checking .env file</h2>";
$env_file = '../.env';
if (!file_exists($env_file)) {
    echo "<div class='error'>✗ .env file not found at " . realpath($env_file) . "</div>";
    echo "<p>This file should have been uploaded. Please upload .env to the root directory.</p>";
    exit;
}
echo "<div class='success'>✓ .env file found</div>";

// Step 2: Update .env with correct URLs
echo "<h2>Step 2: Updating .env with correct domain</h2>";
$env_content = file_get_contents($env_file);

// Update API_BASE_URL
$env_content = preg_replace(
    '/API_BASE_URL=.*/i',
    'API_BASE_URL=' . $api_url,
    $env_content
);

// Update FRONTEND_BASE_URL
$env_content = preg_replace(
    '/FRONTEND_BASE_URL=.*/i',
    'FRONTEND_BASE_URL=' . $frontend_url,
    $env_content
);

// Write updated .env
if (file_put_contents($env_file, $env_content)) {
    echo "<div class='success'>✓ .env updated with correct URLs</div>";
    echo "<div class='info'>";
    echo "API: <code>" . $api_url . "</code><br>";
    echo "Frontend: <code>" . $frontend_url . "</code>";
    echo "</div>";
} else {
    echo "<div class='error'>✗ Could not write to .env file. Check file permissions.</div>";
    exit;
}

// Step 3: Parse .env and validate config
echo "<h2>Step 3: Validating database configuration</h2>";

function parse_env_file($filename) {
    $env = [];
    if (!file_exists($filename)) return $env;
    $lines = file($filename, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos(trim($line), '#') === 0) continue;
        if (strpos($line, '=') !== false) {
            list($key, $value) = explode('=', $line, 2);
            $key = trim($key);
            $value = trim($value);
            $value = trim($value, "\"'");
            $env[$key] = $value;
        }
    }
    return $env;
}

$env = parse_env_file($env_file);
$required = ['DB_HOST', 'DB_USER', 'DB_PASS', 'DB_NAME'];
$missing = [];

foreach ($required as $key) {
    if (empty($env[$key])) {
        $missing[] = $key;
    }
}

if (!empty($missing)) {
    echo "<div class='error'>✗ Missing config: " . implode(', ', $missing) . "</div>";
    exit;
}

echo "<div class='success'>✓ Configuration is valid</div>";
echo "<div class='info'>";
echo "DB Host: <code>" . $env['DB_HOST'] . "</code><br>";
echo "DB Name: <code>" . $env['DB_NAME'] . "</code><br>";
echo "DB User: <code>" . $env['DB_USER'] . "</code>";
echo "</div>";

// Step 4: Test database connection
echo "<h2>Step 4: Testing database connection</h2>";
$mysqli = new mysqli($env['DB_HOST'], $env['DB_USER'], $env['DB_PASS']);

if ($mysqli->connect_error) {
    echo "<div class='error'>✗ Database connection failed: " . $mysqli->connect_error . "</div>";
    echo "<p>This might mean:</p>";
    echo "<ul>";
    echo "<li>Database server is not running</li>";
    echo "<li>Credentials in .env are incorrect</li>";
    echo "<li>Database doesn't exist yet</li>";
    echo "</ul>";
    exit;
}

$mysqli->set_charset('utf8mb4');
echo "<div class='success'>✓ Successfully connected to MySQL</div>";

// Step 5: Create database
echo "<h2>Step 5: Creating database</h2>";
$db_name = $env['DB_NAME'];
$create_db = "CREATE DATABASE IF NOT EXISTS `" . $mysqli->real_escape_string($db_name) . "` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci";

if ($mysqli->query($create_db)) {
    echo "<div class='success'>✓ Database <code>$db_name</code> exists</div>";
} else {
    echo "<div class='error'>✗ Error creating database: " . $mysqli->error . "</div>";
    exit;
}

// Select database
if (!$mysqli->select_db($db_name)) {
    echo "<div class='error'>✗ Could not select database: " . $mysqli->error . "</div>";
    exit;
}

// Step 6: Create user
echo "<h2>Step 6: Setting up database user</h2>";
$db_user = $env['DB_USER'];
$db_pass = $env['DB_PASS'];

// Try to create user (might already exist, that's ok)
@$mysqli->query("CREATE USER IF NOT EXISTS '" . $mysqli->real_escape_string($db_user) . "'@'localhost' IDENTIFIED BY '" . $mysqli->real_escape_string($db_pass) . "'");
@$mysqli->query("GRANT ALL PRIVILEGES ON `" . $mysqli->real_escape_string($db_name) . "`.* TO '" . $mysqli->real_escape_string($db_user) . "'@'localhost'");
@$mysqli->query("FLUSH PRIVILEGES");

echo "<div class='success'>✓ Database user <code>$db_user</code> configured</div>";

// Step 7: Create tables
echo "<h2>Step 7: Creating tables</h2>";

// Load SQL file
$sql_file = '../docs/DATABASE.sql';
if (!file_exists($sql_file)) {
    echo "<div class='error'>✗ DATABASE.sql not found at: " . realpath($sql_file) . "</div>";
    exit;
}

$sql_content = file_get_contents($sql_file);
$statements = array_filter(
    array_map('trim', preg_split('/;/', $sql_content)),
    function($stmt) {
        return !empty($stmt) && strpos($stmt, '--') !== 0;
    }
);

$success_count = 0;
foreach ($statements as $statement) {
    if (empty(trim($statement))) continue;

    if ($mysqli->query($statement)) {
        $success_count++;
    } else {
        // Ignore "already exists" errors
        if (strpos($mysqli->error, 'already exists') === false) {
            echo "<div class='error'>⚠️ Error: " . $mysqli->error . "</div>";
        }
    }
}

echo "<div class='success'>✓ Database tables created/updated ($success_count operations)</div>";

// Step 8: Verify tables
echo "<h2>Step 8: Verifying tables</h2>";
$tables = ['courses', 'sections', 'lessons'];
$all_ok = true;

foreach ($tables as $table) {
    $result = $mysqli->query("SHOW TABLES LIKE '$table'");
    if ($result && $result->num_rows > 0) {
        echo "<div class='success'>✓ Table <code>$table</code> exists</div>";
    } else {
        echo "<div class='error'>✗ Table <code>$table</code> not found</div>";
        $all_ok = false;
    }
}

// Final status
echo "<hr>";
if ($all_ok) {
    echo "<h2>✅ Setup Complete!</h2>";
    echo "<div class='success'>";
    echo "<p><strong>Your platform is ready!</strong></p>";
    echo "<p>Access your platform at:</p>";
    echo "<div style='font-size: 18px; margin: 20px 0;'>";
    echo "<a href='" . htmlspecialchars($frontend_url) . "' style='color: #ff9900; text-decoration: none;'>" . htmlspecialchars($frontend_url) . "</a>";
    echo "</div>";
    echo "</div>";

    echo "<h3>Next Steps:</h3>";
    echo "<ol>";
    echo "<li>Test the API: <a href='" . htmlspecialchars($api_url) . "/courses' style='color: #60a5fa;'>" . htmlspecialchars($api_url) . "/courses</a></li>";
    echo "<li>Upload videos to Mail.ru Cloud</li>";
    echo "<li>Add courses via API or admin panel</li>";
    echo "</ol>";
} else {
    echo "<h2>⚠️ Setup Incomplete</h2>";
    echo "<div class='error'><p>Some tables are missing. Please check the DATABASE.sql file.</p></div>";
}

echo "<hr>";
echo "<p><small>🔒 This setup script can be deleted after initialization:</small></p>";
echo "<pre>rm backend/setup.php</pre>";

$mysqli->close();

echo "    </div>
</body>
</html>";
?>
