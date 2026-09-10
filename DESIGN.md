# sql-mastery — Tasarım Kararları

Bölüm 3 (SQL ve veri modelleme) için e-ticaret OLTP şeması.
Kural: karar değişirse satır silinmez, "GERİ ALINDI" notu düşülür ve yeni karar altına yazılır.

---

## K-001 — Kategoriler hiyerarşik

**Seçim:** `categories(id, parent_id, name, slug)` — tablo kendine referans verir, kök kategoride `parent_id IS NULL`.

**Gerekçe:** Ürün ağacı gerçek hayatta çok seviyeli ("Elektronik > Ses > Kulaklık") ve recursive CTE'yi yapay bir örnek yerine kendi verimizde çalıştırmak istiyoruz.

**Reddedilen alternatif:** Düz kategori listesi (`id, name`). Daha basit ve join'i tek adım, ama hiyerarşik sorgulama pratiğini tamamen ortadan kaldırıyor.

**Bedeli:** Kategori bazlı toplamlarda "alt kategoriler dahil mi" sorusu her seferinde açıkça cevaplanmak zorunda.

---

## K-002 — Fiyat ve maliyet sipariş satırına kopyalanır

**Seçim:** `order_items.unit_price` ve `order_items.unit_cost` — sipariş anındaki değerler satıra yazılır (snapshot).

**Gerekçe:** Geçmiş raporların bugün değişmemesi gerekir. Fiyat `products` üzerinden okunursa, bugünkü bir zam geçen ayın cirosunu ve marjını da değiştirir; bu sessiz ve geç fark edilen bir hatadır.

**Reddedilen alternatif:** Fiyatı `products.list_price`'tan okumak. Tek kaynak olduğu için tutarsızlık riski yok, ama tarihsel doğruluğu imkânsız kılıyor.

**Bedeli:** Aynı bilgi iki yerde durur; `products.list_price` "bugünkü fiyat", `order_items.unit_price` "o günkü fiyat" olarak ayrı ayrı anlaşılmalı.

---

## K-003 — Stok defterden hesaplanır, kolon türetilmiş kopyadır

**Seçim:** `inventory_movements` tek gerçek kaynaktır. `products.stock_cached` türetilmiş kolondur; elle veya artımlı olarak güncellenmez, `make refresh-stock` komutuyla defterden toplu olarak yeniden hesaplanır.

**Gerekçe:** Bu projede stok, canlı bir satış akışıyla değil toplu üretilen bir veri kümesiyle değişiyor. Artımlı güncelleme hem 500 bin satırda yavaş, hem de stoku değiştiren her kod yolunun bunu hatırlamasına bağlı — bir yol unutursa sapma sessizce başlar. Yeniden hesaplama, mantığı tek bir SQL'de toplar ve sapma durumunda düzeltmeyi tek komuta indirir. Anlık stok doğruluğu bu projenin gereği değil; tarihsel doğruluk zaten defterde duruyor.

**Reddedilen alternatif 1:** Sadece `products.stock` kolonu, her satışta güncellenir. Hızlı, ama "geçen salı stok neydi" sorusu sonsuza dek cevapsız kalır.

**Reddedilen alternatif 2:** Sadece defter, türetilmiş kolon yok. Tutarsızlık riski sıfır, ama her stok okuması toplama yapar ve denormalizasyon kararı deneyimi kaybolur.

**Reddedilen alternatif 3:** Trigger ile otomatik güncelleme. Unutulamaz olması avantajı, ama mantık gizli yerde durur ve toplu yüklemede her satır için tetiklendiği için seed'i belirgin yavaşlatır.

**Bedeli:** Kolon, son yenilemeden bu yana bayat kalabilir. Karşılığında bedava bir veri kalitesi testi doğuyor: `stock_cached` defter toplamına eşit mi?

---

## K-004 — Kupon ile sipariş arasında bağlantı tablosu

**Seçim:** `order_coupons(order_id, coupon_id, discount_applied)`, bileşik PK. Bir siparişte birden çok kupon olabilir.

**Gerekçe:** N-N ilişki kurma ve fan-out'u ikinci bir yerde görme pratiği. `discount_applied` kolonu, her kuponun o siparişte kaç lira indirdiğini satıra yazar; böylece raporda kupon mantığı yeniden hesaplanmak zorunda kalmaz.

**Reddedilen alternatif:** `orders.coupon_id` — sipariş başına tek kupon. Marj sorgusunu belirgin şekilde kolaylaştırırdı ve gerçek e-ticaret sistemlerinin çoğunda böyle.

**Bedeli:** Kupon marj etkisi sorgusunda indirimin kalemlere dağıtımı ayrıca düşünülmeli. `discount_applied` bu yükün çoğunu üstleniyor.

---

## K-005 — Aynı kullanıcının aynı ürüne birden çok yorumu serbest

**Seçim:** `reviews` üzerinde `UNIQUE (user_id, product_id)` kısıtı yok.

**Gerekçe:** Aynı ürünü tekrar satın alan bir kullanıcının yeni yorumu ayrı ve meşru bir olaydır; tekilleştirmek o olayı hiç kaydetmemek demektir — K-002'de reddedilen "geçmişi bugünle ezme" hatasının aynısı, başka kılıkta. Ayrıca ortalama puan sorgularının "kullanıcı-ürün başına en son yorum" kalıbını açıkça yazmak zorunda kalması, bu şemada kusur değil; doğru sorunun sorulmasını zorlayan bir özellik.

**Reddedilen alternatif:** `UNIQUE (user_id, product_id)` ile kullanıcı-ürün başına tek yorum. Ortalama puan sorgularını basitleştirirdi, ama tekrar satın alma sonrası yazılan ikinci yorumu veri kaybı pahasına engellerdi.

**Bedeli:** Ortalama puan hesaplarında çok yorum yazan kullanıcı ortalamayı birden çok kez etkiler. Her puan sorgusu "hangi yorumu sayıyorum" sorusunu açıkça cevaplamak zorunda.

---

## Şemaya dair genel notlar

- `payments` grain'i "bir ödeme hareketi"dir, "bir siparişin ödemesi" değil. Başarısız deneme ve iade de birer satırdır; iade `amount` negatif yazılır.
- `inventory_movements.order_id` satış dışı hareketlerde (`purchase`, `adjustment`) NULL'dur. Bu NULL "bilinmiyor" değil, "uygulanamaz" anlamındadır.
- `orders` tablosunda toplam tutar kolonu yoktur; sipariş toplamı `order_items`'tan hesaplanır. Reddedilen alternatif: `orders.total_amount` denormalize kolonu — okumayı hızlandırırdı, ama K-003'teki sapma riskini üçüncü bir yerde daha doğururdu.
