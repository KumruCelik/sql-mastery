-- 001_users_categories.sql
-- Bagimsiz iki temel tablo: kullanicilar ve kategori agaci.

BEGIN;

CREATE TABLE users (
    id          bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email       text        NOT NULL,
    full_name   text        NOT NULL,
    country     text,
    is_active   boolean     NOT NULL DEFAULT true,
    created_at  timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT users_email_uq     UNIQUE (email),
    CONSTRAINT users_email_format CHECK (email LIKE '%_@_%._%'),
    CONSTRAINT users_name_not_blank CHECK (length(btrim(full_name)) > 0)
);

CREATE TABLE categories (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    parent_id  bigint,
    name       text NOT NULL,
    slug       text NOT NULL,

    CONSTRAINT categories_slug_uq   UNIQUE (slug),
    CONSTRAINT categories_parent_fk FOREIGN KEY (parent_id)
        REFERENCES categories (id) ON DELETE RESTRICT,
    CONSTRAINT categories_not_self  CHECK (parent_id IS NULL OR parent_id <> id)
);

COMMIT;
