-- #####################################################################
-- 05_uji_integritas.sql — pengujian integritas basis data Tugas 6
-- Kelompok 4 (7A1) — SI Pemesanan Pre-Order Kue & Manajemen Inventori Yourfoodoo
-- Jalankan SETELAH 00–04. Jalankan per bagian (blok demi blok) agar setiap hasil bisa di-screenshot.
-- Baris yang diberi tanda "HARUS GAGAL" memang sengaja salah; error dari PostgreSQL = uji LULUS.
-- #####################################################################

SET timezone = 'Asia/Jakarta';


-- =====================================================================
-- BAGIAN 0 — BUKTI BASIS DATA BERJALAN DI LOCALHOST (screenshot 1)
-- PIC: Gerry Robbie AG (23083000147) — PJM Fase 3, penanggung jawab setup basis data
-- =====================================================================
-- [AI] prompt: buatkan query untuk menampilkan versi PostgreSQL, nama database, jumlah baris
--              tiap tabel, dan jumlah foreign key sebagai bukti database berjalan (27 Okt 2026)
SELECT version() AS versi_postgresql, current_database() AS nama_database, inet_server_addr() AS host;

SELECT 'pengguna' AS tabel, COUNT(*) AS jumlah_baris FROM pengguna
UNION ALL SELECT 'kue', COUNT(*) FROM kue
UNION ALL SELECT 'bahan_baku', COUNT(*) FROM bahan_baku
UNION ALL SELECT 'resep_kue', COUNT(*) FROM resep_kue
UNION ALL SELECT 'kuota_harian', COUNT(*) FROM kuota_harian
UNION ALL SELECT 'pesanan', COUNT(*) FROM pesanan
UNION ALL SELECT 'detail_pesanan', COUNT(*) FROM detail_pesanan
UNION ALL SELECT 'pembayaran', COUNT(*) FROM pembayaran
UNION ALL SELECT 'supplier', COUNT(*) FROM supplier
UNION ALL SELECT 'pembelian_bahan', COUNT(*) FROM pembelian_bahan
UNION ALL SELECT 'detail_pembelian', COUNT(*) FROM detail_pembelian
UNION ALL SELECT 'riwayat_stok', COUNT(*) FROM riwayat_stok
UNION ALL SELECT 'pengeluaran_operasional', COUNT(*) FROM pengeluaran_operasional;

SELECT constraint_type, COUNT(*) AS jumlah
FROM information_schema.table_constraints
WHERE table_schema = 'public'
  AND constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY', 'UNIQUE', 'CHECK')
  AND constraint_name NOT LIKE '%_not_null'
GROUP BY constraint_type
ORDER BY constraint_type;                       -- FOREIGN KEY harus 18, PRIMARY KEY harus 13


-- =====================================================================
-- SKENARIO 1 — INSERT DATA VALID (screenshot 2)
-- PIC: Muhammad Jiyad Al Islamy Putra Liony (23083000162) — tabel pesanan, detail_pesanan
-- Pesanan baru Rina Wulandari untuk 30 Okt 2026 (H-3): 3 Matcha Mallow + 3 The Classic, lunas,
-- lalu laporan bayar via tombol WhatsApp. Semua baris harus berhasil masuk dalam satu transaksi.
-- =====================================================================
-- [AI] prompt: buatkan skenario uji INSERT valid: satu pesanan baru beserta detail_pesanan dan
--              pembayaran dalam satu transaksi, mengambil id_pesanan lewat kode_pesanan (27 Okt 2026)
BEGIN;

INSERT INTO pesanan (kode_pesanan, id_pelanggan, id_kuota, waktu_pesan, metode_terima, catatan,
                     skema_bayar, subtotal, ongkir, total, batas_bayar)
VALUES ('YF-261027-002', 6, 7, '2026-10-27 18:10+07', 'ambil', 'Uji skenario 1 (insert valid)',
        'lunas', 78000, NULL, 78000, '2026-10-28 18:10+07');

