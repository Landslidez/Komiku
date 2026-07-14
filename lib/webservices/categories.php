<?php //ambil semua kategori
require_once 'db.php';

$sql = "SELECT id, nama FROM categories";
$result = $conn->query($sql);

$categories = [];
while ($row = $result->fetch_assoc()) {
    $categories[] = $row;
}

echo json_encode([
    "status" => "success",
    "data" => $categories
]);

?>