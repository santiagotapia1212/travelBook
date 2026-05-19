<?php
// ============================================================
//  login.php — Iniciar sesión
//  POST /api/login.php
//  Body JSON: { "email": "...", "password": "..." }
// ============================================================

require_once __DIR__ . '/db.php';

// Solo aceptar POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['mensaje' => 'Método no permitido.']);
    exit;
}

// Leer y validar el body JSON
$body = json_decode(file_get_contents('php://input'), true);

if (empty($body['email']) || empty($body['password'])) {
    http_response_code(400);
    echo json_encode(['mensaje' => 'Correo y contraseña son obligatorios.']);
    exit;
}

$email    = trim($body['email']);
$password = $body['password'];

// Buscar usuario por email
$pdo  = getDB();
$stmt = $pdo->prepare('
    SELECT id, nombre, username, password_hash
    FROM   usuarios
    WHERE  email = ?
    LIMIT  1
');
$stmt->execute([$email]);
$usuario = $stmt->fetch();

// Verificar que existe y que el hash coincide
// El SQL de prueba usa SHA2(password, 256), así que comparamos igual
$hashIngresado = hash('sha256', $password);

if (!$usuario || $hashIngresado !== $usuario['password_hash']) {
    http_response_code(401);
    echo json_encode(['mensaje' => 'Correo o contraseña incorrectos.']);
    exit;
}

// Respuesta exitosa — nunca devolver password_hash al cliente
http_response_code(200);
echo json_encode([
    'usuario' => [
        'id'       => $usuario['id'],
        'nombre'   => $usuario['nombre'],
        'username' => $usuario['username'],
    ]
]);
