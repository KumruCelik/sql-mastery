-- smoke.sql
-- Semanin uctan uca calistigini kanitlayan kucuk veri seti.
-- Tekrar tekrar calistirilabilir: bastaki TRUNCATE her seferinde sifirlar.

BEGIN;

TRUNCATE order_items, payments, shipments, orders, products, categories, users
    RESTART IDENTITY CASCADE;

INSERT INTO users (email, full_name, country) VALUES
    ('ayse@ornek.com',   'Ayse Yilmaz',  'TR'),
    ('mehmet@ornek.com', 'Mehmet Demir', 'TR');

INSERT INTO categories (parent_id, name, slug)
VALUES (NULL, 'Elektronik', 'elektronik');

INSERT INTO categories (parent_id, name, slug)
VALUES ((SELECT id FROM categories WHERE slug = 'elektronik'), 'Ses', 'ses');

INSERT INTO products (category_id, sku, name, list_price, unit_cost) VALUES
    ((SELECT id FROM categories WHERE slug = 'ses'),        'SKU-001', 'Kulaklik', 850.00, 400.00),
    ((SELECT id FROM categories WHERE slug = 'elektronik'), 'SKU-002', 'Mouse',    320.00, 150.00);

INSERT INTO orders (user_id, status, shipping_country)
VALUES ((SELECT id FROM users WHERE email = 'ayse@ornek.com'), 'paid', 'TR');

INSERT INTO order_items (order_id, product_id, quantity, unit_price, unit_cost) VALUES
    ((SELECT id FROM orders   WHERE user_id = (SELECT id FROM users WHERE email = 'ayse@ornek.com')),
     (SELECT id FROM products WHERE sku = 'SKU-001'), 2, 850.00, 400.00),
    ((SELECT id FROM orders   WHERE user_id = (SELECT id FROM users WHERE email = 'ayse@ornek.com')),
     (SELECT id FROM products WHERE sku = 'SKU-002'), 1, 320.00, 150.00);

INSERT INTO payments (order_id, amount, method, status)
VALUES ((SELECT id FROM orders WHERE user_id = (SELECT id FROM users WHERE email = 'ayse@ornek.com')),
        2020.00, 'card', 'success');

COMMIT;