INSERT INTO detail_pesanan (id_pesanan, id_kue, qty, harga_satuan, subtotal) VALUES
  ((SELECT id_pesanan FROM pesanan WHERE kode_pesanan = 'YF-261027-002'), 2, 3, 13000, 39000),  -- Matcha Mallow
  ((SELECT id_pesanan FROM pesanan WHERE kode_pesanan = 'YF-261027-002'), 4, 3, 13000, 39000);  -- The Classic

INSERT INTO pembayaran (id_pesanan, jenis, nominal, waktu_lapor)
VALUES ((SELECT id_pesanan FROM pesanan WHERE kode_pesanan = 'YF-261027-002'), 'lunas', 78000, '2026-10-27 18:15+07');

UPDATE pesanan SET status_pesanan = 'menunggu_verifikasi' WHERE kode_pesanan = 'YF-261027-002';

COMMIT;

-- Bukti: data baru ada di tiga tabel
SELECT p.kode_pesanan, u.nama AS pelanggan, k.tanggal, ku.nama_kue, d.qty, d.subtotal,
       p.total, p.status_pesanan, b.jenis AS jenis_bayar, b.nominal, b.status_verifikasi
FROM pesanan p
JOIN pengguna u       ON u.id_pengguna = p.id_pelanggan
JOIN kuota_harian k   ON k.id_kuota    = p.id_kuota
JOIN detail_pesanan d ON d.id_pesanan  = p.id_pesanan
JOIN kue ku           ON ku.id_kue     = d.id_kue
JOIN pembayaran b     ON b.id_pesanan  = p.id_pesanan
WHERE p.kode_pesanan = 'YF-261027-002';


-- =====================================================================
-- SKENARIO 2 — INSERT DENGAN FOREIGN KEY YANG TIDAK ADA (screenshot 3)
-- PIC: Gerry Robbie AG (23083000147) — tabel bahan_baku, detail_pembelian
-- Setiap INSERT di bawah HARUS GAGAL dengan error "violates foreign key constraint".
-- =====================================================================
-- [AI] prompt: buatkan 4 INSERT dengan foreign key yang tidak ada di tabel induk untuk menguji
--              fk_bahan_baku_supplier, fk_detail_beli_bahan, fk_detail_pesanan_pesanan,
--              fk_riwayat_pesanan (27 Okt 2026)

-- 2a. bahan baru dengan supplier langganan id 99 (supplier hanya id 1–5)          HARUS GAGAL
INSERT INTO bahan_baku (nama_bahan, satuan, stok_minimum, id_supplier)
VALUES ('Vanili bubuk', 'kg', 0.1, 99);

-- 2b. detail PO-2610-003 untuk bahan id 999 yang tidak ada                       HARUS GAGAL
INSERT INTO detail_pembelian (id_pembelian, id_bahan, qty_dipesan, harga_satuan)
VALUES ((SELECT id_pembelian FROM pembelian_bahan WHERE nomor = 'PO-2610-003'), 999, 2, 50000);

-- 2c. detail pesanan untuk pesanan id 999 yang tidak ada                         HARUS GAGAL
INSERT INTO detail_pesanan (id_pesanan, id_kue, qty, harga_satuan, subtotal)
VALUES (999, 1, 2, 13000, 26000);

-- 2d. potong stok produksi untuk pesanan id 999 yang tidak ada                   HARUS GAGAL
INSERT INTO riwayat_stok (id_bahan, jenis, jumlah, stok_sesudah, id_pesanan, dicatat_oleh)
VALUES (2, 'keluar_produksi', -0.1, 1.88, 999, 2);

-- Bukti: tidak ada satu pun baris yang masuk (semua hasil 0)
SELECT (SELECT COUNT(*) FROM bahan_baku       WHERE nama_bahan = 'Vanili bubuk') AS bahan_vanili,
       (SELECT COUNT(*) FROM detail_pembelian WHERE id_bahan   = 999)            AS detail_beli_999,
       (SELECT COUNT(*) FROM detail_pesanan   WHERE id_pesanan = 999)            AS detail_pesanan_999,
       (SELECT COUNT(*) FROM riwayat_stok     WHERE id_pesanan = 999)            AS riwayat_999;


