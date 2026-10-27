-- #####################################################################
-- 03_katalog_pesanan.sql — Modul Katalog & Pemesanan
-- Pemilik modul : Muhammad Jiyad Al Islamy Putra Liony (NIM 23083000162)
-- Branch        : feature/jiyad-katalog-pesanan
-- Proyek        : SI Pemesanan Pre-Order Kue & Manajemen Inventori Yourfoodoo
-- Kelompok 4 (7A1) — MK54 Project SI Terapan 2026/2027 — Tugas 6
-- Urutan jalan  : setelah 02 (resep_kue butuh bahan_baku)
-- #####################################################################

SET client_encoding = 'UTF8';
SET timezone = 'Asia/Jakarta';

-- =====================================================================
-- Tabel  2 : kue
-- Isi      : katalog 5 rasa Premium Soft Cookies 45 gr @ Rp13.000
-- Modul    : Katalog & Pemesanan
-- Pemilik  : Muhammad Jiyad Al Islamy Putra Liony (NIM 23083000162)
-- Branch   : feature/jiyad-katalog-pesanan
-- =====================================================================
-- [AI] prompt: buatkan CREATE TABLE kue sesuai skema Tugas 5 K.2 no. 2: nama_kue UNIQUE, berat default 45, harga > 0 (27 Okt 2026)
CREATE TABLE kue (
    id_kue        INTEGER GENERATED ALWAYS AS IDENTITY,
    nama_kue      VARCHAR(100)  NOT NULL,
    deskripsi     TEXT,
    berat_gram    SMALLINT      NOT NULL DEFAULT 45,
    harga         NUMERIC(10,2) NOT NULL,
    foto          VARCHAR(255),                     -- kunci file di Netlify Blobs
    status_aktif  BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT pk_kue       PRIMARY KEY (id_kue),
    CONSTRAINT uq_kue_nama  UNIQUE (nama_kue),
    CONSTRAINT ck_kue_berat CHECK (berat_gram > 0),
    CONSTRAINT ck_kue_harga CHECK (harga > 0)
);

-- =====================================================================
-- Tabel  4 : resep_kue
-- Isi      : takaran bahan untuk 1 kue (dipakai potong stok AB-07)
-- Modul    : Katalog & Pemesanan
-- Pemilik  : Muhammad Jiyad Al Islamy Putra Liony (NIM 23083000162)
-- Branch   : feature/jiyad-katalog-pesanan
-- =====================================================================
-- [AI] prompt: buatkan CREATE TABLE resep_kue sesuai skema Tugas 5 K.2 no. 4: FK id_kue CASCADE, FK id_bahan
--              RESTRICT, takaran NUMERIC(10,4) > 0, uq_resep (id_kue, id_bahan) (27 Okt 2026)
CREATE TABLE resep_kue (
    id_resep  INTEGER GENERATED ALWAYS AS IDENTITY,
    id_kue    INTEGER       NOT NULL,
    id_bahan  INTEGER       NOT NULL,
    takaran   NUMERIC(10,4) NOT NULL,               -- per 1 kue, satuan mengikuti bahan_baku.satuan
    CONSTRAINT pk_resep_kue      PRIMARY KEY (id_resep),
    CONSTRAINT uq_resep          UNIQUE (id_kue, id_bahan),
    CONSTRAINT ck_resep_takaran  CHECK (takaran > 0),
    CONSTRAINT fk_resep_kue      FOREIGN KEY (id_kue)
        REFERENCES kue (id_kue) ON DELETE CASCADE,                    -- FK no. 5
    CONSTRAINT fk_resep_bahan    FOREIGN KEY (id_bahan)
        REFERENCES bahan_baku (id_bahan) ON DELETE RESTRICT           -- FK no. 6
);

