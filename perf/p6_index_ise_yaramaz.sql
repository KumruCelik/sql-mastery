-- p6_index_ise_yaramaz.sql
-- Index'in kullanilamadigi / fayda etmedigi dort durum.
-- products.sku uzerinde UNIQUE kisittan gelen bir index zaten var.

\echo '===== A1) Index KULLANILIR: kolon dogrudan karsilastiriliyor ====='
EXPLAIN (ANALYZE) SELECT id FROM products WHERE sku = 'SKU-00169';

\echo ''
\echo '===== A2) Index KULLANILMAZ: kolona fonksiyon uygulanmis ====='
EXPLAIN (ANALYZE) SELECT id FROM products WHERE lower(sku) = 'sku-00169';

\echo ''
\echo '===== A3) COZUM: ifade index i ====='
CREATE INDEX IF NOT EXISTS idx_products_sku_lower ON products (lower(sku));
ANALYZE products;
EXPLAIN (ANALYZE) SELECT id FROM products WHERE lower(sku) = 'sku-00169';

\echo ''
\echo '===== B) Tip donusumu kolona uygulanmis ====='
EXPLAIN (ANALYZE) SELECT sku FROM products WHERE id = 169;
EXPLAIN (ANALYZE) SELECT sku FROM products WHERE id::text = '169';

\echo ''
\echo '===== C) Dusuk secicilik: satirlarin %92 si kosulu sagliyor ====='
CREATE INDEX IF NOT EXISTS idx_products_active ON products (is_active);
ANALYZE products;
EXPLAIN (ANALYZE) SELECT count(*) FROM products WHERE is_active = true;
EXPLAIN (ANALYZE) SELECT count(*) FROM products WHERE is_active = false;

\echo ''
\echo '===== D) Bastan joker LIKE ====='
EXPLAIN (ANALYZE) SELECT id FROM products WHERE sku LIKE 'SKU-001%';
EXPLAIN (ANALYZE) SELECT id FROM products WHERE sku LIKE '%00169';

\echo ''
\echo '===== E) OR ile iki farkli kolon ====='
EXPLAIN (ANALYZE) SELECT id FROM products WHERE sku = 'SKU-00169' OR name = 'Urun 500';
