-- ─────────────────────────────────────────────────────────────────────────────
--  MediaManager2 — Schema setup script
--  Run once against TrueNAS MySQL 192.168.1.100:3306
--  mysql -h 192.168.1.100 -u root -p < create_mediamanager2.sql
-- ─────────────────────────────────────────────────────────────────────────────

CREATE DATABASE IF NOT EXISTS MediaManager2
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE MediaManager2;

-- ── Media type names (Video, Music, Images, etc.) ────────────────────────────
CREATE TABLE IF NOT EXISTS mediatypename (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    media_type_name  VARCHAR(100) NOT NULL UNIQUE
);

INSERT IGNORE INTO mediatypename (media_type_name) VALUES
    ('Video'), ('Music'), ('Images'), ('Documents'), ('Other');

-- ── File extension → media category mapping ──────────────────────────────────
CREATE TABLE IF NOT EXISTS mediatypes (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    file_extension   VARCHAR(20)  NOT NULL UNIQUE,
    media_category   VARCHAR(100) NOT NULL
);

INSERT IGNORE INTO mediatypes (file_extension, media_category) VALUES
    ('.mkv',  'Video'),  ('.mp4',  'Video'),  ('.avi',  'Video'),
    ('.mov',  'Video'),  ('.wmv',  'Video'),  ('.m2ts', 'Video'),
    ('.flac', 'Music'),  ('.mp3',  'Music'),  ('.aac',  'Music'),
    ('.wav',  'Music'),  ('.m4a',  'Music'),  ('.ogg',  'Music'),
    ('.jpg',  'Images'), ('.jpeg', 'Images'), ('.png',  'Images'),
    ('.tif',  'Images'), ('.tiff', 'Images'), ('.webp', 'Images'),
    ('.pdf',  'Documents'), ('.txt', 'Documents');

-- ── Excluded folder names (os.walk will skip any directory matching these) ───
CREATE TABLE IF NOT EXISTS excluded_folders (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    folder_name  VARCHAR(255) NOT NULL UNIQUE
);

INSERT IGNORE INTO excluded_folders (folder_name) VALUES
    ('@eaDir'), ('.@__thumb'), ('System Volume Information'),
    ('$RECYCLE.BIN'), ('.Spotlight-V100'), ('.Trashes');

-- ── Master / Clone / Secondary classification ────────────────────────────────
CREATE TABLE IF NOT EXISTS mastertype (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    master_type_name  VARCHAR(100) NOT NULL UNIQUE
);

INSERT IGNORE INTO mastertype (master_type_name) VALUES
    ('Master'), ('Clone'), ('Secondary');

-- ── Non-master collection file records ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS mediafiledetail (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    file_path        TEXT         NOT NULL,
    file_name        VARCHAR(500) NOT NULL,
    file_extension   VARCHAR(20),
    file_size_bytes  BIGINT       DEFAULT 0,
    collection_name  VARCHAR(500) NOT NULL,
    media_category   VARCHAR(100),
    device           VARCHAR(200),
    checksum         VARCHAR(128),
    created_at       DATETIME     DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_coll  (collection_name(255)),
    INDEX idx_fname (file_name(255))
) ENGINE=InnoDB;

-- ── Master collection file records ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS masterfiledetail (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    file_path        TEXT         NOT NULL,
    file_name        VARCHAR(500) NOT NULL,
    file_extension   VARCHAR(20),
    file_size_bytes  BIGINT       DEFAULT 0,
    collection_name  VARCHAR(500) NOT NULL,
    media_category   VARCHAR(100),
    device           VARCHAR(200),
    master_type      VARCHAR(100) DEFAULT 'Master',
    checksum         VARCHAR(128),
    created_at       DATETIME     DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_coll  (collection_name(255)),
    INDEX idx_fname (file_name(255))
) ENGINE=InnoDB;

-- ─────────────────────────────────────────────────────────────────────────────
SELECT 'MediaManager2 schema created successfully.' AS status;
