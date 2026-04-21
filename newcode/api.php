<?php
header('Content-Type: application/json');

$mysqli = new mysqli("localhost", "root", "", "sushi");
if ($mysqli->connect_errno) {
    echo json_encode(["error" => "DB connection failed"]);
    exit;
}

$action = $_GET['action'] ?? '';
$input = json_decode(file_get_contents("php://input"), true) ?? [];

function runProcedure($mysqli, $proc, $params = []) {
    $placeholders = implode(',', array_fill(0, count($params), '?'));
    $stmt = $mysqli->prepare("CALL $proc($placeholders)");
    if ($params) {
        $types = str_repeat('s', count($params));
        $stmt->bind_param($types, ...$params);
    }
    $stmt->execute();
    $result = $stmt->get_result();
    $rows = $result ? $result->fetch_all(MYSQLI_ASSOC) : [];
    $stmt->close();
    while ($mysqli->more_results()) { $mysqli->next_result(); }
    return $rows;
}

switch ($action) {

    case "list_events":
        echo json_encode(runProcedure($mysqli, "sp_list_events"));
        break;

    case "get_event":
        echo json_encode(runProcedure($mysqli, "sp_get_event", [
            $_GET['event_id'] ?? 0
        ]));
        break;

    case "list_participants":
        echo json_encode(runProcedure($mysqli, "sp_list_participants", [
            $_GET['event_id'] ?? 0
        ]));
        break;

    case "add_participant":
        echo json_encode(runProcedure($mysqli, "sp_add_participant", [
            $input['event_id'] ?? 0,
            $input['name'] ?? ''
        ]));
        break;

    case "increment_plate":
        echo json_encode(runProcedure($mysqli, "sp_increment_plate", [
            $input['participant_id'] ?? 0,
            $input['plate_type'] ?? ''
        ]));
        break;

    case "get_totals":
        echo json_encode(runProcedure($mysqli, "sp_get_totals_for_event", [
            $_GET['event_id'] ?? 0
        ]));
        break;

    default:
        echo json_encode(["error" => "Unknown action"]);
}
