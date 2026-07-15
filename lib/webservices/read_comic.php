<?php 
require_once 'db.php';

if (!isset($_GET['chapter_id'])) {
    echo json_encode(["status" => "error", "message" => "Parameter 'chapter_id' diperlukan."]);
    exit();
}

$chapter_id = intval($_GET['chapter_id']);

$query = "SELECT id, page FROM pages WHERE chapters_id = ? ORDER BY id ASC";
$stmt = $conn->prepare($query);
$stmt->bind_param("i", $chapter_id);
$stmt->execute();
$result = $stmt->get_result();

$pages = [];
while ($row = $result->fetch_assoc()) {
    $pages[] = [
        "id" => intval($row['id']),
        "page" => $row['page']
    ];
}

echo json_encode([
    "status" => "success",
    "data" => $pages
]);

$stmt->close();
$conn->close();
?>