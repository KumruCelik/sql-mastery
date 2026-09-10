#!/usr/bin/env python3
"""
sql-mastery sentetik veri ureticisi.

Cikti: data/ altinda CSV dosyalari. Yukleme seed/load.sql ile yapilir.
Kullanim: python3 scripts/generate.py

Uretilen ozellikler:
  - mevsimsellik: kasim-aralik zirvesi, ocak-subat durgunlugu, haftasonu artisi
  - guc yasasi: az sayida urun satislarin cogunu yapar
  - ~%2 iade
  - ~%5 eksik veri (ulke, kargo takip no, yorum metni)
  - kasitli anomaliler: zararina satilan urunler, kargo kaydi olmayan
    'shipped' siparisler, ayni kullanicidan ayni urune ikinci yorum
"""

import bisect
import csv
import os
import random
from datetime import datetime, timedelta, timezone
from itertools import accumulate

random.seed(42)

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(BASE, "data")
os.makedirs(OUT, exist_ok=True)

N_USERS = 20_000
N_PRODUCTS = 2_000
N_ORDERS = 100_000
N_COUPONS = 50
N_REVIEWS = 30_000

START = datetime(2024, 1, 1, tzinfo=timezone.utc)
END = datetime(2026, 6, 30, tzinfo=timezone.utc)
TOTAL_DAYS = (END - START).days
DAYS = [START + timedelta(days=i) for i in range(TOTAL_DAYS)]


def day_weight(d):
    if d.month in (11, 12):
        season = 2.2
    elif d.month in (1, 2):
        season = 0.7
    elif d.month in (6, 7):
        season = 1.2
    else:
        season = 1.0
    weekly = 1.25 if d.weekday() >= 5 else 1.0
    trend = 1.0 + 0.4 * ((d - START).days / TOTAL_DAYS)
    return season * weekly * trend


DAY_CUM = list(accumulate(day_weight(d) for d in DAYS))


def pick_day(min_idx=0):
    lo = DAY_CUM[min_idx - 1] if min_idx > 0 else 0.0
    r = random.uniform(lo, DAY_CUM[-1])
    return min(bisect.bisect_left(DAY_CUM, r), TOTAL_DAYS - 1)


def moment(day_idx):
    return DAYS[day_idx] + timedelta(seconds=random.randint(0, 86399))


def open_csv(name, header):
    f = open(os.path.join(OUT, name), "w", newline="", encoding="utf-8")
    wr = csv.writer(f)
    wr.writerow(header)
    return f, wr


def weighted_picker(ids, weights):
    cum = list(accumulate(weights))
    total = cum[-1]

    def pick():
        r = random.uniform(0.0, total)
        return ids[min(bisect.bisect_left(cum, r), len(ids) - 1)]

    return pick


# ---------------------------------------------------------------- kategoriler
ROOTS = [
    ("Elektronik", "elektronik"), ("Kirtasiye", "kirtasiye"),
    ("Mutfak", "mutfak"), ("Giyim", "giyim"),
    ("Spor", "spor"), ("Kitap", "kitap"),
    ("Bebek", "bebek"), ("Bahce", "bahce"),
]
SUBS = [("Temel", "temel"), ("Aksesuar", "aksesuar"),
        ("Yeni Sezon", "yeni-sezon"), ("Premium", "premium")]

f, wr = open_csv("categories.csv", ["id", "parent_id", "name", "slug"])
leaf_ids = []
cid = 0
for rname, rslug in ROOTS:
    cid += 1
    root_id = cid
    wr.writerow([root_id, None, rname, rslug])
    for sname, sslug in SUBS:
        cid += 1
        wr.writerow([cid, root_id, f"{rname} {sname}", f"{rslug}-{sslug}"])
        leaf_ids.append(cid)
f.close()
print(f"categories.csv         {cid:>9,} satir")

# ------------------------------------------------------------------- urunler
price_of, cost_of = {}, {}
rows = []
for pid in range(1, N_PRODUCTS + 1):
    price = round(min(max(random.lognormvariate(4.6, 0.85), 9.9), 25000.0), 2)
    cost = round(price * random.uniform(0.35, 0.80), 2)
    rows.append([pid, random.choice(leaf_ids), f"SKU-{pid:05d}", f"Urun {pid}",
                 price, cost, 0, "true" if random.random() < 0.92 else "false",
                 moment(pick_day(0)).isoformat()])
    price_of[pid], cost_of[pid] = price, cost

# ANOMALI: 10 urun zararina satiliyor (maliyet > liste fiyati)
for pid in random.sample(range(1, N_PRODUCTS + 1), 10):
    yeni = round(price_of[pid] * 1.15, 2)
    rows[pid - 1][5] = yeni
    cost_of[pid] = yeni