-- =====================================================================
-- Tabel  5 : kuota_harian
-- Isi      : kapasitas pesanan per tanggal ambil/kirim (default 15, 0 = tutup)
-- Modul    : Katalog & Pemesanan
-- Pemilik  : Muhammad Jiyad Al Islamy Putra Liony (NIM 23083000162)
-- Branch   : feature/jiyad-katalog-pesanan
-- =====================================================================
-- [AI] prompt: buatkan CREATE TABLE kuota_harian sesuai skema Tugas 5 K.2 no. 5: tanggal UNIQUE, kapasitas default 15 (27 Okt 2026)
CREATE TABLE kuota_harian (
    id_kuota    INTEGER GENERATED ALWAYS AS IDENTITY,
    tanggal     DATE         NOT NULL,
    kapasitas   SMALLINT     NOT NULL DEFAULT 15,
    keterangan  VARCHAR(150),
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT pk_kuota_harian     PRIMARY KEY (id_kuota),
    CONSTRAINT uq_kuota_tanggal    UNIQUE (tanggal),
    CONSTRAINT ck_kuota_kapasitas  CHECK (kapasitas >= 0)
);

-- =====================================================================
-- Tabel  6 : pesanan
-- Isi      : header pre-order; kode YF-yymmdd-nnn
-- Modul    : Katalog & Pemesanan
-- Pemilik  : Muhammad Jiyad Al Islamy Putra Liony (NIM 23083000162)
-- Branch   : feature/jiyad-katalog-pesanan
-- =====================================================================
-- [AI] prompt: buatkan CREATE TABLE pesanan sesuai skema Tugas 5 K.2 no. 6: CHECK status_pesanan,
--              status_pembayaran, metode_terima, skema_bayar; ck_pesanan_kirim, ck_pesanan_selesai,
--              ck_pesanan_batal; FK ke pengguna dan kuota_harian RESTRICT; index idx_pesanan_id_pelanggan
--              dan idx_pesanan_id_kuota (27 Okt 2026)
CREATE TABLE pesanan (
    id_pesanan         INTEGER GENERATED ALWAYS AS IDENTITY,
    kode_pesanan       VARCHAR(20)   NOT NULL,      -- YF-yymmdd-nnn
    id_pelanggan       INTEGER       NOT NULL,
    id_kuota           INTEGER       NOT NULL,
    waktu_pesan        TIMESTAMPTZ   NOT NULL DEFAULT now(),
    metode_terima      VARCHAR(10)   NOT NULL,
    alamat_kirim       TEXT,
    patokan_alamat     VARCHAR(150),
    catatan            VARCHAR(255),
    skema_bayar        VARCHAR(10)   NOT NULL,
    subtotal           NUMERIC(12,2) NOT NULL,
    ongkir             NUMERIC(12,2),               -- NULL = belum diisi admin (AB-11)
    total              NUMERIC(12,2) NOT NULL,      -- subtotal + ongkir, dihitung aplikasi
    batas_bayar        TIMESTAMPTZ   NOT NULL,      -- waktu_pesan + 24 jam (AB-04)
    status_pesanan     VARCHAR(25)   NOT NULL DEFAULT 'menunggu_pembayaran',
    status_pembayaran  VARCHAR(15)   NOT NULL DEFAULT 'belum_bayar',
    alasan_batal       VARCHAR(255),
    CONSTRAINT pk_pesanan               PRIMARY KEY (id_pesanan),
    CONSTRAINT uq_pesanan_kode          UNIQUE (kode_pesanan),
    CONSTRAINT ck_pesanan_metode        CHECK (metode_terima IN ('ambil', 'kirim')),
    CONSTRAINT ck_pesanan_skema         CHECK (skema_bayar IN ('dp', 'lunas')),
    CONSTRAINT ck_pesanan_subtotal      CHECK (subtotal >= 0),
    CONSTRAINT ck_pesanan_ongkir        CHECK (ongkir >= 0),
    CONSTRAINT ck_pesanan_status        CHECK (status_pesanan IN ('menunggu_pembayaran', 'menunggu_verifikasi',
                                            'terkonfirmasi', 'diproduksi', 'siap', 'selesai', 'dibatalkan')),
    CONSTRAINT ck_pesanan_status_bayar  CHECK (status_pembayaran IN ('belum_bayar', 'dp', 'lunas')),
    CONSTRAINT ck_pesanan_kirim         CHECK (metode_terima = 'ambil'
                                            OR (alamat_kirim IS NOT NULL AND skema_bayar = 'dp')),   -- AB-03
    CONSTRAINT ck_pesanan_selesai       CHECK (status_pesanan <> 'selesai' OR status_pembayaran = 'lunas'),
    CONSTRAINT ck_pesanan_batal         CHECK (status_pesanan <> 'dibatalkan' OR alasan_batal IS NOT NULL),
    CONSTRAINT fk_pesanan_pelanggan     FOREIGN KEY (id_pelanggan)
        REFERENCES pengguna (id_pengguna) ON DELETE RESTRICT,         -- FK no. 1
    CONSTRAINT fk_pesanan_kuota         FOREIGN KEY (id_kuota)
        REFERENCES kuota_harian (id_kuota) ON DELETE RESTRICT         -- FK no. 2
);
CREATE INDEX idx_pesanan_id_pelanggan ON pesanan (id_pelanggan);
CREATE INDEX idx_pesanan_id_kuota     ON pesanan (id_kuota);

