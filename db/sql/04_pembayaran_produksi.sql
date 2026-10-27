-- #####################################################################
-- 04_pembayaran_produksi.sql — Modul Pembayaran & Produksi
-- Pemilik modul : Adelio Raihan Aryasatya (NIM 23083000152)
-- Branch        : feature/adelio-pembayaran-produksi
-- Proyek        : SI Pemesanan Pre-Order Kue & Manajemen Inventori Yourfoodoo
-- Kelompok 4 (7A1) — MK54 Project SI Terapan 2026/2027 — Tugas 6
-- Urutan jalan  : terakhir (butuh pesanan dan pembelian_bahan)
-- #####################################################################

SET client_encoding = 'UTF8';
SET timezone = 'Asia/Jakarta';

-- =====================================================================
-- Tabel  8 : pembayaran
-- Isi      : setiap laporan bayar dari tombol WhatsApp; diverifikasi admin
-- Modul    : Pembayaran & Produksi
-- Pemilik  : Adelio Raihan Aryasatya (NIM 23083000152)
-- Branch   : feature/adelio-pembayaran-produksi
-- =====================================================================
-- [AI] prompt: buatkan CREATE TABLE pembayaran sesuai skema Tugas 5 K.2 no. 8: jenis dp/pelunasan/lunas,
--              status_verifikasi menunggu/diterima/ditolak/dikembalikan, ck_bayar_verifikasi, FK ke pesanan
--              dan pengguna RESTRICT (27 Okt 2026)
CREATE TABLE pembayaran (
    id_pembayaran      INTEGER GENERATED ALWAYS AS IDENTITY,
    id_pesanan         INTEGER       NOT NULL,
    jenis              VARCHAR(10)   NOT NULL,
    nominal            NUMERIC(12,2) NOT NULL,
    waktu_lapor        TIMESTAMPTZ   NOT NULL DEFAULT now(),
    status_verifikasi  VARCHAR(15)   NOT NULL DEFAULT 'menunggu',
    diverifikasi_oleh  INTEGER,
    waktu_verifikasi   TIMESTAMPTZ,                 -- dasar periode laporan (AB-12)
    catatan            VARCHAR(255),                -- alasan tolak atau pengembalian
    CONSTRAINT pk_pembayaran           PRIMARY KEY (id_pembayaran),
    CONSTRAINT ck_bayar_jenis          CHECK (jenis IN ('dp', 'pelunasan', 'lunas')),
    CONSTRAINT ck_bayar_nominal        CHECK (nominal > 0),
    CONSTRAINT ck_bayar_status         CHECK (status_verifikasi IN ('menunggu', 'diterima', 'ditolak', 'dikembalikan')),
    CONSTRAINT ck_bayar_verifikasi     CHECK (status_verifikasi = 'menunggu'
                                           OR (diverifikasi_oleh IS NOT NULL AND waktu_verifikasi IS NOT NULL)),
    CONSTRAINT fk_bayar_pesanan        FOREIGN KEY (id_pesanan)
        REFERENCES pesanan (id_pesanan) ON DELETE RESTRICT,           -- FK no. 7
    CONSTRAINT fk_bayar_diverifikasi   FOREIGN KEY (diverifikasi_oleh)
        REFERENCES pengguna (id_pengguna) ON DELETE RESTRICT          -- FK no. 8
);

