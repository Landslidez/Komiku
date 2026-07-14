<?php
header("Content-Type: application/json");
require_once 'db.php';

$action = $_POST['action'];
$comic_id = $_POST['comic_id'];
$user_id = $_POST['user_id'];

if ($action === 'rate') {
    $rate = $_POST['rate'];
    $check = $conn->prepare("SELECT rate FROM rating WHERE comics_id = ? AND users_id = ?");
    $check->bind_param("ii", $comic_id, $user_id);
    $check->execute();
    $res = $check->get_result();
    
    if ($res->num_rows > 0) {
        $stmt = $conn->prepare("UPDATE rating SET rate = ? WHERE comics_id = ? AND users_id = ?");
        $stmt->bind_param("iii", $rate, $comic_id, $user_id);
    } else {
        $stmt = $conn->prepare("INSERT INTO rating (rate, comics_id, users_id) VALUES (?, ?, ?)");
        $stmt->bind_param("iii", $rate, $comic_id, $user_id);
    }
    
    if ($stmt->execute()) {
        echo json_encode(["status" => "success", "message" => "Rating berhasil dikirim!"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Gagal menyimpan rating."]);
    }
    
    $stmt->close();
    $check->close();
} 
else if ($action === 'comment') {
    $comment = $_POST['comment'];
    
    if (empty($comment)) {
        echo json_encode(["status" => "error", "message" => "Komentar tidak boleh kosong."]);
        exit();
    }
    
    $stmt = $conn->prepare("INSERT INTO comments (comment, comics_id, users_id) VALUES (?, ?, ?)");
    $stmt->bind_param("sii", $comment, $comic_id, $user_id);
    
    if ($stmt->execute()) {
        echo json_encode(["status" => "success", "message" => "Komentar berhasil ditambahkan!"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Gagal menambahkan komentar."]);
    }
    $stmt->close();
} else {
    echo json_encode(["status" => "error", "message" => "Aksi tidak dikenali."]);
}

$conn->close();
?>