<?php //cari komik berdasar judul
require_once 'db.php';

$q = isset($_GET['q']) ? $_GET['q'] : '';
$keyword = "%" . $q . "%";

$query = "SELECT c.id, c.title, c.description, c.poster,
                 COALESCE(AVG(r.rate), 0) as average_rating
          FROM comics c
          LEFT JOIN rating r ON c.id = r.comics_id
          WHERE c.title LIKE ?
          GROUP BY c.id";
$stmt = $conn->prepare($query);
$stmt->bind_param("s", $keyword);
$stmt->execute();
$result = $stmt->get_result();

$comics = [];
while ($row = $result->fetch_assoc()) {
    $row['average_rating'] = round(floatval($row['average_rating']), 1);
    $comics[] = $row;
}

echo json_encode([
    "status" => "success",
    "data" => $comics
]);
$stmt->close();
$conn->close();
?>