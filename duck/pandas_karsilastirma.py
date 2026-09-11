#!/usr/bin/env python3
"""DuckDB ile pandas'i ayni is uzerinde karsilastirir: sure ve bellek."""

import os
import resource
import time

import duckdb
import pandas as pd

DOSYA = "data/yellow_2024_01.parquet"
print(f"Dosya boyutu: {os.path.getsize(DOSYA) / 1024 / 1024:.1f} MB\n")


def tepe_bellek_mb():
    # Linux'ta ru_maxrss kilobayt cinsindendir
    return resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024


def olc(ad, fn):
    t0 = time.perf_counter()
    sonuc = fn()
    sure = time.perf_counter() - t0
    print(f"{ad:<42} {sure*1000:9.1f} ms   tepe bellek: {tepe_bellek_mb():7.1f} MB")
    return sonuc


print("=== DuckDB (dosyayi hic belege yuklemeden) ===")
con = duckdb.connect()
olc("1. gunluk yolculuk + ortalama tutar", lambda: con.execute(f"""
    SELECT tpep_pickup_datetime::DATE AS gun, count(*), avg(total_amount)
    FROM '{DOSYA}' GROUP BY gun ORDER BY gun""").fetchall())
olc("2. saat bazinda dagilim", lambda: con.execute(f"""
    SELECT extract(hour FROM tpep_pickup_datetime) AS saat, count(*)
    FROM '{DOSYA}' GROUP BY saat ORDER BY saat""").fetchall())
olc("3. odeme tipine gore ortalama bahsis", lambda: con.execute(f"""
    SELECT payment_type, count(*), avg(tip_amount)
    FROM '{DOSYA}' GROUP BY payment_type""").fetchall())

print("\n=== pandas (once tum dosyayi belege yukler) ===")
df = olc("0. parquet dosyasini yukle", lambda: pd.read_parquet(DOSYA))
print(f"{'   DataFrame bellekte':<42} {df.memory_usage(deep=True).sum()/1024/1024:9.1f} MB")

olc("1. gunluk yolculuk + ortalama tutar", lambda: df.groupby(
    df["tpep_pickup_datetime"].dt.date).agg(n=("total_amount", "size"),
                                            ort=("total_amount", "mean")))
olc("2. saat bazinda dagilim", lambda: df.groupby(
    df["tpep_pickup_datetime"].dt.hour).size())
olc("3. odeme tipine gore ortalama bahsis", lambda: df.groupby("payment_type").agg(
    n=("tip_amount", "size"), ort=("tip_amount", "mean")))

print("\n=== Sadece iki kolon okunsa? ===")
olc("DuckDB: 2 kolon", lambda: con.execute(f"""
    SELECT payment_type, avg(tip_amount) FROM '{DOSYA}' GROUP BY payment_type""").fetchall())
olc("pandas: 2 kolon (columns= ile)", lambda: pd.read_parquet(
    DOSYA, columns=["payment_type", "tip_amount"]).groupby("payment_type").mean())
