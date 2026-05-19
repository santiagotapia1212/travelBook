<?php
// ============================================================
//  viajes.php — Publicar un nuevo viaje
//  POST /api/viajes.php
//  Body JSON:
//  {
//    "usuario_id":   1,
//    "titulo":       "...",
//    "ciudad":       "...",
//    "pais":         "...",
//    "fecha_inicio": "2026-01-10",
//    "fecha_fin":    "2026-01-24",   <- puede ser null
//    "descripcion":  "...",
//    "es_publico":   1,
//    "lugar": {                      <- puede ser null
//      "nombre":      "...",
//      "categoria":   "atraccion",
//      "calificacion": 5,            <- puede ser null
//      "comentario":  "..."          <- puede ser null
//    }
//  }
// ============================================================

require_once __DIR__ . '/db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['mensaje' => 'Método no permitido.']);
    exit;
}

$body = json_decode(file_get_contents('php://input'), true);

// Validar campos obligatorios del viaje
$requeridos = ['usuario_id', 'titulo', 'ciudad', 'pais', 'fecha_inicio'];
foreach ($requeridos as $campo) {
    if (empty($body[$campo])) {
        http_response_code(400);
        echo json_encode(['mensaje' => "El campo '$campo' es obligatorio."]);
        exit;
    }
}

$usuarioId   = (int)$body['usuario_id'];
$titulo      = trim($body['titulo']);
$ciudad      = trim($body['ciudad']);
$pais        = trim($body['pais']);
$fechaInicio = $body['fecha_inicio'];
$fechaFin    = !empty($body['fecha_fin']) ? $body['fecha_fin'] : null;
$descripcion = !empty($body['descripcion']) ? trim($body['descripcion']) : null;
$esPublico   = isset($body['es_publico']) ? (int)$body['es_publico'] : 1;
$lugar       = isset($body['lugar']) && is_array($body['lugar']) ? $body['lugar'] : null;

// Validar que el usuario existe
$pdo  = getDB();
$stmt = $pdo->prepare('SELECT id FROM usuarios WHERE id = ? LIMIT 1');
$stmt->execute([$usuarioId]);
if (!$stmt->fetch()) {
    http_response_code(404);
    echo json_encode(['mensaje' => 'El usuario no existe.']);
    exit;
}

// Validar categoría si viene lugar
$categoriasValidas = ['restaurante', 'hotel', 'atraccion', 'playa', 'museo', 'otro'];
if ($lugar && !empty($lugar['categoria']) && !in_array($lugar['categoria'], $categoriasValidas)) {
    http_response_code(400);
    echo json_encode(['mensaje' => 'Categoría de lugar no válida.']);
    exit;
}

// ── TRANSACCIÓN: insertar viaje y (si aplica) lugar ──────────
try {
    $pdo->beginTransaction();

    // 1. Insertar en tabla viajes
    $stmt = $pdo->prepare('
        INSERT INTO viajes
            (usuario_id, titulo, ciudad, pais, fecha_inicio, fecha_fin, descripcion, es_publico)
        VALUES
            (?, ?, ?, ?, ?, ?, ?, ?)
    ');
    $stmt->execute([
        $usuarioId,
        $titulo,
        $ciudad,
        $pais,
        $fechaInicio,
        $fechaFin,
        $descripcion,
        $esPublico,
    ]);

    $viajeId = (int)$pdo->lastInsertId();

    // 2. Si se envió un lugar destacado, insertarlo en tabla lugares
    if ($lugar && !empty($lugar['nombre'])) {
        $lugarNombre      = trim($lugar['nombre']);
        $lugarCategoria   = !empty($lugar['categoria']) ? $lugar['categoria'] : 'otro';
        $lugarCalif       = isset($lugar['calificacion']) && $lugar['calificacion'] >= 1
                            ? (int)$lugar['calificacion'] : null;
        $lugarComentario  = !empty($lugar['comentario']) ? trim($lugar['comentario']) : null;

        $stmt = $pdo->prepare('
            INSERT INTO lugares (viaje_id, nombre, categoria, calificacion, comentario)
            VALUES (?, ?, ?, ?, ?)
        ');
        $stmt->execute([
            $viajeId,
            $lugarNombre,
            $lugarCategoria,
            $lugarCalif,
            $lugarComentario,
        ]);
    }

    $pdo->commit();

    http_response_code(201);
    echo json_encode([
        'viaje_id' => $viajeId,
        'mensaje'  => 'Viaje publicado con éxito.'
    ]);

} catch (PDOException $e) {
    $pdo->rollBack();
    http_response_code(500);
    echo json_encode(['mensaje' => 'Error al guardar el viaje: ' . $e->getMessage()]);
}