-- =====================================================================
-- SKENARIO 3 — DELETE TABEL INDUK YANG MASIH DIRUJUK (screenshot 4 dan 5)
-- PIC: Adelio Raihan Aryasatya (23083000152) — tabel pembayaran, riwayat_stok
-- 3a–3d: FK ON DELETE RESTRICT → DELETE HARUS GAGAL (data transaksi terlindungi).
-- 3e   : FK ON DELETE CASCADE  → detail ikut terhapus bersama header-nya.
-- =====================================================================
-- [AI] prompt: buatkan uji DELETE baris induk yang masih dirujuk untuk FK RESTRICT (pesanan,
--              kue, supplier, pengguna) dan satu uji CASCADE pembelian_bahan -> detail_pembelian
--              di dalam transaksi yang di-ROLLBACK (27 Okt 2026)

-- 3a. pesanan yang sudah punya pembayaran dan riwayat stok                       HARUS GAGAL
DELETE FROM pesanan WHERE kode_pesanan = 'YF-261021-001';

-- 3b. kue yang sudah pernah dipesan                                              HARUS GAGAL
DELETE FROM kue WHERE nama_kue = 'Blureo';

-- 3c. supplier yang menjadi supplier langganan bahan dan punya PO                HARUS GAGAL
DELETE FROM supplier WHERE nama_toko = 'UD Sumber Rejeki Bahan Kue';

-- 3d. pelanggan yang sudah punya pesanan                                         HARUS GAGAL
DELETE FROM pengguna WHERE email = 'nadiaputri.rmd@gmail.com';

-- Bukti 3a–3d: data induk masih ada (semua hasil 1)
SELECT (SELECT COUNT(*) FROM pesanan  WHERE kode_pesanan = 'YF-261021-001')              AS pesanan,
       (SELECT COUNT(*) FROM kue      WHERE nama_kue     = 'Blureo')                     AS kue,
       (SELECT COUNT(*) FROM supplier WHERE nama_toko    = 'UD Sumber Rejeki Bahan Kue') AS supplier,
       (SELECT COUNT(*) FROM pengguna WHERE email        = 'nadiaputri.rmd@gmail.com')   AS pengguna;

-- 3e. CASCADE: hapus PO-2610-003 (masih dipesan) → 3 baris detail_pembelian ikut terhapus.
--     Dijalankan dalam transaksi lalu ROLLBACK supaya data awal tetap utuh.
--     id_pembelian 6 = PO-2610-003 (lihat data awal pembelian_bahan)
BEGIN;
SELECT COUNT(*) AS detail_po003_sebelum FROM detail_pembelian WHERE id_pembelian = 6;   -- 3

DELETE FROM pembelian_bahan WHERE nomor = 'PO-2610-003';

SELECT COUNT(*) AS detail_po003_sesudah FROM detail_pembelian WHERE id_pembelian = 6;   -- 0 (ikut terhapus)
ROLLBACK;

SELECT COUNT(*) AS detail_po003_setelah_rollback FROM detail_pembelian WHERE id_pembelian = 6;  -- kembali 3


-- =====================================================================
-- SKENARIO 4 — QUERY JOIN ANTAR TABEL (screenshot 6, 7, 8)
-- PIC: Willy Rafael F. Silalahi (23083000168) — laporan membaca semua tabel
-- Setiap query adalah dasar satu halaman sistem; pemilik halaman ikut menjelaskan query-nya.
-- =====================================================================

-- 4a. Daftar pesanan lengkap (W-08) — pesanan + pengguna + kuota_harian + detail_pesanan + kue
-- [AI] prompt: buatkan query JOIN daftar pesanan berisi kode, pelanggan, tanggal ambil/kirim,
--              isi pesanan per rasa, total, dan status (27 Okt 2026)
SELECT p.kode_pesanan,
       u.nama                AS pelanggan,
       k.tanggal             AS tanggal_ambil_kirim,
       p.metode_terima,
       string_agg(ku.nama_kue || ' x' || d.qty, ', ' ORDER BY ku.nama_kue) AS isi_pesanan,
       p.total,
       p.status_pesanan,
       p.status_pembayaran
