<?php
require_once 'db.php';
    if (!isset($_GET['comic_id'])) {
        echo json_encode([
            "status" => "error",
            "message" => "Parameter 'id' komik diperlukan."
        ]);
        exit();
    }

$comic_id = $_GET['comic_id'];

$query_comic = "SELECT c.id, c.title, c.description, c.poster, c.users_id,
                       COALESCE(AVG(r.rate), 0) as average_rating,
                       COUNT(r.rate) as total_rating_users
                FROM comics c
                LEFT JOIN rating r ON c.id = r.comics_id
                WHERE c.id = ?
                GROUP BY c.id";

$stmt_comic = $conn->prepare($query_comic);
$stmt_comic->bind_param("i", $comic_id);
$stmt_comic->execute();
$res_comic = $stmt_comic->get_result();

if ($res_comic->num_rows === 0) {
    echo json_encode(["status" => "error", "message" => "Komik tidak ditemukan."]);
    $stmt_comic->close();
    exit();
}
$comic_data = $res_comic->fetch_assoc();
$stmt_comic->close();

$query_cats = "SELECT cat.id, cat.nama FROM categories cat
               INNER JOIN comics_has_categories chc ON cat.id = chc.categories_id
               WHERE chc.comics_id = ?";
$stmt_cats = $conn->prepare($query_cats);
$stmt_cats->bind_param("i", $comic_id);
$stmt_cats->execute();
$res_cats = $stmt_cats->get_result();
$category_names = [];
$category_ids = [];
while($row = $res_cats->fetch_assoc()) {
    $category_names[] = $row['nama'];
    $category_ids[] = intval($row['id']);
}
$stmt_cats->close();

$query_chapters = "SELECT id, chapter FROM chapters WHERE comics_id = ? ORDER BY chapter ASC";
$stmt_chapters = $conn->prepare($query_chapters);
$stmt_chapters->bind_param("i", $comic_id);
$stmt_chapters->execute();
$res_chapters = $stmt_chapters->get_result();
$chapters = [];
while ($row = $res_chapters->fetch_assoc()) {
    $chapters[] = ["id" => intval($row['id']), "chapter" => intval($row['chapter'])];
}
$stmt_chapters->close();

$query_comments = "SELECT c.id, c.comment, u.username, u.profile_pic
                   FROM comments c
                   INNER JOIN users u ON c.users_id = u.id
                   WHERE c.comics_id = ?
                   ORDER BY c.id DESC";
$stmt_comments = $conn->prepare($query_comments);
$stmt_comments->bind_param("i", $comic_id);
$stmt_comments->execute();
$res_comments = $stmt_comments->get_result();
$comments = [];
while ($row = $res_comments->fetch_assoc()) {
    $comments[] = [
        "id" => intval($row['id']),
        "comment" => $row['comment'],
        "username" => $row['username'],
        "profile_pic" => $row['profile_pic']
    ];
}
$stmt_comments->close();

echo json_encode([
    "status" => "success",
    "data" => [
        "comic" => [
            "id" => intval($comic_data['id']),
            "title" => $comic_data['title'],
            "description" => $comic_data['description'],
            "poster" => $comic_data['poster'],
            "users_id" => $comic_data['users_id'] !== null ? intval($comic_data['users_id']) : null,
            "categories" => implode(", ", $category_names),
            "category_ids" => $category_ids,
            "average_rating" => round(floatval($comic_data['average_rating']), 1),
            "total_ratings" => intval($comic_data['total_rating_users'])
        ],
        "chapters" => $chapters,
        "comments" => $comments
    ]
]);
?>