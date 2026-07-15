<?php 
require_once 'db.php';

$chapter_id = isset($_POST['chapter_id']) ? intval($_POST['chapter_id']) : 0;
$page = isset($_POST['page']) ? $_POST['page'] : '';
$image = isset($_POST['image']) ? $_POST['image'] : '';

if ($chapter_id == 0 || $image == '') {
    echo json_encode(["status" => "error", "message" => "Data halaman tidak lengkap."]);
    exit();
}

$dir = "images/komik/" . $chapter_id;
if (!is_dir($dir)) {
    mkdir($dir, 0777, true);
}
$path = $dir . "/" . $page . ".png";
file_put_contents($path, base64_decode($image));

$stmt = $conn->prepare("INSERT INTO pages (page, chapters_id) VALUES (?, ?)");
$stmt->bind_param("si", $path, $chapter_id);
$stmt->execute();

if ($stmt->affected_rows > 0) {
    echo json_encode(["status" => "success", "message" => "Halaman ditambahkan."]);
} else {
    echo json_encode(["status" => "error", "message" => "Gagal menyimpan halaman."]);
}
$stmt->close();
$conn->close();
?>