FROM pesanan p
JOIN pengguna u       ON u.id_pengguna = p.id_pelanggan
JOIN kuota_harian k   ON k.id_kuota    = p.id_kuota
JOIN detail_pesanan d ON d.id_pesanan  = p.id_pesanan
JOIN kue ku           ON ku.id_kue     = d.id_kue
GROUP BY p.id_pesanan, u.nama, k.tanggal
ORDER BY k.tanggal, p.kode_pesanan;

-- 4b. Sisa kuota per tanggal (W-04 / W-10, AB-02 dan AB-04) — kuota_harian LEFT JOIN pesanan
--     Pesanan menunggu_pembayaran hanya dihitung bila batas_bayar belum lewat.
-- [AI] prompt: buatkan query sisa kuota per tanggal: kapasitas dikurangi pesanan yang mengisi kuota,
--              pesanan belum bayar yang lewat batas_bayar tidak dihitung (27 Okt 2026)
SELECT k.tanggal,
       k.kapasitas,
       COUNT(p.id_pesanan)                AS terisi,
       k.kapasitas - COUNT(p.id_pesanan)  AS sisa,
       k.keterangan
FROM kuota_harian k
LEFT JOIN pesanan p
       ON p.id_kuota = k.id_kuota
      AND (p.status_pesanan IN ('menunggu_verifikasi', 'terkonfirmasi', 'diproduksi', 'siap', 'selesai')
           OR (p.status_pesanan = 'menunggu_pembayaran' AND p.batas_bayar > now()))
GROUP BY k.id_kuota
ORDER BY k.tanggal;

-- 4c. Jadwal produksi dapur per tanggal dan rasa (W-20)
-- [AI] prompt: buatkan query jadwal produksi: jumlah kue per rasa per tanggal untuk pesanan
--              terkonfirmasi, diproduksi, dan siap (27 Okt 2026)
SELECT k.tanggal, ku.nama_kue, SUM(d.qty) AS jumlah_kue, COUNT(DISTINCT p.id_pesanan) AS jumlah_pesanan
FROM pesanan p
JOIN kuota_harian k   ON k.id_kuota   = p.id_kuota
JOIN detail_pesanan d ON d.id_pesanan = p.id_pesanan
JOIN kue ku           ON ku.id_kue    = d.id_kue
WHERE p.status_pesanan IN ('terkonfirmasi', 'diproduksi', 'siap')
GROUP BY k.tanggal, ku.nama_kue
ORDER BY k.tanggal, ku.nama_kue;

-- 4d. Stok tersedia, peringatan, dan saran beli (W-12, AB-08 dan AB-09)
--     bahan_baku + resep_kue + detail_pesanan + pesanan + supplier
-- [AI] prompt: buatkan query stok tersedia = stok - kebutuhan pesanan terkonfirmasi (detail_pesanan x
--              resep_kue), peringatan bila <= stok minimum, saran beli = (kebutuhan + minimum - stok)
--              dibulatkan ke atas ke kelipatan beli, beserta supplier langganan (27 Okt 2026)
WITH kebutuhan AS (
    SELECT r.id_bahan, SUM(d.qty * r.takaran) AS butuh
    FROM pesanan p
    JOIN detail_pesanan d ON d.id_pesanan = p.id_pesanan
    JOIN resep_kue r      ON r.id_kue     = d.id_kue
    WHERE p.status_pesanan = 'terkonfirmasi'
    GROUP BY r.id_bahan
)
SELECT b.nama_bahan,
       b.satuan,
       b.stok_saat_ini,
       COALESCE(k.butuh, 0)                         AS kebutuhan,
       b.stok_saat_ini - COALESCE(k.butuh, 0)       AS stok_tersedia,
       b.stok_minimum,
       CASE WHEN b.stok_saat_ini - COALESCE(k.butuh, 0) <= b.stok_minimum
            THEN 'PERLU BELI' ELSE 'aman' END       AS peringatan,
       CASE WHEN b.stok_saat_ini - COALESCE(k.butuh, 0) <= b.stok_minimum
            THEN CEIL((COALESCE(k.butuh, 0) + b.stok_minimum - b.stok_saat_ini) / b.kelipatan_beli)
                 * b.kelipatan_beli
            ELSE 0 END                              AS saran_beli,
       COALESCE(s.nama_toko, '(beli eceran)')       AS supplier_langganan