-- =====================================================================
-- Tabel 12 : riwayat_stok
-- Isi      : log setiap perubahan stok; jumlah positif = masuk, negatif = keluar
-- Modul    : Pembayaran & Produksi
-- Pemilik  : Adelio Raihan Aryasatya (NIM 23083000152)
-- Branch   : feature/adelio-pembayaran-produksi
-- =====================================================================
-- [AI] prompt: buatkan CREATE TABLE riwayat_stok sesuai skema Tugas 5 K.2 no. 12: PK BIGINT identity,
--              jenis masuk_pembelian/keluar_produksi/penyesuaian, jumlah <> 0, ck_riwayat_sumber, FK ke
--              bahan_baku, pesanan, pembelian_bahan, pengguna semuanya RESTRICT (27 Okt 2026)
CREATE TABLE riwayat_stok (
    id_riwayat    BIGINT GENERATED ALWAYS AS IDENTITY,
    id_bahan      INTEGER       NOT NULL,
    jenis         VARCHAR(20)   NOT NULL,
    jumlah        NUMERIC(12,3) NOT NULL,           -- + masuk, - keluar
    stok_sesudah  NUMERIC(12,3) NOT NULL,
    id_pesanan    INTEGER,                          -- diisi untuk keluar_produksi
    id_pembelian  INTEGER,                          -- diisi untuk masuk_pembelian
    dicatat_oleh  INTEGER       NOT NULL,
    keterangan    VARCHAR(255),                     -- wajib untuk penyesuaian
    waktu         TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT pk_riwayat_stok          PRIMARY KEY (id_riwayat),
    CONSTRAINT ck_riwayat_jenis         CHECK (jenis IN ('masuk_pembelian', 'keluar_produksi', 'penyesuaian')),
    CONSTRAINT ck_riwayat_jumlah        CHECK (jumlah <> 0),
    CONSTRAINT ck_riwayat_sumber        CHECK (
        (jenis = 'keluar_produksi' AND id_pesanan IS NOT NULL)
        OR (jenis = 'masuk_pembelian' AND id_pembelian IS NOT NULL)
        OR (jenis = 'penyesuaian' AND keterangan IS NOT NULL)),
    CONSTRAINT fk_riwayat_bahan         FOREIGN KEY (id_bahan)
        REFERENCES bahan_baku (id_bahan) ON DELETE RESTRICT,          -- FK no. 13
    CONSTRAINT fk_riwayat_pesanan       FOREIGN KEY (id_pesanan)
        REFERENCES pesanan (id_pesanan) ON DELETE RESTRICT,           -- FK no. 14
    CONSTRAINT fk_riwayat_pembelian     FOREIGN KEY (id_pembelian)
        REFERENCES pembelian_bahan (id_pembelian) ON DELETE RESTRICT, -- FK no. 15
    CONSTRAINT fk_riwayat_dicatat_oleh  FOREIGN KEY (dicatat_oleh)
        REFERENCES pengguna (id_pengguna) ON DELETE RESTRICT          -- FK no. 16
);


-- ---------------------------------------------------------------- DATA AWAL

