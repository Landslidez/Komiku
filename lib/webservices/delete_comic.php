<?php 
require_once 'db.php';

$comic_id = isset($_POST['comic_id']) ? intval($_POST['comic_id']) : 0;
$user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;

if ($comic_id == 0) {
    echo json_encode(["status" => "error", "message" => "Komik tidak valid."]);
    exit();
}

$stmt = $conn->prepare("SELECT users_id FROM comics WHERE id = ?");
$stmt->bind_param("i", $comic_id);
$stmt->execute();
$result = $stmt->get_result();
$stmt->close();

if ($result->num_rows == 0) {
    echo json_encode(["status" => "error", "message" => "Komik tidak ditemukan."]);
    exit();
}

$row = $result->fetch_assoc();
if ($row['users_id'] === null || intval($row['users_id']) !== $user_id) {
    echo json_encode(["status" => "error", "message" => "Anda hanya bisa menghapus komik buatan sendiri."]);
    exit();
}

$stmt = $conn->prepare("DELETE FROM pages WHERE chapters_id IN (SELECT id FROM chapters WHERE comics_id = ?)");
$stmt->bind_param("i", $comic_id);
$stmt->execute();
$stmt->close();

foreach (["chapters", "comics_has_categories", "rating", "comments"] as $tbl) {
    $stmt = $conn->prepare("DELETE FROM $tbl WHERE comics_id = ?");
    $stmt->bind_param("i", $comic_id);
    $stmt->execute();
    $stmt->close();
}

$stmt = $conn->prepare("DELETE FROM comics WHERE id = ?");
$stmt->bind_param("i", $comic_id);
$stmt->execute();
$stmt->close();

echo json_encode(["status" => "success", "message" => "Komik berhasil dihapus."]);
$conn->close();
?>