FROM bahan_baku b
LEFT JOIN kebutuhan k ON k.id_bahan    = b.id_bahan
LEFT JOIN supplier s  ON s.id_supplier = b.id_supplier
ORDER BY peringatan DESC, b.nama_bahan;

-- 4e. Jejak stok butter (W-21) — riwayat_stok + bahan_baku + pengguna + pesanan + pembelian_bahan
-- [AI] prompt: buatkan query riwayat stok satu bahan yang menampilkan sumber perubahan (kode pesanan
--              atau nomor pembelian) dan siapa yang mencatat (27 Okt 2026)
SELECT r.waktu, b.nama_bahan, r.jenis, r.jumlah, r.stok_sesudah,
       COALESCE(p.kode_pesanan, pb.nomor, r.keterangan) AS sumber,
       u.nama AS dicatat_oleh
FROM riwayat_stok r
JOIN bahan_baku b            ON b.id_bahan      = r.id_bahan
JOIN pengguna u              ON u.id_pengguna   = r.dicatat_oleh
LEFT JOIN pesanan p          ON p.id_pesanan    = r.id_pesanan
LEFT JOIN pembelian_bahan pb ON pb.id_pembelian = r.id_pembelian
WHERE b.nama_bahan = 'Butter'
ORDER BY r.waktu, r.id_riwayat;

-- 4f. Laporan laba bersih Oktober 2026 (W-18, AB-12) — pembayaran, pembelian_bahan, pengeluaran_operasional
--     Laba = pembayaran diterima − (PO diterima + belanja eceran) − pengeluaran operasional.
--     Data awal baru mencakup 18–27 Okt dan pembelian stok pertama, jadi hasilnya wajar masih minus.
-- [AI] prompt: buatkan query laporan laba bersih bulanan dari tiga tabel sesuai AB-12, periode
--              berdasarkan waktu_verifikasi, tanggal_diterima, dan tanggal pengeluaran (27 Okt 2026)
SELECT pemasukan, belanja_bahan, operasional,
       pemasukan - (belanja_bahan + operasional) AS laba_bersih
FROM (
    SELECT
      (SELECT COALESCE(SUM(nominal), 0) FROM pembayaran
        WHERE status_verifikasi = 'diterima'
          AND waktu_verifikasi >= '2026-10-01' AND waktu_verifikasi < '2026-11-01')  AS pemasukan,
      (SELECT COALESCE(SUM(total_biaya), 0) FROM pembelian_bahan
        WHERE status = 'diterima'
          AND tanggal_diterima BETWEEN '2026-10-01' AND '2026-10-31')                AS belanja_bahan,
      (SELECT COALESCE(SUM(nominal), 0) FROM pengeluaran_operasional
        WHERE tanggal BETWEEN '2026-10-01' AND '2026-10-31')                         AS operasional
) AS ringkas;


-- =====================================================================
-- UJI TAMBAHAN A — CONSTRAINT UNIQUE, NOT NULL, CHECK (sesuai template Skenario 2)
-- PIC: masing-masing pemilik tabel
-- Setiap perintah HARUS GAGAL.
-- =====================================================================
-- [AI] prompt: buatkan INSERT yang melanggar UNIQUE, NOT NULL, dan CHECK pada skema Tugas 5
--              (uq_kue_nama, uq_pengguna_email, NOT NULL nama_toko, ck_pesanan_kirim,
--              ck_pengeluaran_kategori, ck_riwayat_sumber) (27 Okt 2026)

-- A1. UNIQUE nama kue (Jiyad)                                                     HARUS GAGAL
INSERT INTO kue (nama_kue, harga) VALUES ('Blureo', 13000);

