<?php 
require_once 'db.php';

$user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
$username = isset($_POST['username']) ? trim($_POST['username']) : '';
$profile_pic = isset($_POST['profile_pic']) ? $_POST['profile_pic'] : '';

if ($user_id == 0 || $username == '') {
    echo json_encode(["status" => "error", "message" => "Data tidak lengkap."]);
    exit();
}

$stmt = $conn->prepare("SELECT id FROM users WHERE username = ? AND id != ?");
$stmt->bind_param("si", $username, $user_id);
$stmt->execute();
$res = $stmt->get_result();
$stmt->close();
if ($res->num_rows > 0) {
    echo json_encode(["status" => "error", "message" => "Username sudah dipakai user lain."]);
    exit();
}

$stmt = $conn->prepare("SELECT profile_pic FROM users WHERE id = ?");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$old = $stmt->get_result()->fetch_assoc();
$stmt->close();
$finalPic = $old['profile_pic'];

if ($profile_pic != '') {
    $dir = "images/profile_pic";
    if (!is_dir($dir)) {
        mkdir($dir, 0777, true);
    }
    $newPath = $dir . "/" . $user_id . "_" . time() . ".png";
    file_put_contents($newPath, base64_decode($profile_pic));

    $oldPic = $old['profile_pic'];
    if ($oldPic != '' && $oldPic != $newPath && strpos($oldPic, 'images/') === 0 && file_exists($oldPic)) {
        unlink($oldPic);
    }
    $finalPic = $newPath;
}

$stmt = $conn->prepare("UPDATE users SET username = ?, profile_pic = ? WHERE id = ?");
$stmt->bind_param("ssi", $username, $finalPic, $user_id);
$stmt->execute();
$stmt->close();

echo json_encode([
    "status" => "success",
    "message" => "Profil berhasil diperbarui!",
    "data" => ["username" => $username, "profile_pic" => $finalPic]
]);
$conn->close();
?>