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
$res = $stmt->get_result();
$stmt->close();

if ($res->num_rows == 0) {
    echo json_encode(["status" => "error", "message" => "Komik tidak ditemukan."]);
    exit();
}
$row = $res->fetch_assoc();
if ($row['users_id'] === null || intval($row['users_id']) !== $user_id) {
    echo json_encode(["status" => "error", "message" => "Anda hanya bisa menambah chapter di komik buatan sendiri."]);
    exit();
}

$stmt = $conn->prepare("SELECT COALESCE(MAX(chapter), 0) + 1 AS next_chapter FROM chapters WHERE comics_id = ?");
$stmt->bind_param("i", $comic_id);
$stmt->execute();
$r = $stmt->get_result()->fetch_assoc();
$next = intval($r['next_chapter']);
$stmt->close();

$stmt = $conn->prepare("INSERT INTO chapters (comics_id, chapter) VALUES (?, ?)");
$stmt->bind_param("ii", $comic_id, $next);
$stmt->execute();
$chapter_id = $conn->insert_id;
$stmt->close();

echo json_encode([
    "status" => "success",
    "message" => "Chapter dibuat.",
    "data" => ["chapter_id" => $chapter_id, "chapter" => $next]
]);
$conn->close();
?>