-- =====================================================================
-- Tabel  7 : detail_pesanan
-- Isi      : rasa dan jumlah per pesanan; harga_satuan = salinan harga saat memesan
-- Modul    : Katalog & Pemesanan
-- Pemilik  : Muhammad Jiyad Al Islamy Putra Liony (NIM 23083000162)
-- Branch   : feature/jiyad-katalog-pesanan
-- =====================================================================
-- [AI] prompt: buatkan CREATE TABLE detail_pesanan sesuai skema Tugas 5 K.2 no. 7: FK id_pesanan CASCADE,
--              FK id_kue RESTRICT, qty > 0, uq_detail_pesanan (id_pesanan, id_kue) (27 Okt 2026)
CREATE TABLE detail_pesanan (
    id_detail     INTEGER GENERATED ALWAYS AS IDENTITY,
    id_pesanan    INTEGER       NOT NULL,
    id_kue        INTEGER       NOT NULL,
    qty           SMALLINT      NOT NULL,
    harga_satuan  NUMERIC(10,2) NOT NULL,
    subtotal      NUMERIC(12,2) NOT NULL,           -- qty × harga_satuan
    CONSTRAINT pk_detail_pesanan        PRIMARY KEY (id_detail),
    CONSTRAINT uq_detail_pesanan        UNIQUE (id_pesanan, id_kue),
    CONSTRAINT ck_detail_pesanan_qty    CHECK (qty > 0),
    CONSTRAINT ck_detail_pesanan_harga  CHECK (harga_satuan > 0),
    CONSTRAINT fk_detail_pesanan_pesanan FOREIGN KEY (id_pesanan)
        REFERENCES pesanan (id_pesanan) ON DELETE CASCADE,            -- FK no. 3
    CONSTRAINT fk_detail_pesanan_kue    FOREIGN KEY (id_kue)
        REFERENCES kue (id_kue) ON DELETE RESTRICT                    -- FK no. 4
);


-- ---------------------------------------------------------------- DATA AWAL

-- Data awal kue (5 baris) — pemilik: Muhammad Jiyad Al Islamy Putra Liony (23083000162)
-- [AI] prompt: buatkan data awal 5 rasa Yourfoodoo: Redvelvet Cheese, Matcha Mallow, Blureo, The Classic,
--              Chocoholic, 45 gr @ Rp13.000 (27 Okt 2026)
INSERT INTO kue (nama_kue, deskripsi, berat_gram, harga, foto, created_at) VALUES
  ('Redvelvet Cheese', 'Soft cookies red velvet dengan isian keju krim di tengah', 45, 13000, 'kue/redvelvet-cheese.webp', '2026-10-18 19:40+07'),  -- id 1
  ('Matcha Mallow', 'Soft cookies matcha dengan marshmallow yang meleleh di dalam', 45, 13000, 'kue/matcha-mallow.webp', '2026-10-18 19:40+07'),  -- id 2
  ('Blureo', 'Soft cookies biru dengan potongan biskuit cokelat krim', 45, 13000, 'kue/blureo.webp', '2026-10-18 19:40+07'),  -- id 3
  ('The Classic', 'Soft cookies butter klasik dengan dark chocolate chip', 45, 13000, 'kue/the-classic.webp', '2026-10-18 19:40+07'),  -- id 4
  ('Chocoholic', 'Soft cookies double chocolate dengan kakao dan chocolate chip', 45, 13000, 'kue/chocoholic.webp', '2026-10-18 19:40+07');  -- id 5

