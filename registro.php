<?php
// ============================================================
//  registro.php — Crear nueva cuenta
//  POST /api/registro.php
//  Body JSON: { "nombre", "username", "email", "password",
//               "bio" (nullable), "es_publico" }
// ============================================================

require_once __DIR__ . '/db.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['mensaje' => 'Método no permitido.']);
    exit;
}

$body = json_decode(file_get_contents('php://input'), true);

// Validación básica de campos obligatorios
$requeridos = ['nombre', 'username', 'email', 'password'];
foreach ($requeridos as $campo) {
    if (empty($body[$campo])) {
        http_response_code(400);
        echo json_encode(['mensaje' => "El campo '$campo' es obligatorio."]);
        exit;
    }
}

$nombre    = trim($body['nombre']);
$username  = trim($body['username']);
$email     = trim($body['email']);
$password  = $body['password'];
$bio       = isset($body['bio']) && $body['bio'] !== '' ? trim($body['bio']) : null;
$esPublico = isset($body['es_publico']) ? (int)$body['es_publico'] : 1;

// Validar formato email
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(['mensaje' => 'El formato del correo no es válido.']);
    exit;
}

// Validar username (solo letras, números y guión bajo)
if (!preg_match('/^[a-zA-Z0-9_]{3,50}$/', $username)) {
    http_response_code(400);
    echo json_encode(['mensaje' => 'El username solo puede contener letras, números y _ (mín. 3 caracteres).']);
    exit;
}

// Validar longitud mínima de contraseña
if (strlen($password) < 8) {
    http_response_code(400);
    echo json_encode(['mensaje' => 'La contraseña debe tener al menos 8 caracteres.']);
    exit;
}

$pdo = getDB();

// Verificar que email y username no estén en uso
$stmt = $pdo->prepare('SELECT id FROM usuarios WHERE email = ? OR username = ? LIMIT 1');
$stmt->execute([$email, $username]);
if ($stmt->fetch()) {
    http_response_code(409);
    echo json_encode(['mensaje' => 'El correo o nombre de usuario ya está registrado.']);
    exit;
}

// Insertar nuevo usuario
// Usamos SHA2 igual que el script SQL de datos de prueba
$passwordHash = hash('sha256', $password);

$stmt = $pdo->prepare('
    INSERT INTO usuarios (nombre, username, email, password_hash, bio, es_publico)
    VALUES (?, ?, ?, ?, ?, ?)
');
$stmt->execute([$nombre, $username, $email, $passwordHash, $bio, $esPublico]);

$nuevoId = (int)$pdo->lastInsertId();

http_response_code(201);
echo json_encode([
    'usuario' => [
        'id'       => $nuevoId,
        'nombre'   => $nombre,
        'username' => $username,
    ]
]);
