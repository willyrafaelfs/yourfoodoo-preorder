-- #####################################################################
-- 01_akun_laporan.sql — Modul Akun, Keuangan & Laporan
-- Pemilik modul : Willy Rafael F. Silalahi (NIM 23083000168)
-- Branch        : feature/willy-akun-laporan
-- Proyek        : SI Pemesanan Pre-Order Kue & Manajemen Inventori Yourfoodoo
-- Kelompok 4 (7A1) — MK54 Project SI Terapan 2026/2027 — Tugas 6
-- Urutan jalan  : setelah 00_reset.sql
-- #####################################################################

SET client_encoding = 'UTF8';
SET timezone = 'Asia/Jakarta';

-- =====================================================================
-- Tabel  1 : pengguna
-- Isi      : semua akun: pelanggan (login Google), admin dan staf dapur (email + password)
-- Modul    : Akun, Keuangan & Laporan
-- Pemilik  : Willy Rafael F. Silalahi (NIM 23083000168)
-- Branch   : feature/willy-akun-laporan
-- =====================================================================
-- [AI] prompt: buatkan CREATE TABLE pengguna untuk PostgreSQL sesuai skema final Tugas 5 Bagian K.2 no. 1:
--              PK identity, email dan google_id UNIQUE, CHECK peran, dan ck_pengguna_login (pelanggan wajib
--              google_id, admin/staf wajib password_hash) (27 Okt 2026)
CREATE TABLE pengguna (
    id_pengguna     INTEGER GENERATED ALWAYS AS IDENTITY,
    nama            VARCHAR(100) NOT NULL,
    email           VARCHAR(100) NOT NULL,
    no_hp           VARCHAR(15),                    -- wajib diisi pelanggan sebelum memesan (dicek aplikasi)
    alamat          TEXT,
    patokan_alamat  VARCHAR(150),
    peran           VARCHAR(20)  NOT NULL,
    google_id       VARCHAR(50),                    -- diisi untuk pelanggan (login Google)
    password_hash   VARCHAR(255),                   -- diisi untuk admin dan staf (bcrypt)
    status_aktif    BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT pk_pengguna           PRIMARY KEY (id_pengguna),
    CONSTRAINT uq_pengguna_email     UNIQUE (email),
    CONSTRAINT uq_pengguna_google_id UNIQUE (google_id),
    CONSTRAINT ck_pengguna_peran     CHECK (peran IN ('pelanggan', 'admin', 'staf_dapur')),
    CONSTRAINT ck_pengguna_login     CHECK (
        (peran = 'pelanggan' AND google_id IS NOT NULL)
        OR (peran <> 'pelanggan' AND password_hash IS NOT NULL))
);

-- =====================================================================
-- Tabel 13 : pengeluaran_operasional
-- Isi      : biaya non-bahan; hanya kategori utilitas (gas, listrik, air) dan transportasi
-- Modul    : Akun, Keuangan & Laporan
-- Pemilik  : Willy Rafael F. Silalahi (NIM 23083000168)
-- Branch   : feature/willy-akun-laporan
-- =====================================================================
-- [AI] prompt: buatkan CREATE TABLE pengeluaran_operasional sesuai skema Tugas 5 K.2 no. 13: kategori
--              CHECK IN ('utilitas','transportasi'), nominal > 0, FK dicatat_oleh ke pengguna RESTRICT (27 Okt 2026)
CREATE TABLE pengeluaran_operasional (
    id_pengeluaran  INTEGER GENERATED ALWAYS AS IDENTITY,
    tanggal         DATE          NOT NULL,
    kategori        VARCHAR(20)   NOT NULL,         -- utilitas = gas, listrik, air
    deskripsi       VARCHAR(255)  NOT NULL,
    nominal         NUMERIC(12,2) NOT NULL,
    dicatat_oleh    INTEGER       NOT NULL,
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT pk_pengeluaran_operasional PRIMARY KEY (id_pengeluaran),
    CONSTRAINT ck_pengeluaran_kategori    CHECK (kategori IN ('utilitas', 'transportasi')),
    CONSTRAINT ck_pengeluaran_nominal     CHECK (nominal > 0),
    CONSTRAINT fk_pengeluaran_dicatat_oleh FOREIGN KEY (dicatat_oleh)
        REFERENCES pengguna (id_pengguna) ON DELETE RESTRICT          -- FK no. 17
);


-- ---------------------------------------------------------------- DATA AWAL

