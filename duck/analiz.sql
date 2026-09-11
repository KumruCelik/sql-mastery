.timer on

-- 1) Kapsam ve tarih araligi
SELECT count(*) AS yolculuk,
       min(tpep_pickup_datetime) AS ilk,
       max(tpep_pickup_datetime) AS son
FROM 'data/yellow_2024_01.parquet';

-- 2) Gunluk yolculuk ve ortalama ucret (ilk 10 gun)
SELECT tpep_pickup_datetime::DATE AS gun,
       count(*)                   AS yolculuk,
       round(avg(total_amount),2) AS ort_tutar
FROM 'data/yellow_2024_01.parquet'
WHERE tpep_pickup_datetime >= '2024-01-01' AND tpep_pickup_datetime < '2024-02-01'
GROUP BY gun ORDER BY gun LIMIT 10;

-- 3) Saat bazinda yolculuk dagilimi
SELECT extract(hour FROM tpep_pickup_datetime) AS saat,
       count(*) AS yolculuk,
       round(100.0*count(*)/sum(count(*)) OVER (),2) AS yuzde
FROM 'data/yellow_2024_01.parquet'
GROUP BY saat ORDER BY saat;

-- 4) Odeme tipine gore dagilim ve bahsis
SELECT payment_type,
       count(*) AS yolculuk,
       round(avg(tip_amount),2) AS ort_bahsis,
       round(avg(total_amount),2) AS ort_tutar
FROM 'data/yellow_2024_01.parquet'
GROUP BY payment_type ORDER BY yolculuk DESC;

-- 5) En cok kullanilan 10 alis noktasi
SELECT PULocationID, count(*) AS yolculuk, round(avg(trip_distance),2) AS ort_mesafe
FROM 'data/yellow_2024_01.parquet'
GROUP BY PULocationID ORDER BY yolculuk DESC LIMIT 10;

-- 6) Mesafe bantlarina gore ortalama ucret
SELECT CASE WHEN trip_distance < 1 THEN '0-1 mil'
            WHEN trip_distance < 3 THEN '1-3 mil'
            WHEN trip_distance < 10 THEN '3-10 mil'
            ELSE '10+ mil' END AS bant,
       count(*) AS yolculuk,
       round(avg(fare_amount),2) AS ort_ucret,
       round(avg(total_amount/nullif(trip_distance,0)),2) AS mil_basina
FROM 'data/yellow_2024_01.parquet'
WHERE trip_distance > 0
GROUP BY bant ORDER BY min(trip_distance);

-- 7) Bahsis oraninin yuzdelikleri (kartli odemelerde)
SELECT round(quantile_cont(tip_amount/nullif(fare_amount,0), 0.25),4) AS p25,
       round(quantile_cont(tip_amount/nullif(fare_amount,0), 0.50),4) AS medyan,
       round(quantile_cont(tip_amount/nullif(fare_amount,0), 0.75),4) AS p75,
       round(quantile_cont(tip_amount/nullif(fare_amount,0), 0.95),4) AS p95
FROM 'data/yellow_2024_01.parquet'
WHERE payment_type = 1 AND fare_amount > 0;

-- 8) Yolcu sayisina gore mesafe ve ucret
SELECT passenger_count, count(*) AS yolculuk,
       round(avg(trip_distance),2) AS ort_mesafe,
       round(avg(total_amount),2)  AS ort_tutar
FROM 'data/yellow_2024_01.parquet'
GROUP BY passenger_count ORDER BY passenger_count NULLS LAST;

-- 9) En pahali 10 yolculuk (anomali avi)
SELECT tpep_pickup_datetime, trip_distance, fare_amount, tip_amount, total_amount
FROM 'data/yellow_2024_01.parquet'
ORDER BY total_amount DESC LIMIT 10;

-- 10) Veri kalitesi kontrolleri
SELECT count(*) FILTER (WHERE total_amount < 0)                              AS negatif_tutar,
       count(*) FILTER (WHERE trip_distance = 0)                             AS sifir_mesafe,
       count(*) FILTER (WHERE tpep_dropoff_datetime < tpep_pickup_datetime)  AS varis_kalkistan_once,
       count(*) FILTER (WHERE tpep_pickup_datetime < '2024-01-01'
                           OR tpep_pickup_datetime >= '2024-02-01')          AS ay_disinda,
       count(*) FILTER (WHERE passenger_count IS NULL)                       AS yolcu_sayisi_bos
FROM 'data/yellow_2024_01.parquet';
