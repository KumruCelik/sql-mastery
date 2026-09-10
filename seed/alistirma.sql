-- alistirma.sql
-- Ders alistirmalari icin kucuk tablo. Gercek semanin parcasi degil.
-- Tekrar tekrar calistirilabilir.

DROP TABLE IF EXISTS alistirma;

CREATE TABLE alistirma (
    id       integer PRIMARY KEY,
    ad       text    NOT NULL,
    kategori text    NOT NULL,
    fiyat    integer NOT NULL,
    stok     integer NOT NULL
);

INSERT INTO alistirma (id, ad, kategori, fiyat, stok) VALUES
    (1, 'Kalem',     'kirtasiye',   15, 120),
    (2, 'Defter',    'kirtasiye',   45,  30),
    (3, 'Kulaklik',  'elektronik', 850,   8),
    (4, 'Mouse',     'elektronik', 320,   0),
    (5, 'Su sisesi', 'mutfak',      90,  60),
    (6, 'Termos',    'mutfak',     540,  12);