-- Data awal pengguna (9 baris) — pemilik: Willy Rafael F. Silalahi (23083000168)
-- [AI] prompt: buatkan data awal realistis tabel pengguna untuk toko kue Yourfoodoo (Gondanglegi, Kab. Malang):
--              1 admin (pemilik), 2 staf dapur, 6 pelanggan login Google (27 Okt 2026)
-- password_hash admin & staf = bcrypt dari password pengembangan 'Yourfoodoo#Dev26' (ganti sebelum produksi)
-- id 1 = admin, id 2-3 = staf dapur, id 4-9 = pelanggan
INSERT INTO pengguna (nama, email, no_hp, alamat, patokan_alamat, peran, google_id, password_hash, created_at) VALUES
  ('Tian Sakara', 'tian.sakara@yourfoodoo.id', '081334521870', 'Jl. Ahmad Yani Perum Kauman Asri No. 3, Gondanglegi Kulon, Kab. Malang', NULL, 'admin', NULL, '$2b$10$T2g6Cx.giFcX1Maohy0iIePojmpSN34fwN1FnN0YulApPvAAy.nQW', '2026-10-18 19:00+07'),
  ('Dewi Anggraini', 'dewi.dapur@yourfoodoo.id', '085755310429', NULL, NULL, 'staf_dapur', NULL, '$2b$10$T2g6Cx.giFcX1Maohy0iIePojmpSN34fwN1FnN0YulApPvAAy.nQW', '2026-10-18 19:10+07'),
  ('Rahma Aulia', 'rahma.dapur@yourfoodoo.id', '082140876615', NULL, NULL, 'staf_dapur', NULL, '$2b$10$T2g6Cx.giFcX1Maohy0iIePojmpSN34fwN1FnN0YulApPvAAy.nQW', '2026-10-18 19:12+07'),
  ('Nadia Putri Ramadhani', 'nadiaputri.rmd@gmail.com', '085731204518', 'Jl. Raya Gondanglegi No. 45, Gondanglegi Wetan, Kab. Malang', 'Depan Masjid Al-Ikhlas', 'pelanggan', '108245731690245118327', NULL, '2026-10-21 19:05+07'),
  ('Bagus Prasetyo', 'bagus.prasetyo21@gmail.com', '081249937702', 'Jl. Kawi No. 12, Kepanjen, Kab. Malang', 'Rumah pagar hijau sebelah apotek', 'pelanggan', '113907452281604937215', NULL, '2026-10-21 21:30+07'),
  ('Rina Wulandari', 'rinawulan.dari@gmail.com', '087859146623', 'Jl. Diponegoro No. 8, Bululawang, Kab. Malang', 'Gang samping SD Negeri 2', 'pelanggan', '104578213369940217766', NULL, '2026-10-22 12:58+07'),
  ('Fajar Nugroho', 'fajarnugroho.tr@gmail.com', '085604718239', 'Jl. Sultan Agung No. 21, Turen, Kab. Malang', 'Seberang toko bangunan Sumber Makmur', 'pelanggan', '117320946658812043591', NULL, '2026-10-24 07:52+07'),
  ('Ayu Kartika Sari', 'ayukartika.s@gmail.com', '081330627145', 'Jl. Hayam Wuruk Gg. 3 No. 5, Gondanglegi Kulon, Kab. Malang', 'Rumah cat kuning ujung gang', 'pelanggan', '102846619035572208143', NULL, '2026-10-24 20:05+07'),
  ('Dimas Ardiansyah', 'dimas.ardiansyah@gmail.com', '089677215408', 'Jl. Panglima Sudirman No. 102, Kepanjen, Kab. Malang', 'Sebelah konter pulsa Dimas Cell', 'pelanggan', '109934582217760351942', NULL, '2026-10-23 09:20+07');

-- Data awal pengeluaran_operasional (6 baris) — pemilik: Willy Rafael F. Silalahi (23083000168)
-- [AI] prompt: buatkan data awal pengeluaran operasional Oktober 2026, kategori hanya utilitas dan transportasi (27 Okt 2026)
INSERT INTO pengeluaran_operasional (tanggal, kategori, deskripsi, nominal, dicatat_oleh, created_at) VALUES
  ('2026-10-18', 'utilitas', 'Isi ulang LPG 12 kg untuk oven', 205000, 1, '2026-10-18 21:00+07'),
  ('2026-10-19', 'transportasi', 'Bensin mengambil bahan PO-2610-001 ke UD Sumber Rejeki', 30000, 1, '2026-10-19 21:00+07'),
  ('2026-10-20', 'utilitas', 'Token listrik PLN rumah produksi', 150000, 1, '2026-10-20 21:00+07'),
  ('2026-10-24', 'transportasi', 'Kurir instan antar pesanan YF-261021-002', 14000, 1, '2026-10-24 21:00+07'),
  ('2026-10-26', 'utilitas', 'Tagihan air PDAM bulan Oktober', 78500, 1, '2026-10-26 21:00+07'),
  ('2026-10-27', 'transportasi', 'Kurir instan antar pesanan YF-261024-003', 16000, 1, '2026-10-27 21:00+07');