-- Data awal pembayaran (15 baris) — pemilik: Adelio Raihan Aryasatya (23083000152)
-- [AI] prompt: buatkan data awal pembayaran: DP 50%, pelunasan (sisa + ongkir), lunas, satu ditolak karena
--              nominal kurang, dan yang masih menunggu verifikasi (27 Okt 2026)
INSERT INTO pembayaran (id_pesanan, jenis, nominal, waktu_lapor, status_verifikasi, diverifikasi_oleh, waktu_verifikasi, catatan) VALUES
  (1, 'lunas', 156000, '2026-10-21 19:30+07', 'diterima', 1, '2026-10-21 20:05+07', NULL),  -- YF-261021-001
  (2, 'dp', 65000, '2026-10-21 22:00+07', 'diterima', 1, '2026-10-22 08:10+07', NULL),  -- YF-261021-002
  (3, 'dp', 78000, '2026-10-22 13:20+07', 'diterima', 1, '2026-10-22 15:00+07', NULL),  -- YF-261022-001
  (4, 'lunas', 120000, '2026-10-23 09:45+07', 'ditolak', 1, '2026-10-23 10:20+07', 'Nominal transfer kurang Rp10.000 dari total pesanan'),  -- YF-261023-001
  (4, 'lunas', 130000, '2026-10-23 11:00+07', 'diterima', 1, '2026-10-23 11:15+07', NULL),  -- YF-261023-001
  (2, 'pelunasan', 79000, '2026-10-23 10:15+07', 'diterima', 1, '2026-10-23 10:40+07', 'Termasuk ongkir kurir Rp14.000'),  -- YF-261021-002
  (3, 'pelunasan', 78000, '2026-10-24 16:00+07', 'diterima', 1, '2026-10-24 16:30+07', NULL),  -- YF-261022-001
  (6, 'lunas', 156000, '2026-10-24 20:30+07', 'diterima', 1, '2026-10-25 08:00+07', NULL),  -- YF-261024-002
  (7, 'dp', 104000, '2026-10-24 22:10+07', 'diterima', 1, '2026-10-25 08:05+07', NULL),  -- YF-261024-003
  (8, 'dp', 78000, '2026-10-25 10:20+07', 'diterima', 1, '2026-10-25 12:00+07', NULL),  -- YF-261025-001
  (9, 'lunas', 130000, '2026-10-25 17:00+07', 'diterima', 1, '2026-10-25 18:30+07', NULL),  -- YF-261025-002
  (7, 'pelunasan', 120000, '2026-10-26 12:00+07', 'diterima', 1, '2026-10-26 12:30+07', 'Termasuk ongkir kurir Rp16.000'),  -- YF-261024-003
  (10, 'lunas', 104000, '2026-10-26 19:20+07', 'diterima', 1, '2026-10-26 20:00+07', NULL),  -- YF-261026-001
  (11, 'dp', 65000, '2026-10-27 08:15+07', 'menunggu', NULL, NULL, NULL),  -- YF-261026-002
  (8, 'pelunasan', 93000, '2026-10-27 16:40+07', 'menunggu', NULL, NULL, 'Termasuk ongkir kurir Rp15.000');  -- YF-261025-001

