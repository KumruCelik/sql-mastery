-- load.sql
-- data/ altindaki CSV'leri tablolara yukler.
-- Repo kokunden calistirilmali (yollar goreli).

BEGIN;

TRUNCATE order_coupons, inventory_movements, reviews, shipments, payments,
         order_items, orders, coupons, products, categories, users
    RESTART IDENTITY CASCADE;

\copy categories (id, parent_id, name, slug) FROM 'data/categories.csv' WITH (FORMAT csv, HEADER true)
\copy users (id, email, full_name, country, is_active, created_at) FROM 'data/users.csv' WITH (FORMAT csv, HEADER true)
\copy products (id, category_id, sku, name, list_price, unit_cost, stock_cached, is_active, created_at) FROM 'data/products.csv' WITH (FORMAT csv, HEADER true)
\copy coupons (id, code, discount_type, discount_value, max_uses, valid_from, valid_to) FROM 'data/coupons.csv' WITH (FORMAT csv, HEADER true)
\copy orders (id, user_id, status, shipping_country, ordered_at) FROM 'data/orders.csv' WITH (FORMAT csv, HEADER true)
\copy order_items (id, order_id, product_id, quantity, unit_price, unit_cost) FROM 'data/order_items.csv' WITH (FORMAT csv, HEADER true)
\copy payments (id, order_id, amount, method, status, paid_at) FROM 'data/payments.csv' WITH (FORMAT csv, HEADER true)
\copy shipments (id, order_id, carrier, tracking_no, status, shipped_at, delivered_at) FROM 'data/shipments.csv' WITH (FORMAT csv, HEADER true)
\copy order_coupons (order_id, coupon_id, discount_applied) FROM 'data/order_coupons.csv' WITH (FORMAT csv, HEADER true)
\copy reviews (id, user_id, product_id, rating, body, created_at) FROM 'data/reviews.csv' WITH (FORMAT csv, HEADER true)
\copy inventory_movements (id, product_id, order_id, movement_type, quantity, occurred_at) FROM 'data/inventory_movements.csv' WITH (FORMAT csv, HEADER true)

-- Elle id yazdik; sayaclari en buyuk id'ye kur (K-006).
SELECT setval(pg_get_serial_sequence('categories',          'id'), (SELECT max(id) FROM categories));
SELECT setval(pg_get_serial_sequence('users',               'id'), (SELECT max(id) FROM users));
SELECT setval(pg_get_serial_sequence('products',            'id'), (SELECT max(id) FROM products));
SELECT setval(pg_get_serial_sequence('coupons',             'id'), (SELECT max(id) FROM coupons));
SELECT setval(pg_get_serial_sequence('orders',              'id'), (SELECT max(id) FROM orders));
SELECT setval(pg_get_serial_sequence('order_items',         'id'), (SELECT max(id) FROM order_items));
SELECT setval(pg_get_serial_sequence('payments',            'id'), (SELECT max(id) FROM payments));
SELECT setval(pg_get_serial_sequence('shipments',           'id'), (SELECT max(id) FROM shipments));
SELECT setval(pg_get_serial_sequence('reviews',             'id'), (SELECT max(id) FROM reviews));
SELECT setval(pg_get_serial_sequence('inventory_movements', 'id'), (SELECT max(id) FROM inventory_movements));

COMMIT;

\i seed/refresh_stock.sql

ANALYZE;