-- A2. UNIQUE email pengguna (Willy)                                               HARUS GAGAL
INSERT INTO pengguna (nama, email, peran, google_id)
VALUES ('Akun Ganda', 'nadiaputri.rmd@gmail.com', 'pelanggan', '100000000000000000001');

-- A3. NOT NULL nama_toko supplier (Gerry)                                         HARUS GAGAL
INSERT INTO supplier (nama_kontak, no_hp) VALUES ('Pak Joko', '081200000000');

-- A4. CHECK ck_pesanan_kirim: pesanan dikirim wajib DP (AB-03) (Jiyad)            HARUS GAGAL
INSERT INTO pesanan (kode_pesanan, id_pelanggan, id_kuota, metode_terima, alamat_kirim, skema_bayar,
                     subtotal, total, batas_bayar)
VALUES ('YF-261027-099', 5, 8, 'kirim', 'Jl. Kawi No. 12, Kepanjen', 'lunas', 26000, 26000, now() + interval '24 hours');

-- A5. CHECK kategori pengeluaran hanya utilitas/transportasi (Willy)              HARUS GAGAL
INSERT INTO pengeluaran_operasional (tanggal, kategori, deskripsi, nominal, dicatat_oleh)
VALUES ('2026-10-27', 'promosi', 'Iklan Instagram', 50000, 1);

-- A6. CHECK ck_riwayat_sumber: penyesuaian wajib keterangan (Adelio)              HARUS GAGAL
INSERT INTO riwayat_stok (id_bahan, jenis, jumlah, stok_sesudah, dicatat_oleh)
VALUES (5, 'penyesuaian', -2, 106.6, 2);


-- =====================================================================
-- UJI TAMBAHAN B — TRANSAKSI & ROLLBACK (sesuai template Skenario 4, AB-07)
-- PIC: Adelio Raihan Aryasatya (23083000152) — proses "Mulai produksi"
-- Pesanan YF-261025-001 (6 Redvelvet Cheese + 6 Blureo, ambil/kirim 28 Okt) butuh biskuit
-- 6 × 0,008 = 0,048 kg, padahal stok biskuit tinggal 0,028 kg (PO-2610-003 belum datang).
-- Potong stok melanggar ck_bahan_stok (stok >= 0) → seluruh transaksi dibatalkan:
-- status pesanan dan stok bahan lain tidak berubah sedikit pun.
-- =====================================================================
-- [AI] prompt: buatkan simulasi transaksi mulai produksi: ubah status pesanan menjadi diproduksi lalu
--              potong stok semua bahan sesuai resep; bila stok kurang transaksi gagal dan di-ROLLBACK
--              (27 Okt 2026)

-- B0. kondisi sebelum
SELECT kode_pesanan, status_pesanan FROM pesanan WHERE kode_pesanan = 'YF-261025-001';
SELECT nama_bahan, stok_saat_ini FROM bahan_baku WHERE id_bahan IN (1, 2, 11) ORDER BY id_bahan;

BEGIN;
UPDATE pesanan SET status_pesanan = 'diproduksi' WHERE kode_pesanan = 'YF-261025-001';   -- berhasil sementara

UPDATE bahan_baku b                                                                       -- HARUS GAGAL
SET stok_saat_ini = b.stok_saat_ini - k.butuh
FROM (SELECT r.id_bahan, SUM(d.qty * r.takaran) AS butuh
      FROM detail_pesanan d
      JOIN resep_kue r ON r.id_kue = d.id_kue
      WHERE d.id_pesanan = (SELECT id_pesanan FROM pesanan WHERE kode_pesanan = 'YF-261025-001')
      GROUP BY r.id_bahan) AS k
WHERE b.id_bahan = k.id_bahan;
ROLLBACK;

-- B1. kondisi sesudah: status tetap 'terkonfirmasi', stok tepung, butter, biskuit sama seperti B0
SELECT kode_pesanan, status_pesanan FROM pesanan WHERE kode_pesanan = 'YF-261025-001';
SELECT nama_bahan, stok_saat_ini FROM bahan_baku WHERE id_bahan IN (1, 2, 11) ORDER BY id_bahan;