-- Data awal riwayat_stok (95 baris) — pemilik: Adelio Raihan Aryasatya (23083000152)
-- [AI] prompt: buatkan data awal riwayat_stok yang konsisten: stok awal (stock opname), masuk dari pembelian
--              yang diterima, keluar produksi = qty kue x takaran resep, satu penyesuaian telur pecah;
--              stok_sesudah berurutan per bahan (27 Okt 2026)
-- Urut waktu. stok_sesudah = stok bahan setelah baris ini; baris terakhir per bahan = bahan_baku.stok_saat_ini
INSERT INTO riwayat_stok (id_bahan, jenis, jumlah, stok_sesudah, id_pesanan, id_pembelian, dicatat_oleh, keterangan, waktu) VALUES
  (1, 'penyesuaian', 4.5, 4.5, NULL, NULL, 1, 'Stok awal hasil stock opname sebelum sistem dipakai', '2026-10-18 20:00+07'),
  (2, 'penyesuaian', 1.8, 1.8, NULL, NULL, 1, 'Stok awal hasil stock opname sebelum sistem dipakai', '2026-10-18 20:00+07'),
  (3, 'penyesuaian', 3, 3, NULL, NULL, 1, 'Stok awal hasil stock opname sebelum sistem dipakai', '2026-10-18 20:00+07'),
  (4, 'penyesuaian', 1.2, 1.2, NULL, NULL, 1, 'Stok awal hasil stock opname sebelum sistem dipakai', '2026-10-18 20:00+07'),
  (5, 'penyesuaian', 40, 40, NULL, NULL, 1, 'Stok awal hasil stock opname sebelum sistem dipakai', '2026-10-18 20:00+07'),
  (6, 'penyesuaian', 0.8, 0.8, NULL, NULL, 1, 'Stok awal hasil stock opname sebelum sistem dipakai', '2026-10-18 20:00+07'),
  (7, 'penyesuaian', 0.6, 0.6, NULL, NULL, 1, 'Stok awal hasil stock opname sebelum sistem dipakai', '2026-10-18 20:00+07'),
  (8, 'penyesuaian', 0.08, 0.08, NULL, NULL, 1, 'Stok awal hasil stock opname sebelum sistem dipakai', '2026-10-18 20:00+07'),
  (9, 'penyesuaian', 0.4, 0.4, NULL, NULL, 1, 'Stok awal hasil stock opname sebelum sistem dipakai', '2026-10-18 20:00+07'),
  (10, 'penyesuaian', 0.3, 0.3, NULL, NULL, 1, 'Stok awal hasil stock opname sebelum sistem dipakai', '2026-10-18 20:00+07'),
  (11, 'penyesuaian', 0.06, 0.06, NULL, NULL, 1, 'Stok awal hasil stock opname sebelum sistem dipakai', '2026-10-18 20:00+07'),
  (12, 'penyesuaian', 1, 1, NULL, NULL, 1, 'Stok awal hasil stock opname sebelum sistem dipakai', '2026-10-18 20:00+07'),
  (13, 'penyesuaian', 1, 1, NULL, NULL, 1, 'Stok awal hasil stock opname sebelum sistem dipakai', '2026-10-18 20:00+07'),
  (14, 'penyesuaian', 60, 60, NULL, NULL, 1, 'Stok awal hasil stock opname sebelum sistem dipakai', '2026-10-18 20:00+07'),
  (1, 'masuk_pembelian', 5, 9.5, NULL, 1, 1, NULL, '2026-10-19 14:00+07'),
  (2, 'masuk_pembelian', 1, 2.8, NULL, 1, 1, NULL, '2026-10-19 14:00+07'),
  (3, 'masuk_pembelian', 2, 5, NULL, 1, 1, NULL, '2026-10-19 14:00+07'),
  (4, 'masuk_pembelian', 2, 3.2, NULL, 1, 1, NULL, '2026-10-19 14:00+07'),
  (6, 'masuk_pembelian', 2, 2.8, NULL, 1, 1, NULL, '2026-10-19 14:00+07'),
  (7, 'masuk_pembelian', 0.5, 1.1, NULL, 1, 1, NULL, '2026-10-19 14:00+07'),
  (9, 'masuk_pembelian', 1, 1.4, NULL, 1, 1, NULL, '2026-10-19 14:00+07'),
  (5, 'masuk_pembelian', 88, 128, NULL, 2, 1, NULL, '2026-10-21 10:00+07'),
  (14, 'masuk_pembelian', 200, 260, NULL, 3, 1, NULL, '2026-10-22 11:00+07'),
  (8, 'masuk_pembelian', 0.2, 0.28, NULL, 4, 1, NULL, '2026-10-23 15:00+07'),
  (10, 'masuk_pembelian', 1, 1.3, NULL, 4, 1, NULL, '2026-10-23 15:00+07'),
  (12, 'masuk_pembelian', 1, 2, NULL, 4, 1, NULL, '2026-10-23 15:00+07'),
  (13, 'masuk_pembelian', 1, 2, NULL, 4, 1, NULL, '2026-10-23 15:00+07'),
  (1, 'keluar_produksi', -0.18, 9.32, 1, NULL, 2, NULL, '2026-10-24 06:00+07'),
  (2, 'keluar_produksi', -0.12, 2.68, 1, NULL, 2, NULL, '2026-10-24 06:00+07'),
  (3, 'keluar_produksi', -0.048, 4.952, 1, NULL, 2, NULL, '2026-10-24 06:00+07'),
  (4, 'keluar_produksi', -0.048, 3.152, 1, NULL, 2, NULL, '2026-10-24 06:00+07'),
  (5, 'keluar_produksi', -2.4, 125.6, 1, NULL, 2, NULL, '2026-10-24 06:00+07'),
  (6, 'keluar_produksi', -0.108, 2.692, 1, NULL, 2, NULL, '2026-10-24 06:00+07'),
  (7, 'keluar_produksi', -0.024, 1.076, 1, NULL, 2, NULL, '2026-10-24 06:00+07'),
  (14, 'keluar_produksi', -12, 248, 1, NULL, 2, NULL, '2026-10-24 06:00+07'),
  (1, 'keluar_produksi', -0.15, 9.17, 2, NULL, 2, NULL, '2026-10-24 06:00+07'),
  (2, 'keluar_produksi', -0.1, 2.58, 2, NULL, 2, NULL, '2026-10-24 06:00+07'),
  (3, 'keluar_produksi', -0.04, 4.912, 2, NULL, 2, NULL, '2026-10-24 06:00+07'),
  (4, 'keluar_produksi', -0.04, 3.112, 2, NULL, 2, NULL, '2026-10-24 06:00+07'),
  (5, 'keluar_produksi', -2, 123.6, 2, NULL, 2, NULL, '2026-10-24 06:00+07'),
  (7, 'keluar_produksi', -0.008, 1.068, 2, NULL, 2, NULL, '2026-10-24 06:00+07'),
  (8, 'keluar_produksi', -0.01, 0.27, 2, NULL, 2, NULL, '2026-10-24 06:00+07'),
  (9, 'keluar_produksi', -0.04, 1.36, 2, NULL, 2, NULL, '2026-10-24 06:00+07'),
  (10, 'keluar_produksi', -0.03, 1.27, 2, NULL, 2, NULL, '2026-10-24 06:00+07'),
  (12, 'keluar_produksi', -0.1, 1.9, 2, NULL, 2, NULL, '2026-10-24 06:00+07'),
  (14, 'keluar_produksi', -10, 238, 2, NULL, 2, NULL, '2026-10-24 06:00+07'),
  (3, 'masuk_pembelian', 2, 6.912, NULL, 5, 1, NULL, '2026-10-24 16:00+07'),
  (1, 'keluar_produksi', -0.18, 8.99, 3, NULL, 3, NULL, '2026-10-25 06:00+07'),
  (2, 'keluar_produksi', -0.12, 2.46, 3, NULL, 3, NULL, '2026-10-25 06:00+07'),
  (3, 'keluar_produksi', -0.048, 6.864, 3, NULL, 3, NULL, '2026-10-25 06:00+07'),
  (4, 'keluar_produksi', -0.048, 3.064, 3, NULL, 3, NULL, '2026-10-25 06:00+07'),
  (5, 'keluar_produksi', -2.4, 121.2, 3, NULL, 3, NULL, '2026-10-25 06:00+07'),
  (6, 'keluar_produksi', -0.032, 2.66, 3, NULL, 3, NULL, '2026-10-25 06:00+07'),
  (7, 'keluar_produksi', -0.006, 1.062, 3, NULL, 3, NULL, '2026-10-25 06:00+07'),
  (9, 'keluar_produksi', -0.032, 1.328, 3, NULL, 3, NULL, '2026-10-25 06:00+07'),
  (11, 'keluar_produksi', -0.032, 0.028, 3, NULL, 3, NULL, '2026-10-25 06:00+07'),
  (12, 'keluar_produksi', -0.08, 1.82, 3, NULL, 3, NULL, '2026-10-25 06:00+07'),
  (13, 'keluar_produksi', -0.08, 1.92, 3, NULL, 3, NULL, '2026-10-25 06:00+07'),
  (14, 'keluar_produksi', -12, 226, 3, NULL, 3, NULL, '2026-10-25 06:00+07'),
  (1, 'keluar_produksi', -0.15, 8.84, 4, NULL, 2, NULL, '2026-10-26 06:00+07'),
  (2, 'keluar_produksi', -0.1, 2.36, 4, NULL, 2, NULL, '2026-10-26 06:00+07'),
  (3, 'keluar_produksi', -0.04, 6.824, 4, NULL, 2, NULL, '2026-10-26 06:00+07'),
  (4, 'keluar_produksi', -0.04, 3.024, 4, NULL, 2, NULL, '2026-10-26 06:00+07'),
  (5, 'keluar_produksi', -2, 119.2, 4, NULL, 2, NULL, '2026-10-26 06:00+07'),
  (6, 'keluar_produksi', -0.1, 2.56, 4, NULL, 2, NULL, '2026-10-26 06:00+07'),
  (7, 'keluar_produksi', -0.04, 1.022, 4, NULL, 2, NULL, '2026-10-26 06:00+07'),
  (14, 'keluar_produksi', -10, 216, 4, NULL, 2, NULL, '2026-10-26 06:00+07'),
  (5, 'penyesuaian', -3, 116.2, NULL, NULL, 2, 'Telur pecah saat ditata di kulkas', '2026-10-26 09:00+07'),
  (1, 'keluar_produksi', -0.18, 8.66, 6, NULL, 3, NULL, '2026-10-27 06:00+07'),
  (2, 'keluar_produksi', -0.12, 2.24, 6, NULL, 3, NULL, '2026-10-27 06:00+07'),
  (3, 'keluar_produksi', -0.048, 6.776, 6, NULL, 3, NULL, '2026-10-27 06:00+07'),
  (4, 'keluar_produksi', -0.048, 2.976, 6, NULL, 3, NULL, '2026-10-27 06:00+07'),
  (5, 'keluar_produksi', -2.4, 113.8, 6, NULL, 3, NULL, '2026-10-27 06:00+07'),
  (7, 'keluar_produksi', -0.009, 1.013, 6, NULL, 3, NULL, '2026-10-27 06:00+07'),
  (8, 'keluar_produksi', -0.012, 0.258, 6, NULL, 3, NULL, '2026-10-27 06:00+07'),
  (9, 'keluar_produksi', -0.048, 1.28, 6, NULL, 3, NULL, '2026-10-27 06:00+07'),
  (10, 'keluar_produksi', -0.036, 1.234, 6, NULL, 3, NULL, '2026-10-27 06:00+07'),
  (12, 'keluar_produksi', -0.12, 1.7, 6, NULL, 3, NULL, '2026-10-27 06:00+07'),
  (14, 'keluar_produksi', -12, 204, 6, NULL, 3, NULL, '2026-10-27 06:00+07'),
  (1, 'keluar_produksi', -0.24, 8.42, 7, NULL, 3, NULL, '2026-10-27 06:00+07'),
  (2, 'keluar_produksi', -0.16, 2.08, 7, NULL, 3, NULL, '2026-10-27 06:00+07'),
  (3, 'keluar_produksi', -0.064, 6.712, 7, NULL, 3, NULL, '2026-10-27 06:00+07'),
  (4, 'keluar_produksi', -0.064, 2.912, 7, NULL, 3, NULL, '2026-10-27 06:00+07'),
  (5, 'keluar_produksi', -3.2, 110.6, 7, NULL, 3, NULL, '2026-10-27 06:00+07'),
  (6, 'keluar_produksi', -0.144, 2.416, 7, NULL, 3, NULL, '2026-10-27 06:00+07'),
  (7, 'keluar_produksi', -0.032, 0.981, 7, NULL, 3, NULL, '2026-10-27 06:00+07'),
  (14, 'keluar_produksi', -16, 188, 7, NULL, 3, NULL, '2026-10-27 06:00+07'),
  (1, 'keluar_produksi', -0.15, 8.27, 9, NULL, 2, NULL, '2026-10-27 13:00+07'),
  (2, 'keluar_produksi', -0.1, 1.98, 9, NULL, 2, NULL, '2026-10-27 13:00+07'),
  (3, 'keluar_produksi', -0.04, 6.672, 9, NULL, 2, NULL, '2026-10-27 13:00+07'),
  (4, 'keluar_produksi', -0.04, 2.872, 9, NULL, 2, NULL, '2026-10-27 13:00+07'),
  (5, 'keluar_produksi', -2, 108.6, 9, NULL, 2, NULL, '2026-10-27 13:00+07'),
  (6, 'keluar_produksi', -0.09, 2.326, 9, NULL, 2, NULL, '2026-10-27 13:00+07'),
  (7, 'keluar_produksi', -0.02, 0.961, 9, NULL, 2, NULL, '2026-10-27 13:00+07'),
  (14, 'keluar_produksi', -10, 178, 9, NULL, 2, NULL, '2026-10-27 13:00+07');