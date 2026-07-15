<?php
require_once 'db.php';

if (isset($_GET['category_id']) && !empty($_GET['category_id'])) {
    $category_id = intval($_GET['category_id']);

    $query = "SELECT c.id, c.title, c.description, c.poster,
                     COALESCE(AVG(r.rate), 0) as average_rating
              FROM comics c
              INNER JOIN comics_has_categories chc ON c.id = chc.comics_id
              LEFT JOIN rating r ON c.id = r.comics_id
              WHERE chc.categories_id = ?
              GROUP BY c.id";

    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $category_id);

    if ($stmt->execute()) {
        $result = $stmt->get_result();
        $comics = [];
        while ($row = $result->fetch_assoc()) {
            $row['average_rating'] = round(floatval($row['average_rating']), 1);
            $comics[] = $row;
        }
        echo json_encode(["status" => "success", "data" => $comics]);
    } else {
        echo json_encode(["status" => "error", "message" => "Gagal mengeksekusi query ke database."]);
    }

    $stmt->close();
} else {
    echo json_encode(["status" => "error", "message" => "Parameter 'category_id' tidak ditemukan atau kosong."]);
}

$conn->close();
?>