f, wr = open_csv("products.csv", ["id", "category_id", "sku", "name",
                                  "list_price", "unit_cost", "stock_cached",
                                  "is_active", "created_at"])
wr.writerows(rows)
f.close()
print(f"products.csv           {N_PRODUCTS:>9,} satir")

# urun populerligi: guc yasasi
ranked = list(range(1, N_PRODUCTS + 1))
random.shuffle(ranked)
pick_product = weighted_picker(ranked, [1.0 / (i ** 1.1) for i in range(1, N_PRODUCTS + 1)])

# ------------------------------------------------------------- kullanicilar
COUNTRIES = ["TR"] * 70 + ["DE"] * 10 + ["NL"] * 5 + ["FR"] * 5 + ["GB"] * 5 + ["US"] * 5
user_created = {}
f, wr = open_csv("users.csv", ["id", "email", "full_name", "country",
                               "is_active", "created_at"])
for uid in range(1, N_USERS + 1):
    didx = random.randint(0, int(TOTAL_DAYS * 0.9))
    user_created[uid] = didx
    ulke = None if random.random() < 0.05 else random.choice(COUNTRIES)  # %5 eksik
    wr.writerow([uid, f"user{uid}@ornek.com", f"Kullanici {uid}", ulke,
                 "true" if random.random() < 0.95 else "false",
                 moment(didx).isoformat()])
f.close()
print(f"users.csv              {N_USERS:>9,} satir")

ranked_u = list(range(1, N_USERS + 1))
random.shuffle(ranked_u)
pick_user = weighted_picker(ranked_u, [1.0 / (i ** 0.7) for i in range(1, N_USERS + 1)])

# ------------------------------------------------------------------ kuponlar
coupons = []
f, wr = open_csv("coupons.csv", ["id", "code", "discount_type", "discount_value",
                                 "max_uses", "valid_from", "valid_to"])
for c in range(1, N_COUPONS + 1):
    percent = random.random() < 0.6
    val = round(random.uniform(5, 40), 2) if percent else round(random.uniform(20, 200), 2)
    vf = DAYS[random.randint(0, TOTAL_DAYS - 200)]
    vt = vf + timedelta(days=random.randint(30, 180))
    wr.writerow([c, f"KUPON{c:03d}", "percent" if percent else "amount", val,
                 random.choice([None, 100, 500, 1000]), vf.isoformat(), vt.isoformat()])
    coupons.append((c, percent, val))
f.close()
print(f"coupons.csv            {N_COUPONS:>9,} satir")

# ------------------------------------- siparisler, kalemler, stok hareketleri
STATUSES = (["created"] * 7 + ["paid"] * 10 + ["shipped"] * 13 +
            ["delivered"] * 63 + ["cancelled"] * 5 + ["returned"] * 2)
ITEM_COUNTS = [1] * 45 + [2] * 28 + [3] * 15 + [4] * 8 + [5] * 4
QTYS = [1] * 70 + [2] * 22 + [3] * 8
CARRIERS = ["Yurtici", "Aras", "MNG", "PTT", "UPS"]

fo, wo = open_csv("orders.csv", ["id", "user_id", "status", "shipping_country", "ordered_at"])
fi, wi = open_csv("order_items.csv", ["id", "order_id", "product_id", "quantity",
                                      "unit_price", "unit_cost"])
fs, ws = open_csv("shipments.csv", ["id", "order_id", "carrier", "tracking_no",
                                    "status", "shipped_at", "delivered_at"])
fm, wm = open_csv("inventory_movements.csv", ["id", "product_id", "order_id",
                                              "movement_type", "quantity", "occurred_at"])

item_id = ship_id = mv_id = 0
order_total = {}
review_pool = []
kargosuz = set(random.sample(range(1, N_ORDERS + 1), 30))  # ANOMALI

