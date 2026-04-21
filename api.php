<?php
// api.php
header('Content-Type: application/json');
require_once __DIR__ . '/config.php';

$pdo = db();
$action = $_GET['action'] ?? '';

function json_error($msg, $code = 400) {
    http_response_code($code);
    echo json_encode(['ok' => false, 'error' => $msg]);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true);
if (!is_array($input)) $input = [];

switch ($action) {
    // List Events
    case 'list_events':
        $stmt = $pdo->query("SELECT id, name, event_date FROM events ORDER BY event_date DESC, id DESC");
        echo json_encode(['ok' => true, 'events' => $stmt->fetchAll()]);
        break;

    // Create Events
    case 'create_event':
        $name = trim($input['name'] ?? '');
        $date = trim($input['event_date'] ?? '');
        if ($name === '' || $date === '') json_error('Missing name or date');
        $stmt = $pdo->prepare("INSERT INTO events (name, event_date) VALUES (?, ?)");
        $stmt->execute([$name, $date]);
        echo json_encode(['ok' => true, 'event_id' => $pdo->lastInsertId()]);
        break;

    // List Participants
    case 'list_participants':
        $stmt = $pdo->query("SELECT id, name FROM participants ORDER BY name");
        echo json_encode(['ok' => true, 'participants' => $stmt->fetchAll()]);
        break;

    // Set Particiipants for an Event
    case 'set_event_participants':
        $event_id = (int)($input['event_id'] ?? 0);
        $existing_ids = $input['participant_ids'] ?? [];
        $new_names = $input['new_names'] ?? [];
        if ($event_id <= 0) json_error('Invalid event');

        $pdo->beginTransaction();
        try {
            $created_ids = [];
            foreach ($new_names as $name) {
                $name = trim($name);
                if ($name === '') continue;
                $stmt = $pdo->prepare("INSERT IGNORE INTO participants (name) VALUES (?)");
                $stmt->execute([$name]);
                $stmt2 = $pdo->prepare("SELECT id FROM participants WHERE name = ?");
                $stmt2->execute([$name]);
                if ($row = $stmt2->fetch()) $created_ids[] = (int)$row['id'];
            }
            $all_ids = array_map('intval', array_merge($existing_ids, $created_ids));

            $stmt = $pdo->prepare("DELETE FROM event_participants WHERE event_id = ?");
            $stmt->execute([$event_id]);

            $stmt = $pdo->prepare("INSERT INTO event_participants (event_id, participant_id) VALUES (?, ?)");
            foreach ($all_ids as $pid) {
                $stmt->execute([$event_id, $pid]);
            }

            $pdo->commit();
            echo json_encode(['ok' => true, 'participant_ids' => $all_ids]);
        } catch (Exception $e) {
            $pdo->rollBack();
            json_error('DB error: ' . $e->getMessage(), 500);
        }
        break;

    // Event setup - whatever that is!?
    case 'get_event_setup':
        $event_id = (int)($_GET['event_id'] ?? 0);
        if ($event_id <= 0) json_error('Invalid event');

        $stmt = $pdo->prepare("
            SELECT p.id, p.name
            FROM event_participants ep
            JOIN participants p ON p.id = ep.participant_id
            WHERE ep.event_id = ?
            ORDER BY p.name
        ");
        $stmt->execute([$event_id]);
        $participants = $stmt->fetchAll();

        $stmt = $pdo->query("
            SELECT pc.id, pc.name, pc.display_order, pc.hex_colour, pc.active
            FROM plate_colours pc
            WHERE pc.active = 1
            ORDER BY pc.display_order, pc.name
        ");
        $colours = $stmt->fetchAll();

        $stmt = $pdo->prepare("
            SELECT plate_colour_id, unit_price
            FROM event_plate_prices
            WHERE event_id = ?
        ");
        $stmt->execute([$event_id]);
        $colour_prices = [];
        foreach ($stmt->fetchAll() as $row) {
            $colour_prices[$row['plate_colour_id']] = $row['unit_price'];
        }

        $stmt = $pdo->query("
            SELECT id, name, default_price
            FROM menu_items
            WHERE active = 1
            ORDER BY name
        ");
        $menu_items = $stmt->fetchAll();

        $stmt = $pdo->prepare("
            SELECT menu_item_id, unit_price
            FROM event_menu_prices
            WHERE event_id = ?
        ");
        $stmt->execute([$event_id]);
        $menu_prices = [];
        foreach ($stmt->fetchAll() as $row) {
            $menu_prices[$row['menu_item_id']] = $row['unit_price'];
        }

        echo json_encode([
            'ok' => true,
            'participants' => $participants,
            'colours' => $colours,
            'colour_prices' => $colour_prices,
            'menu_items' => $menu_items,
            'menu_prices' => $menu_prices,
        ]);
        break;

    // Save Prices
    case 'save_prices':
        $event_id = (int)($input['event_id'] ?? 0);
        if ($event_id <= 0) json_error('Invalid event');
        $colour_prices = $input['colour_prices'] ?? [];
        $menu_prices = $input['menu_prices'] ?? [];

        $pdo->beginTransaction();
        try {
            $stmtDel = $pdo->prepare("DELETE FROM event_plate_prices WHERE event_id = ?");
            $stmtDel->execute([$event_id]);

            $stmtIns = $pdo->prepare("
                INSERT INTO event_plate_prices (event_id, plate_colour_id, unit_price)
                VALUES (?, ?, ?)
            ");
            foreach ($colour_prices as $cid => $price) {
                $cid = (int)$cid;
                $price = (float)$price;
                if ($cid <= 0 || $price <= 0) continue;
                $stmtIns->execute([$event_id, $cid, $price]);
            }

            $stmtDel2 = $pdo->prepare("DELETE FROM event_menu_prices WHERE event_id = ?");
            $stmtDel2->execute([$event_id]);

            $stmtIns2 = $pdo->prepare("
                INSERT INTO event_menu_prices (event_id, menu_item_id, unit_price)
                VALUES (?, ?, ?)
            ");
            foreach ($menu_prices as $mid => $price) {
                $mid = (int)$mid;
                $price = (float)$price;
                if ($mid <= 0 || $price <= 0) continue;
                $stmtIns2->execute([$event_id, $mid, $price]);
            }

            $pdo->commit();
            echo json_encode(['ok' => true]);
        } catch (Exception $e) {
            $pdo->rollBack();
            json_error('DB error: ' . $e->getMessage(), 500);
        }
        break;

    // Increment a plate for a given user at a given event.
    case 'increment_plate':
        $event_id = (int)($input['event_id'] ?? 0);
        $participant_id = (int)($input['participant_id'] ?? 0);
        $plate_colour_id = (int)($input['plate_colour_id'] ?? 0);
        $delta = (int)($input['delta'] ?? 1);
        if ($event_id <= 0 || $participant_id <= 0 || $plate_colour_id <= 0) json_error('Invalid parameters');

        $pdo->beginTransaction();
        try {
            $stmt = $pdo->prepare("
                INSERT INTO plate_consumption (event_id, participant_id, plate_colour_id, quantity)
                VALUES (?, ?, ?, GREATEST(?,0))
                ON DUPLICATE KEY UPDATE quantity = GREATEST(quantity + VALUES(quantity), 0)
            ");
            $stmt->execute([$event_id, $participant_id, $plate_colour_id, $delta]);
            $stmt2 = $pdo->prepare("
                SELECT quantity FROM plate_consumption
                WHERE event_id = ? AND participant_id = ? AND plate_colour_id = ?
            ");
            $stmt2->execute([$event_id, $participant_id, $plate_colour_id]);
            $row = $stmt2->fetch();
            $pdo->commit();
            echo json_encode(['ok' => true, 'quantity' => (int)($row['quantity'] ?? 0)]);
        } catch (Exception $e) {
            $pdo->rollBack();
            json_error('DB error: ' . $e->getMessage(), 500);
        }
        break;

    // Increment a menu item for a given user at a given event.
    case 'increment_menu':
        $event_id = (int)($input['event_id'] ?? 0);
        $participant_id = (int)($input['participant_id'] ?? 0);
        $menu_item_id = (int)($input['menu_item_id'] ?? 0);
        $delta = (int)($input['delta'] ?? 1);
        if ($event_id <= 0 || $participant_id <= 0 || $menu_item_id <= 0) json_error('Invalid parameters');

        $pdo->beginTransaction();
        try {
            $stmt = $pdo->prepare("
                INSERT INTO menu_consumption (event_id, participant_id, menu_item_id, quantity)
                VALUES (?, ?, ?, GREATEST(?,0))
                ON DUPLICATE KEY UPDATE quantity = GREATEST(quantity + VALUES(quantity), 0)
            ");
            $stmt->execute([$event_id, $participant_id, $menu_item_id, $delta]);
            $stmt2 = $pdo->prepare("
                SELECT quantity FROM menu_consumption
                WHERE event_id = ? AND participant_id = ? AND menu_item_id = ?
            ");
            $stmt2->execute([$event_id, $participant_id, $menu_item_id]);
            $row = $stmt2->fetch();
            $pdo->commit();
            echo json_encode(['ok' => true, 'quantity' => (int)($row['quantity'] ?? 0)]);
        } catch (Exception $e) {
            $pdo->rollBack();
            json_error('DB error: ' . $e->getMessage(), 500);
        }
        break;

    // Get the totals for a given event.
    case 'get_totals':
        $event_id = (int)($_GET['event_id'] ?? 0);
        if ($event_id <= 0) json_error('Invalid event');

        $stmt = $pdo->prepare("
            SELECT pc.plate_colour_id, pc.participant_id, pc.quantity, epp.unit_price
            FROM plate_consumption pc
            JOIN event_plate_prices epp
              ON epp.event_id = pc.event_id AND epp.plate_colour_id = pc.plate_colour_id
            WHERE pc.event_id = ?
        ");
        $stmt->execute([$event_id]);
        $plate_rows = $stmt->fetchAll();

        $stmt = $pdo->prepare("
            SELECT mc.menu_item_id, mc.participant_id, mc.quantity, emp.unit_price
            FROM menu_consumption mc
            JOIN event_menu_prices emp
              ON emp.event_id = mc.event_id AND emp.menu_item_id = mc.menu_item_id
            WHERE mc.event_id = ?
        ");
        $stmt->execute([$event_id]);
        $menu_rows = $stmt->fetchAll();

        $per_person = [];
        foreach ($plate_rows as $r) {
            $pid = (int)$r['participant_id'];
            $per_person[$pid] = ($per_person[$pid] ?? 0) + $r['quantity'] * $r['unit_price'];
        }
        foreach ($menu_rows as $r) {
            $pid = (int)$r['participant_id'];
            $per_person[$pid] = ($per_person[$pid] ?? 0) + $r['quantity'] * $r['unit_price'];
        }

        echo json_encode(['ok' => true, 'per_person' => $per_person]);
        break;

    // Get Grid data - whatever that is!?
    case 'get_grid_data':
        $event_id = (int)($_GET['event_id'] ?? 0);
        if ($event_id <= 0) json_error('Invalid event');

        $stmt = $pdo->prepare("
            SELECT participant_id, plate_colour_id, quantity
            FROM plate_consumption
            WHERE event_id = ?
        ");
        $stmt->execute([$event_id]);
        $plate = $stmt->fetchAll();

        $stmt = $pdo->prepare("
            SELECT participant_id, menu_item_id, quantity
            FROM menu_consumption
            WHERE event_id = ?
        ");
        $stmt->execute([$event_id]);
        $menu = $stmt->fetchAll();

        echo json_encode(['ok' => true, 'plate' => $plate, 'menu' => $menu]);
        break;

    // Handle unexpected input.
    default:
        json_error('Unknown action', 404);
}