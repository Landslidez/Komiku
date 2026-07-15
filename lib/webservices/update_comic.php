<?php
require_once 'db.php';

$comic_id = isset($_POST['comic_id']) ? intval($_POST['comic_id']) : 0;
$user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
$title = isset($_POST['title']) ? $_POST['title'] : '';
$description = isset($_POST['description']) ? $_POST['description'] : '';
$categories = isset($_POST['categories']) ? $_POST['categories'] : '';
$poster = isset($_POST['poster']) ? $_POST['poster'] : '';

if ($comic_id == 0 || $title == '') {
    echo json_encode(["status" => "error", "message" => "Data tidak lengkap."]);
    exit();
}

$stmt = $conn->prepare("SELECT users_id, poster FROM comics WHERE id = ?");
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
    echo json_encode(["status" => "error", "message" => "Anda hanya bisa mengedit komik buatan sendiri."]);
    exit();
}

$stmt = $conn->prepare("UPDATE comics SET title = ?, description = ? WHERE id = ?");
$stmt->bind_param("ssi", $title, $description, $comic_id);
$stmt->execute();
$stmt->close();

if ($poster != '') {
    $dir = "images/poster";
    if (!is_dir($dir)) {
        mkdir($dir, 0777, true);
    }
    $newPath = $dir . "/" . $comic_id . "_" . time() . ".png";
    file_put_contents($newPath, base64_decode($poster));

    $stmt = $conn->prepare("UPDATE comics SET poster = ? WHERE id = ?");
    $stmt->bind_param("si", $newPath, $comic_id);
    $stmt->execute();
    $stmt->close();

    $oldPoster = $row['poster'];
    if ($oldPoster != '' && $oldPoster != $newPath && strpos($oldPoster, 'images/') === 0 && file_exists($oldPoster)) {
        unlink($oldPoster);
    }
}

$stmt = $conn->prepare("DELETE FROM comics_has_categories WHERE comics_id = ?");
$stmt->bind_param("i", $comic_id);
$stmt->execute();
$stmt->close();

foreach (array_filter(explode(",", $categories)) as $cat) {
    $cat_id = intval($cat);
    $stmt = $conn->prepare("INSERT INTO comics_has_categories (comics_id, categories_id) VALUES (?, ?)");
    $stmt->bind_param("ii", $comic_id, $cat_id);
    $stmt->execute();
    $stmt->close();
}

echo json_encode(["status" => "success", "message" => "Komik berhasil diperbarui!"]);
$conn->close();
?>