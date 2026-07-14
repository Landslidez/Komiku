<?php
require_once 'db.php';

$username = isset($_POST['username']) ? $_POST['username'] : null;
$password = isset($_POST['password']) ? $_POST['password'] : null;

if (!$username || !$password) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Username dan Password harus diisi."]);
    exit();
}

$stmt = $conn->prepare("SELECT id, username, profile_pic FROM users WHERE username = ? AND password = ?");
$stmt->bind_param("ss", $username, $password);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();
    echo json_encode([
        "status" => "success",
        "message" => "Login berhasil!",
        "data" => [
            "id" => $user['id'],
            "username" => $user['username'],
            "profile_pic" => $user['profile_pic']
        ]
    ]);
} else {
    echo json_encode(["status" => "error", "message" => "Username atau password salah."]);
}
$stmt->close();
?>