-- Data awal resep_kue (40 baris) — pemilik: Muhammad Jiyad Al Islamy Putra Liony (23083000162)
-- [AI] prompt: buatkan data awal resep per 1 kue 45 gr untuk 5 rasa: adonan dasar (tepung, butter, gula pasir,
--              gula palem, telur, kemasan) ditambah bahan khas tiap rasa (27 Okt 2026)
-- CATATAN: takaran di bawah adalah perkiraan tim; ganti dengan takaran dari buku resep klien (Tugas 5 L.3 no. 6)
INSERT INTO resep_kue (id_kue, id_bahan, takaran) VALUES
  (1, 1, 0.015),  -- Redvelvet Cheese - Tepung terigu protein sedang
  (1, 2, 0.01),  -- Redvelvet Cheese - Butter
  (1, 3, 0.004),  -- Redvelvet Cheese - Gula pasir
  (1, 4, 0.004),  -- Redvelvet Cheese - Gula palem
  (1, 5, 0.2),  -- Redvelvet Cheese - Telur ayam
  (1, 14, 1),  -- Redvelvet Cheese - Plastik kemasan cookies
  (1, 7, 0.0015),  -- Redvelvet Cheese - Bubuk kakao
  (1, 9, 0.008),  -- Redvelvet Cheese - Keju krim
  (1, 12, 0.02),  -- Redvelvet Cheese - Pewarna makanan merah (pasta 30 ml)
  (2, 1, 0.015),  -- Matcha Mallow - Tepung terigu protein sedang
  (2, 2, 0.01),  -- Matcha Mallow - Butter
  (2, 3, 0.004),  -- Matcha Mallow - Gula pasir
  (2, 4, 0.004),  -- Matcha Mallow - Gula palem
  (2, 5, 0.2),  -- Matcha Mallow - Telur ayam
  (2, 14, 1),  -- Matcha Mallow - Plastik kemasan cookies
  (2, 8, 0.002),  -- Matcha Mallow - Bubuk matcha
  (2, 10, 0.006),  -- Matcha Mallow - Marshmallow
  (3, 1, 0.015),  -- Blureo - Tepung terigu protein sedang
  (3, 2, 0.01),  -- Blureo - Butter
  (3, 3, 0.004),  -- Blureo - Gula pasir
  (3, 4, 0.004),  -- Blureo - Gula palem
  (3, 5, 0.2),  -- Blureo - Telur ayam
  (3, 14, 1),  -- Blureo - Plastik kemasan cookies
  (3, 11, 0.008),  -- Blureo - Biskuit cokelat krim (remuk)
  (3, 13, 0.02),  -- Blureo - Pewarna makanan biru (pasta 30 ml)
  (4, 1, 0.015),  -- The Classic - Tepung terigu protein sedang
  (4, 2, 0.01),  -- The Classic - Butter
  (4, 3, 0.004),  -- The Classic - Gula pasir
  (4, 4, 0.004),  -- The Classic - Gula palem
  (4, 5, 0.2),  -- The Classic - Telur ayam
  (4, 14, 1),  -- The Classic - Plastik kemasan cookies
  (4, 6, 0.008),  -- The Classic - Dark chocolate chip
  (5, 1, 0.015),  -- Chocoholic - Tepung terigu protein sedang
  (5, 2, 0.01),  -- Chocoholic - Butter
  (5, 3, 0.004),  -- Chocoholic - Gula pasir
  (5, 4, 0.004),  -- Chocoholic - Gula palem
  (5, 5, 0.2),  -- Chocoholic - Telur ayam
  (5, 14, 1),  -- Chocoholic - Plastik kemasan cookies
  (5, 6, 0.01),  -- Chocoholic - Dark chocolate chip
  (5, 7, 0.004);  -- Chocoholic - Bubuk kakao