for oid in range(1, N_ORDERS + 1):
    uid = pick_user()
    when = moment(pick_day(user_created[uid]))
    status = random.choice(STATUSES)
    ulke = random.choice(COUNTRIES) if random.random() > 0.05 else None
    wo.writerow([oid, uid, status, ulke, when.isoformat()])

    secilen = set()
    while len(secilen) < random.choice(ITEM_COUNTS):
        secilen.add(pick_product())

    toplam = 0.0
    for pid in secilen:
        item_id += 1
        qty = random.choice(QTYS)
        birim = round(price_of[pid] * random.uniform(0.85, 1.0), 2)
        maliyet = round(cost_of[pid] * random.uniform(0.90, 1.10), 2)
        wi.writerow([item_id, oid, pid, qty, birim, maliyet])
        toplam += birim * qty

        if status in ("paid", "shipped", "delivered", "returned"):
            mv_id += 1
            wm.writerow([mv_id, pid, oid, "sale", -qty, when.isoformat()])
        if status == "returned":
            mv_id += 1
            wm.writerow([mv_id, pid, oid, "return", qty,
                         (when + timedelta(days=random.randint(5, 20))).isoformat()])
        if status == "delivered" and random.random() < 0.25:
            review_pool.append((uid, pid, when))

    order_total[oid] = round(toplam, 2)

    if status in ("shipped", "delivered", "returned") and oid not in kargosuz:
        ship_id += 1
        gonderi = when + timedelta(days=random.randint(1, 3))
        teslim = gonderi + timedelta(days=random.randint(1, 7))
        durum = {"shipped": "in_transit", "delivered": "delivered", "returned": "returned"}[status]
        takip = None if random.random() < 0.05 else f"TRK{ship_id:08d}"  # %5 eksik
        ws.writerow([ship_id, oid, random.choice(CARRIERS), takip, durum,
                     gonderi.isoformat(),
                     None if durum == "in_transit" else teslim.isoformat()])

fo.close(); fi.close(); fs.close()
print(f"orders.csv             {N_ORDERS:>9,} satir")
print(f"order_items.csv        {item_id:>9,} satir")
print(f"shipments.csv          {ship_id:>9,} satir")

# ------------------------------------------------------ siparis-kupon baglari
indirim = {}
f, wr = open_csv("order_coupons.csv", ["order_id", "coupon_id", "discount_applied"])
for oid in range(1, N_ORDERS + 1):
    r = random.random()
    adet = 2 if r < 0.03 else (1 if r < 0.18 else 0)
    if adet == 0:
        continue
    toplam_ind = 0.0
    for cid_, percent, val in random.sample(coupons, adet):
        tutar = order_total[oid] * val / 100 if percent else min(val, order_total[oid] * 0.5)
        tutar = max(round(tutar, 2), 0.01)
        wr.writerow([oid, cid_, tutar])
        toplam_ind += tutar
    indirim[oid] = toplam_ind
f.close()
print(f"order_coupons.csv      {len(indirim):>9,} siparis")

# ------------------------------------------------------------------ odemeler
METHODS = ["card"] * 70 + ["transfer"] * 20 + ["cod"] * 10
pay_id = 0
f, wr = open_csv("payments.csv", ["id", "order_id", "amount", "method", "status", "paid_at"])
for oid in range(1, N_ORDERS + 1):
    odenecek = max(round(order_total[oid] - indirim.get(oid, 0.0), 2), 1.00)
    yontem = random.choice(METHODS)
    if random.random() < 0.08:                      # basarisiz deneme
        pay_id += 1
        wr.writerow([pay_id, oid, odenecek, yontem, "failed", DAYS[0].isoformat()])
    pay_id += 1
    wr.writerow([pay_id, oid, odenecek, yontem, "success", DAYS[0].isoformat()])
f.close()
print(f"payments.csv           {pay_id:>9,} satir")

# ------------------------------------------------------------------ yorumlar
f, wr = open_csv("reviews.csv", ["id", "user_id", "product_id", "rating", "body", "created_at"])
secim = random.sample(review_pool, min(N_REVIEWS, len(review_pool)))
secim += random.sample(secim, 200)                  # ANOMALI: ikinci yorumlar
RATINGS = [5] * 45 + [4] * 30 + [3] * 13 + [2] * 7 + [1] * 5
for i, (uid, pid, when) in enumerate(secim, start=1):
    wr.writerow([i, uid, pid, random.choice(RATINGS),
                 None if random.random() < 0.05 else f"Yorum {i}",  # %5 eksik
                 (when + timedelta(days=random.randint(3, 60))).isoformat()])
f.close()
print(f"reviews.csv            {len(secim):>9,} satir")

# ------------------------------------------- stok girisleri ve duzeltmeleri
for pid in range(1, N_PRODUCTS + 1):
    for _ in range(random.randint(4, 8)):
        mv_id += 1
        wm.writerow([mv_id, pid, None, "purchase", random.randint(50, 500),
                     moment(pick_day(0)).isoformat()])
for _ in range(300):
    mv_id += 1
    miktar = random.choice([-1, 1]) * random.randint(1, 20)
    wm.writerow([mv_id, random.randint(1, N_PRODUCTS), None, "adjustment", miktar,
                 moment(pick_day(0)).isoformat()])
fm.close()
print(f"inventory_movements.csv {mv_id:>8,} satir")
print("\nTamam. Dosyalar: " + OUT)
