"""scripts/generate.py ciktisinin dogrulanmasi.

Uretici sabit tohumla (random.seed(42)) calisir, dolayisiyla satir
sayilari deterministiktir. Bu testler iki isi birden yapar:
tekrarlanabilirligi ve dagilimsal gercekciligi dogrular.

Betik subprocess ile degil runpy ile calistirilir; ayni surecte
calistigi icin coverage generate.py'yi olcebilir.
"""

import csv
import os
import runpy

import pytest

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(BASE, "data")
BETIK = os.path.join(BASE, "scripts", "generate.py")

BEKLENEN_DOSYALAR = [
    "categories.csv", "users.csv", "products.csv", "orders.csv",
    "order_items.csv", "payments.csv", "shipments.csv", "coupons.csv",
    "order_coupons.csv", "reviews.csv", "inventory_movements.csv",
]

# Sabit tohumla uretildiginde beklenen satir sayilari.
# Bu degerler degisirse uretici degismis demektir; testin bagirmasi istenir.
BEKLENEN_SATIR = {
    "users.csv": 20_000,
    "products.csv": 2_000,
    "orders.csv": 100_000,
    "coupons.csv": 50,
    "order_items.csv": 168_920,
    "inventory_movements.csv": 164_012,
    "payments.csv": 108_094,
    "shipments.csv": 77_999,
    "reviews.csv": 26_810,
}


def oku(ad):
    with open(os.path.join(OUT, ad), encoding="utf-8") as f:
        return list(csv.DictReader(f))


def satir_sayisi(ad):
    with open(os.path.join(OUT, ad), encoding="utf-8") as f:
        return sum(1 for _ in f) - 1


@pytest.fixture(scope="session", autouse=True)
def veri_uret():
    os.makedirs(OUT, exist_ok=True)
    runpy.run_path(BETIK, run_name="__main__")


def test_butun_dosyalar_uretildi():
    eksik = [a for a in BEKLENEN_DOSYALAR
             if not os.path.exists(os.path.join(OUT, a))]
    assert eksik == [], f"uretilmeyen dosyalar: {eksik}"


@pytest.mark.parametrize("ad,beklenen", sorted(BEKLENEN_SATIR.items()))
def test_satir_sayilari_deterministik(ad, beklenen):
    """Sabit tohum ayni sayilari uretmeli; sapma tekrarlanabilirligin bozuldugunu gosterir."""
    assert satir_sayisi(ad) == beklenen


@pytest.mark.xfail(
    strict=True,
    reason="BILINEN KUSUR: generate.py'de kalem sayisi dongusunun kosulunda hedef "
           "deger her turda yeniden rastgele cekiliyor, bu yuzden ortalama asagi "
           "dusuyor (olculen 1,689 / beklenen 1,98). Duzeltilmedi cunku veri 15 "
           "yazilmis cevapta kullanildi; iyilestirme notu cevaplar.md icinde. "
           "Duzeltildiginde bu test gecer ve strict=True uyarir -- isareti kaldirin.",
)
def test_siparis_basina_ortalama_kalem_sayisi():
    ortalama = satir_sayisi("order_items.csv") / satir_sayisi("orders.csv")
    assert 1.90 <= ortalama <= 2.05, f"olculen ortalama: {ortalama:.3f}"


def test_iade_orani_makul():
    durumlar = [s["status"] for s in oku("orders.csv")]
    oran = durumlar.count("returned") / len(durumlar)
    assert 0.010 <= oran <= 0.035, f"iade orani: {oran:.4f}"


def test_eksik_ulke_orani_makul():
    ulkeler = [u["country"] for u in oku("users.csv")]
    oran = sum(1 for u in ulkeler if not u.strip()) / len(ulkeler)
    assert 0.03 <= oran <= 0.07, f"eksik ulke orani: {oran:.4f}"


def test_yabanci_anahtar_butunlugu():
    siparis_id = {o["id"] for o in oku("orders.csv")}
    urun_id = {p["id"] for p in oku("products.csv")}
    yetim_siparis, yetim_urun = set(), set()
    for k in oku("order_items.csv"):
        if k["order_id"] not in siparis_id:
            yetim_siparis.add(k["order_id"])
        if k["product_id"] not in urun_id:
            yetim_urun.add(k["product_id"])
    assert not yetim_siparis, f"orders'ta bulunmayan order_id: {sorted(yetim_siparis)[:5]}"
    assert not yetim_urun, f"products'ta bulunmayan product_id: {sorted(yetim_urun)[:5]}"