-- Data awal kuota_harian (9 baris) — pemilik: Muhammad Jiyad Al Islamy Putra Liony (23083000162)
-- [AI] prompt: buatkan data awal kuota_harian 24 Okt - 1 Nov 2026, default 15, satu tanggal tutup (0) (27 Okt 2026)
INSERT INTO kuota_harian (tanggal, kapasitas, keterangan, created_at) VALUES
  ('2026-10-24', 15, NULL, '2026-10-20 08:00+07'),  -- id 1
  ('2026-10-25', 15, NULL, '2026-10-20 08:00+07'),  -- id 2
  ('2026-10-26', 15, NULL, '2026-10-20 08:00+07'),  -- id 3
  ('2026-10-27', 15, NULL, '2026-10-20 08:00+07'),  -- id 4
  ('2026-10-28', 15, NULL, '2026-10-20 08:00+07'),  -- id 5
  ('2026-10-29', 15, NULL, '2026-10-20 08:00+07'),  -- id 6
  ('2026-10-30', 15, NULL, '2026-10-20 08:00+07'),  -- id 7
  ('2026-10-31', 15, NULL, '2026-10-20 08:00+07'),  -- id 8
  ('2026-11-01', 0, 'Toko tutup (contoh kuota 0 = tidak menerima pesanan)', '2026-10-20 08:00+07');  -- id 9

