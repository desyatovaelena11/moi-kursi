<?php
/**
 * Installation Script for Moi-Kursi
 *
 * Usage:
 * 1. Copy .env.example to .env and fill with your credentials
 * 2. Upload this file to Beget
 * 3. Visit: https://yourdomain.ru/backend/install.php
 * 4. Follow the instructions
 */

// Disable output buffering
if (ob_get_level()) ob_end_clean();

echo "<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'>
    <title>Moi-Kursi Installation</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; }
        h1 { color: #0066cc; }
        .success { background: #d4edda; padding: 15px; border-radius: 4px; margin: 20px 0; color: #155724; }
        .error { background: #f8d7da; padding: 15px; border-radius: 4px; margin: 20px 0; color: #721c24; }
        .info { background: #d1ecf1; padding: 15px; border-radius: 4px; margin: 20px 0; color: #0c5460; }
        pre { background: #f8f9fa; padding: 15px; border-radius: 4px; overflow-x: auto; }
        code { color: #d63384; }
        hr { margin: 30px 0; }
    </style>
</head>
<body>
    <div class='container'>
        <h1>📚 Moi-Kursi Installation</h1>";

// 1. Check .env file
echo "<h2>Step 1: Checking .env file</h2>";
if (file_exists('../.env')) {
    echo "<div class='success'>✓ .env file found</div>";
    $env = parse_env_file('../.env');
} else {
    echo "<div class='error'>✗ .env file not found</div>";
    echo "<p>Please create .env file from .env.example and fill with your credentials:</p>";
    echo "<pre>" . file_get_contents('../.env.example') . "</pre>";
    exit;
}

// 2. Validate .env
echo "<h2>Step 2: Validating configuration</h2>";
$required_keys = ['DB_HOST', 'DB_USER', 'DB_PASS', 'DB_NAME'];
$missing_keys = [];

foreach ($required_keys as $key) {
    if (empty($env[$key])) {
        $missing_keys[] = $key;
    }
}

if (!empty($missing_keys)) {
    echo "<div class='error'>✗ Missing configuration keys: " . implode(', ', $missing_keys) . "</div>";
    exit;
}

echo "<div class='success'>✓ Configuration is valid</div>";
echo "<div class='info'>";
echo "DB Host: {$env['DB_HOST']}<br>";
echo "DB Name: {$env['DB_NAME']}<br>";
echo "DB User: {$env['DB_USER']}<br>";
echo "</div>";

// 3. Test Database Connection
echo "<h2>Step 3: Testing Database Connection</h2>";
$mysqli = new mysqli($env['DB_HOST'], $env['DB_USER'], $env['DB_PASS'], $env['DB_NAME']);

if ($mysqli->connect_error) {
    echo "<div class='error'>✗ Database connection failed: " . $mysqli->connect_error . "</div>";
    exit;
}

$mysqli->set_charset('utf8mb4');
echo "<div class='success'>✓ Successfully connected to database</div>";

// 4. Create Tables
echo "<h2>Step 4: Creating Tables</h2>";

$sql_file = file_get_contents('../docs/DATABASE.sql');
// Remove comments and split by semicolon
$statements = array_filter(
    array_map('trim', preg_split('/;/', $sql_file)),
    function($stmt) {
        return !empty($stmt) && strpos($stmt, '--') !== 0;
    }
);

$success_count = 0;
$error_count = 0;

foreach ($statements as $statement) {
    if (empty(trim($statement))) continue;

    if (!$mysqli->query($statement)) {
        if (strpos($mysqli->error, 'already exists') === false) {
            echo "<div class='error'>Error: " . $mysqli->error . "</div>";
            $error_count++;
        }
    } else {
        $success_count++;
    }
}

if ($error_count === 0) {
    echo "<div class='success'>✓ Database tables created successfully</div>";
} else {
    echo "<div class='error'>Some tables could not be created (they may already exist)</div>";
}

// 5. Verify Tables
echo "<h2>Step 5: Verifying Tables</h2>";
$tables = ['courses', 'sections', 'lessons'];
$all_exist = true;

foreach ($tables as $table) {
    $result = $mysqli->query("SHOW TABLES LIKE '$table'");
    if ($result->num_rows > 0) {
        echo "<div class='success'>✓ Table '$table' exists</div>";
    } else {
        echo "<div class='error'>✗ Table '$table' not found</div>";
        $all_exist = false;
    }
}

// 6. Test API
echo "<h2>Step 6: Testing API</h2>";
echo "<p>Your API should be available at:</p>";
echo "<div class='info'><code>" . $env['API_BASE_URL'] . "/courses</code></div>";
echo "<p>Try opening this URL in your browser - you should see a JSON response with courses.</p>";

// 7. Next Steps
echo "<h2>Installation Complete! 🎉</h2>";
echo "<div class='success'>";
echo "<p><strong>Next Steps:</strong></p>";
echo "<ol>";
echo "<li>Upload your videos to Mail.ru Cloud</li>";
echo "<li>Get direct links to video files</li>";
echo "<li>Use the API to add courses, sections, and lessons with video URLs</li>";
echo "<li>Visit " . $env['FRONTEND_BASE_URL'] . " to access your platform</li>";
echo "</ol>";
echo "</div>";

echo "<hr>";
echo "<h3>Quick API Test</h3>";
echo "<pre>";
echo "# Get all courses\n";
echo "curl " . $env['API_BASE_URL'] . "/courses\n\n";
echo "# Create a course\n";
echo "curl -X POST " . $env['API_BASE_URL'] . "/courses \\\n";
echo "  -H 'Content-Type: application/json' \\\n";
echo "  -d '{\"name\":\"Test Course\",\"description\":\"Test\"}'\n";
echo "</pre>";

echo "<hr>";
echo "<p><small>Installation script can be deleted after setup: <code>rm backend/install.php</code></small></p>";
echo "    </div>
</body>
</html>";

// Helper function to parse .env file
function parse_env_file($filename) {
    $env = [];
    if (!file_exists($filename)) return $env;

    $lines = file($filename, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        // Skip comments
        if (strpos(trim($line), '#') === 0) continue;

        if (strpos($line, '=') !== false) {
            list($key, $value) = explode('=', $line, 2);
            $key = trim($key);
            $value = trim($value);
            // Remove quotes if present
            $value = trim($value, "\"'");
            $env[$key] = $value;
        }
    }
    return $env;
}

$mysqli->close();
?>
