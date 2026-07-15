<?php
require_once 'db.php';

$title = isset($_POST['title']) ? $_POST['title'] : '';
$description = isset($_POST['description']) ? $_POST['description'] : '';
$categories = isset($_POST['categories']) ? $_POST['categories'] : '';
$poster = isset($_POST['poster']) ? $_POST['poster'] : '';
$user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;

if ($title == '' || $poster == '') {
    echo json_encode(["status" => "error", "message" => "Judul dan poster harus diisi."]);
    exit();
}

$stmt = $conn->prepare("INSERT INTO comics (title, description, poster, users_id) VALUES (?, ?, '', ?)");
$stmt->bind_param("ssi", $title, $description, $user_id);
$stmt->execute();
$comic_id = $conn->insert_id;
$stmt->close();

$dir = "images/poster";
if (!is_dir($dir)) {
    mkdir($dir, 0777, true);
}
$path = $dir . "/" . $comic_id . ".png";
file_put_contents($path, base64_decode($poster));

$stmt = $conn->prepare("UPDATE comics SET poster = ? WHERE id = ?");
$stmt->bind_param("si", $path, $comic_id);
$stmt->execute();
$stmt->close();

foreach (array_filter(explode(",", $categories)) as $cat) {
    $cat_id = intval($cat);
    $stmt = $conn->prepare("INSERT INTO comics_has_categories (comics_id, categories_id) VALUES (?, ?)");
    $stmt->bind_param("ii", $comic_id, $cat_id);
    $stmt->execute();
    $stmt->close();
}

$chapter = 1;
$stmt = $conn->prepare("INSERT INTO chapters (comics_id, chapter) VALUES (?, ?)");
$stmt->bind_param("ii", $comic_id, $chapter);
$stmt->execute();
$chapter_id = $conn->insert_id;
$stmt->close();

echo json_encode([
    "status" => "success",
    "message" => "Komik berhasil dibuat!",
    "data" => ["comic_id" => $comic_id, "chapter_id" => $chapter_id]
]);
$conn->close();
?>