-- Data awal pesanan (12 baris) — pemilik: Muhammad Jiyad Al Islamy Putra Liony (23083000162)
-- [AI] prompt: buatkan data awal pesanan yang mencakup semua status (menunggu_pembayaran s.d. selesai dan
--              dibatalkan), ambil dan kirim, DP dan lunas; patuhi H-2, ck_pesanan_kirim, ck_pesanan_selesai,
--              batas_bayar = waktu_pesan + 24 jam (27 Okt 2026)
INSERT INTO pesanan (kode_pesanan, id_pelanggan, id_kuota, waktu_pesan, metode_terima, alamat_kirim, patokan_alamat, catatan, skema_bayar, subtotal, ongkir, total, batas_bayar, status_pesanan, status_pembayaran, alasan_batal) VALUES
  ('YF-261021-001', 4, 1, '2026-10-21 19:12+07', 'ambil', NULL, NULL, 'Untuk arisan RT, mohon dipisah per rasa', 'lunas', 156000, NULL, 156000, '2026-10-22 19:12+07', 'selesai', 'lunas', NULL),  -- id 1: Nadia Putri Ramadhani, 2026-10-24
  ('YF-261021-002', 5, 1, '2026-10-21 21:40+07', 'kirim', 'Jl. Kawi No. 12, Kepanjen, Kab. Malang', 'Rumah pagar hijau sebelah apotek', NULL, 'dp', 130000, 14000, 144000, '2026-10-22 21:40+07', 'selesai', 'lunas', NULL),  -- id 2: Bagus Prasetyo, 2026-10-24
  ('YF-261022-001', 6, 2, '2026-10-22 13:05+07', 'ambil', NULL, NULL, 'Diambil sore sekitar jam 4', 'dp', 156000, NULL, 156000, '2026-10-23 13:05+07', 'selesai', 'lunas', NULL),  -- id 3: Rina Wulandari, 2026-10-25
  ('YF-261023-001', 9, 3, '2026-10-23 09:30+07', 'ambil', NULL, NULL, NULL, 'lunas', 130000, NULL, 130000, '2026-10-24 09:30+07', 'selesai', 'lunas', NULL),  -- id 4: Dimas Ardiansyah, 2026-10-26
  ('YF-261024-001', 7, 4, '2026-10-24 08:00+07', 'ambil', NULL, NULL, NULL, 'dp', 78000, NULL, 78000, '2026-10-25 08:00+07', 'dibatalkan', 'belum_bayar', 'Dibatalkan pelanggan sebelum membayar (salah pilih tanggal)'),  -- id 5: Fajar Nugroho, 2026-10-27
  ('YF-261024-002', 8, 4, '2026-10-24 20:15+07', 'ambil', NULL, NULL, 'Hadiah ulang tahun, tolong dikemas rapi', 'lunas', 156000, NULL, 156000, '2026-10-25 20:15+07', 'siap', 'lunas', NULL),  -- id 6: Ayu Kartika Sari, 2026-10-27
  ('YF-261024-003', 6, 4, '2026-10-24 22:05+07', 'kirim', 'Jl. Diponegoro No. 8, Bululawang, Kab. Malang', 'Gang samping SD Negeri 2', 'Kirim sebelum jam 11 siang', 'dp', 208000, 16000, 224000, '2026-10-25 22:05+07', 'selesai', 'lunas', NULL),  -- id 7: Rina Wulandari, 2026-10-27
  ('YF-261025-001', 9, 5, '2026-10-25 10:00+07', 'kirim', 'Jl. Panglima Sudirman No. 102, Kepanjen, Kab. Malang', 'Sebelah konter pulsa Dimas Cell', NULL, 'dp', 156000, 15000, 171000, '2026-10-26 10:00+07', 'terkonfirmasi', 'dp', NULL),  -- id 8: Dimas Ardiansyah, 2026-10-28
  ('YF-261025-002', 4, 4, '2026-10-25 16:45+07', 'ambil', NULL, NULL, 'Diambil jam 7 malam', 'lunas', 130000, NULL, 130000, '2026-10-26 16:45+07', 'diproduksi', 'lunas', NULL),  -- id 9: Nadia Putri Ramadhani, 2026-10-27
  ('YF-261026-001', 5, 6, '2026-10-26 19:00+07', 'ambil', NULL, NULL, NULL, 'lunas', 104000, NULL, 104000, '2026-10-27 19:00+07', 'terkonfirmasi', 'lunas', NULL),  -- id 10: Bagus Prasetyo, 2026-10-29
  ('YF-261026-002', 8, 7, '2026-10-26 21:30+07', 'ambil', NULL, NULL, NULL, 'dp', 130000, NULL, 130000, '2026-10-27 21:30+07', 'menunggu_verifikasi', 'belum_bayar', NULL),  -- id 11: Ayu Kartika Sari, 2026-10-30
  ('YF-261027-001', 7, 8, '2026-10-27 15:20+07', 'ambil', NULL, NULL, NULL, 'lunas', 156000, NULL, 156000, '2026-10-28 15:20+07', 'menunggu_pembayaran', 'belum_bayar', NULL);  -- id 12: Fajar Nugroho, 2026-10-31

-- Data awal detail_pesanan (21 baris) — pemilik: Muhammad Jiyad Al Islamy Putra Liony (23083000162)
-- [AI] prompt: buatkan data awal detail_pesanan sesuai pesanan; subtotal = qty x harga_satuan (27 Okt 2026)
INSERT INTO detail_pesanan (id_pesanan, id_kue, qty, harga_satuan, subtotal) VALUES
  (1, 4, 6, 13000, 78000),
  (1, 5, 6, 13000, 78000),
  (2, 1, 5, 13000, 65000),
  (2, 2, 5, 13000, 65000),
  (3, 1, 4, 13000, 52000),
  (3, 3, 4, 13000, 52000),
  (3, 4, 4, 13000, 52000),
  (4, 5, 10, 13000, 130000),
  (5, 2, 6, 13000, 78000),
  (6, 1, 6, 13000, 78000),
  (6, 2, 6, 13000, 78000),
  (7, 4, 8, 13000, 104000),
  (7, 5, 8, 13000, 104000),
  (8, 1, 6, 13000, 78000),
  (8, 3, 6, 13000, 78000),
  (9, 4, 5, 13000, 65000),
  (9, 5, 5, 13000, 65000),
  (10, 2, 4, 13000, 52000),
  (10, 3, 4, 13000, 52000),
  (11, 1, 10, 13000, 130000),
  (12, 4, 12, 13000, 156000);

