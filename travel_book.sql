-- ============================================================
--  TRAVEL BOOK — Script de Base de Datos MySQL
--  Materia: Desarrollo de Aplicaciones Web
-- ============================================================
--  MODELO RELACIONAL NORMALIZADO (3FN)
--
--  Tablas:
--    1. usuarios
--    2. viajes
--    3. lugares
--    4. fotos
--    5. likes
--    6. comentarios
-- ============================================================

CREATE DATABASE IF NOT EXISTS travel_book
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE travel_book;

-- ------------------------------------------------------------
-- 1. USUARIOS
--    Almacena la información de cada usuario registrado.
--    Es_publico controla si su perfil es visible para otros.
-- ------------------------------------------------------------
CREATE TABLE usuarios (
  id              INT           NOT NULL AUTO_INCREMENT,
  nombre          VARCHAR(100)  NOT NULL,
  username        VARCHAR(50)   NOT NULL,
  email           VARCHAR(150)  NOT NULL,
  password_hash   VARCHAR(255)  NOT NULL,
  avatar_url      VARCHAR(500)      NULL DEFAULT NULL,
  bio             TEXT              NULL DEFAULT NULL,
  es_publico      TINYINT(1)    NOT NULL DEFAULT 1,
  creado_en       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_username (username),
  UNIQUE KEY uq_email    (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 2. VIAJES
--    Cada viaje pertenece a un usuario.
--    Es_publico permite que otros usuarios lo vean en el feed.
-- ------------------------------------------------------------
CREATE TABLE viajes (
  id              INT           NOT NULL AUTO_INCREMENT,
  usuario_id      INT           NOT NULL,
  titulo          VARCHAR(200)  NOT NULL,
  pais            VARCHAR(100)  NOT NULL,
  ciudad          VARCHAR(100)  NOT NULL,
  fecha_inicio    DATE          NOT NULL,
  fecha_fin       DATE              NULL DEFAULT NULL,
  descripcion     TEXT              NULL DEFAULT NULL,
  es_publico      TINYINT(1)    NOT NULL DEFAULT 1,
  creado_en       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_viajes_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 3. LUGARES
--    Sitios visitados dentro de un viaje.
--    Calificacion va de 1 a 5 estrellas.
-- ------------------------------------------------------------
CREATE TABLE lugares (
  id              INT           NOT NULL AUTO_INCREMENT,
  viaje_id        INT           NOT NULL,
  nombre          VARCHAR(200)  NOT NULL,
  categoria       ENUM(
                    'restaurante',
                    'hotel',
                    'atraccion',
                    'playa',
                    'museo',
                    'otro'
                  )             NOT NULL DEFAULT 'otro',
  calificacion    TINYINT           NULL DEFAULT NULL,
  comentario      TEXT              NULL DEFAULT NULL,
  creado_en       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT chk_calificacion
    CHECK (calificacion BETWEEN 1 AND 5),
  CONSTRAINT fk_lugares_viaje
    FOREIGN KEY (viaje_id) REFERENCES viajes(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 4. FOTOS
--    Imágenes asociadas a un viaje.
--    Opcionalmente pueden estar ligadas a un lugar específico.
-- ------------------------------------------------------------
CREATE TABLE fotos (
  id              INT           NOT NULL AUTO_INCREMENT,
  viaje_id        INT           NOT NULL,
  lugar_id        INT               NULL DEFAULT NULL,
  storage_path    VARCHAR(500)  NOT NULL,
  pie_foto        VARCHAR(300)      NULL DEFAULT NULL,
  creado_en       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_fotos_viaje
    FOREIGN KEY (viaje_id) REFERENCES viajes(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_fotos_lugar
    FOREIGN KEY (lugar_id) REFERENCES lugares(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 5. LIKES
--    Un usuario solo puede dar like una vez por viaje
--    (restricción UNIQUE compuesta).
-- ------------------------------------------------------------
CREATE TABLE likes (
  id              INT           NOT NULL AUTO_INCREMENT,
  usuario_id      INT           NOT NULL,
  viaje_id        INT           NOT NULL,
  creado_en       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_like_unico (usuario_id, viaje_id),
  CONSTRAINT fk_likes_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_likes_viaje
    FOREIGN KEY (viaje_id) REFERENCES viajes(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 6. COMENTARIOS
--    Comentarios de usuarios en viajes públicos.
-- ------------------------------------------------------------
CREATE TABLE comentarios (
  id              INT           NOT NULL AUTO_INCREMENT,
  viaje_id        INT           NOT NULL,
  usuario_id      INT           NOT NULL,
  contenido       TEXT          NOT NULL,
  creado_en       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_comentarios_viaje
    FOREIGN KEY (viaje_id) REFERENCES viajes(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_comentarios_usuario
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
--  DATOS DE PRUEBA
-- ============================================================

INSERT INTO usuarios (nombre, username, email, password_hash, bio, es_publico) VALUES
('María González', 'maria_travels',   'maria@ejemplo.com',  SHA2('pass1234', 256), 'Exploradora del mundo 🌍 | Amante de la fotografía', 1),
('Carlos Ruiz',    'carlos_aventura', 'carlos@ejemplo.com', SHA2('pass1234', 256), 'Viajero empedernido',                                 1),
('Ana López',      'ana_mundo',       'ana@ejemplo.com',    SHA2('pass1234', 256), 'Naturaleza y aventura',                               1),
('Pedro Morales',  'pedro_viajero',   'pedro@ejemplo.com',  SHA2('pass1234', 256), 'Fotografía de viajes',                                1);

INSERT INTO viajes (usuario_id, titulo, pais, ciudad, fecha_inicio, fecha_fin, descripcion, es_publico) VALUES
(1, 'Dos semanas en Japón',       'Japón',      'Tokio',      '2026-01-10', '2026-01-24', 'La mezcla perfecta entre tradición y modernidad.',          1),
(1, 'Trekking en la Patagonia',   'Argentina',  'Patagonia',  '2025-12-15', '2025-12-28', 'Glaciares impresionantes y paisajes que quitan el aliento.', 1),
(2, 'Una semana en Bali',         'Indonesia',  'Bali',       '2025-11-01', '2025-11-08', 'Templos, arrozales y playas de arena volcánica negra.',      1),
(3, 'Otoño en el Bosque Negro',   'Alemania',   'Friburgo',   '2025-10-05', '2025-10-12', 'Pueblos de cuento de hadas y bosques de colores imposibles.',1),
(4, 'Explorando Dubai',           'Emiratos',   'Dubai',      '2025-09-20', '2025-09-27', 'Arquitectura futurista y desiertos infinitos.',              1);

INSERT INTO lugares (viaje_id, nombre, categoria, calificacion, comentario) VALUES
(1, 'Templo Senso-ji',    'atraccion', 5, 'El templo más antiguo de Tokio, impresionante de noche.'),
(1, 'Ramen Ichiran',      'restaurante',5, 'El mejor ramen que he probado en mi vida.'),
(2, 'Glaciar Perito Moreno', 'atraccion', 5, 'Ver el hielo caer al lago es una experiencia única.'),
(3, 'Templo Tanah Lot',   'atraccion', 5, 'Templo sobre el mar, espectacular al atardecer.'),
(3, 'Warung Babi Guling', 'restaurante',4, 'Cerdo asado tradicional balinés, muy recomendado.'),
(5, 'Burj Khalifa',       'atraccion', 5, 'Las vistas desde el piso 148 son surrealistas.');

INSERT INTO likes (usuario_id, viaje_id) VALUES
(2, 1), (3, 1), (4, 1),
(1, 3), (4, 3),
(1, 4), (2, 4),
(1, 5), (2, 5), (3, 5);

INSERT INTO comentarios (viaje_id, usuario_id, contenido) VALUES
(1, 2, '¡Japón está en mi lista! ¿Cuánto gastaste aproximadamente?'),
(1, 3, 'Las fotos del Senso-ji se ven increíbles 😍'),
(3, 1, 'Bali es mágico, yo también quiero volver.'),
(5, 3, '¿El Burj Khalifa vale la pena la entrada?');
