<?php //menampilkan semua komik yang ada di database
require_once 'db.php';

$query = "SELECT c.id, c.title, c.description, c.poster FROM comics c";
$stmt = $conn->prepare($query);
$stmt->execute();
$result = $stmt->get_result();

$comics = [];
while ($row = $result->fetch_assoc()) {
    $comics[] = $row;
}

echo json_encode([
    "status" => "success",
    "data" => $comics
]);
$stmt->close();

?>