-- #####################################################################
-- 02_inventori_pembelian.sql — Modul Inventori & Pembelian
-- Pemilik modul : Gerry Robbie AG (NIM 23083000147)
-- Branch        : feature/gerry-inventori-pembelian
-- Proyek        : SI Pemesanan Pre-Order Kue & Manajemen Inventori Yourfoodoo
-- Kelompok 4 (7A1) — MK54 Project SI Terapan 2026/2027 — Tugas 6
-- Urutan jalan  : setelah 01_akun_laporan.sql (butuh pengguna)
-- #####################################################################

SET client_encoding = 'UTF8';
SET timezone = 'Asia/Jakarta';

-- =====================================================================
-- Tabel  9 : supplier
-- Isi      : 2 supplier tetap dan toko eceran (toko eceran juga dicatat sebagai supplier)
-- Modul    : Inventori & Pembelian
-- Pemilik  : Gerry Robbie AG (NIM 23083000147)
-- Branch   : feature/gerry-inventori-pembelian
-- =====================================================================
-- [AI] prompt: buatkan CREATE TABLE supplier sesuai skema Tugas 5 K.2 no. 9, nama_toko UNIQUE (27 Okt 2026)
CREATE TABLE supplier (
    id_supplier     INTEGER GENERATED ALWAYS AS IDENTITY,
    nama_toko       VARCHAR(100) NOT NULL,
    nama_kontak     VARCHAR(100),
    no_hp           VARCHAR(15),                    -- untuk kirim PO via WhatsApp
    alamat          TEXT,
    barang_dipasok  VARCHAR(255),
    status_aktif    BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT pk_supplier           PRIMARY KEY (id_supplier),
    CONSTRAINT uq_supplier_nama_toko UNIQUE (nama_toko)
);

-- =====================================================================
-- Tabel  3 : bahan_baku
-- Isi      : bahan dan kemasan; telur dalam butir (1 krat = 30 butir); FK ke supplier langganan
-- Modul    : Inventori & Pembelian
-- Pemilik  : Gerry Robbie AG (NIM 23083000147)
-- Branch   : feature/gerry-inventori-pembelian
-- =====================================================================
-- [AI] prompt: buatkan CREATE TABLE bahan_baku sesuai skema Tugas 5 K.2 no. 3: stok tidak boleh minus,
--              CHECK jenis bahan/kemasan, kelipatan_beli > 0, FK id_supplier boleh NULL ke supplier
--              ON DELETE RESTRICT (revisi dosen 26 Okt) (27 Okt 2026)
CREATE TABLE bahan_baku (
    id_bahan               INTEGER GENERATED ALWAYS AS IDENTITY,
    nama_bahan             VARCHAR(100)  NOT NULL,
    jenis                  VARCHAR(10)   NOT NULL DEFAULT 'bahan',
    satuan                 VARCHAR(20)   NOT NULL,  -- kg, butir, botol, pcs
    stok_saat_ini          NUMERIC(12,3) NOT NULL DEFAULT 0,
    stok_minimum           NUMERIC(12,3) NOT NULL DEFAULT 0,
    kelipatan_beli         NUMERIC(12,3) NOT NULL DEFAULT 1,
    harga_satuan_terakhir  NUMERIC(12,2),
    id_supplier            INTEGER,                 -- supplier langganan; NULL = hanya dibeli eceran
    status_aktif           BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at             TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT pk_bahan_baku          PRIMARY KEY (id_bahan),
    CONSTRAINT uq_bahan_baku_nama     UNIQUE (nama_bahan),
    CONSTRAINT ck_bahan_jenis         CHECK (jenis IN ('bahan', 'kemasan')),
    CONSTRAINT ck_bahan_stok          CHECK (stok_saat_ini >= 0),
    CONSTRAINT ck_bahan_stok_minimum  CHECK (stok_minimum >= 0),
    CONSTRAINT ck_bahan_kelipatan     CHECK (kelipatan_beli > 0),
    CONSTRAINT ck_bahan_harga         CHECK (harga_satuan_terakhir >= 0),
    CONSTRAINT fk_bahan_baku_supplier FOREIGN KEY (id_supplier)
        REFERENCES supplier (id_supplier) ON DELETE RESTRICT          -- FK no. 18
);

-- =====================================================================
-- Tabel 10 : pembelian_bahan
-- Isi      : header PO ke supplier (PO-yymm-nnn) atau belanja eceran (EC-yymm-nnn)
-- Modul    : Inventori & Pembelian
-- Pemilik  : Gerry Robbie AG (NIM 23083000147)
-- Branch   : feature/gerry-inventori-pembelian
-- =====================================================================
-- [AI] prompt: buatkan CREATE TABLE pembelian_bahan sesuai skema Tugas 5 K.2 no. 10: jenis po/eceran,
--              status dipesan/diterima/dibatalkan, ck_pembelian_diterima, ck_eceran_langsung, FK ke supplier
--              dan pengguna RESTRICT (27 Okt 2026)
CREATE TABLE pembelian_bahan (
    id_pembelian      INTEGER GENERATED ALWAYS AS IDENTITY,
    nomor             VARCHAR(20)   NOT NULL,       -- PO-yymm-nnn atau EC-yymm-nnn
    jenis             VARCHAR(10)   NOT NULL,
    id_supplier       INTEGER       NOT NULL,
    dicatat_oleh      INTEGER       NOT NULL,
    tanggal           DATE          NOT NULL,
    cara_terima       VARCHAR(10),                  -- hanya untuk PO
    status            VARCHAR(12)   NOT NULL DEFAULT 'dipesan',
    tanggal_diterima  DATE,
    ongkir_supplier   NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_biaya       NUMERIC(12,2) NOT NULL DEFAULT 0,  -- Σ qty_diterima × harga + ongkir (dihitung aplikasi)
    catatan           VARCHAR(255),
    CONSTRAINT pk_pembelian_bahan         PRIMARY KEY (id_pembelian),
    CONSTRAINT uq_pembelian_nomor         UNIQUE (nomor),
    CONSTRAINT ck_pembelian_jenis         CHECK (jenis IN ('po', 'eceran')),
    CONSTRAINT ck_pembelian_cara_terima   CHECK (cara_terima IN ('ambil', 'kirim')),
    CONSTRAINT ck_pembelian_status        CHECK (status IN ('dipesan', 'diterima', 'dibatalkan')),
    CONSTRAINT ck_pembelian_ongkir        CHECK (ongkir_supplier >= 0),
    CONSTRAINT ck_pembelian_total         CHECK (total_biaya >= 0),
    CONSTRAINT ck_pembelian_diterima      CHECK (status <> 'diterima' OR tanggal_diterima IS NOT NULL),
    CONSTRAINT ck_eceran_langsung         CHECK (jenis = 'po' OR status = 'diterima'),
    CONSTRAINT fk_pembelian_supplier      FOREIGN KEY (id_supplier)
        REFERENCES supplier (id_supplier) ON DELETE RESTRICT,         -- FK no. 9
    CONSTRAINT fk_pembelian_dicatat_oleh  FOREIGN KEY (dicatat_oleh)
        REFERENCES pengguna (id_pengguna) ON DELETE RESTRICT          -- FK no. 10
);

-- =====================================================================
-- Tabel 11 : detail_pembelian
-- Isi      : bahan per pembelian; qty_diterima diisi saat konfirmasi penerimaan
-- Modul    : Inventori & Pembelian
-- Pemilik  : Gerry Robbie AG (NIM 23083000147)
-- Branch   : feature/gerry-inventori-pembelian
-- =====================================================================
-- [AI] prompt: buatkan CREATE TABLE detail_pembelian sesuai skema Tugas 5 K.2 no. 11: FK ke pembelian_bahan
--              ON DELETE CASCADE, FK ke bahan_baku RESTRICT, uq_detail_pembelian (id_pembelian, id_bahan) (27 Okt 2026)
CREATE TABLE detail_pembelian (
    id_detail_pembelian  INTEGER GENERATED ALWAYS AS IDENTITY,
    id_pembelian         INTEGER       NOT NULL,
    id_bahan             INTEGER       NOT NULL,
    qty_dipesan          NUMERIC(12,3) NOT NULL,
    qty_diterima         NUMERIC(12,3),             -- NULL = belum diterima
    harga_satuan         NUMERIC(12,2) NOT NULL,
    CONSTRAINT pk_detail_pembelian       PRIMARY KEY (id_detail_pembelian),
    CONSTRAINT uq_detail_pembelian       UNIQUE (id_pembelian, id_bahan),
    CONSTRAINT ck_detail_beli_dipesan    CHECK (qty_dipesan > 0),
    CONSTRAINT ck_detail_beli_diterima   CHECK (qty_diterima >= 0),
    CONSTRAINT ck_detail_beli_harga      CHECK (harga_satuan >= 0),
    CONSTRAINT fk_detail_beli_pembelian  FOREIGN KEY (id_pembelian)
        REFERENCES pembelian_bahan (id_pembelian) ON DELETE CASCADE,  -- FK no. 11
    CONSTRAINT fk_detail_beli_bahan      FOREIGN KEY (id_bahan)
        REFERENCES bahan_baku (id_bahan) ON DELETE RESTRICT           -- FK no. 12
);


-- ---------------------------------------------------------------- DATA AWAL

-- Data awal supplier (5 baris) — pemilik: Gerry Robbie AG (23083000147)
-- [AI] prompt: buatkan data awal supplier: 2 supplier tetap dan 3 toko eceran di sekitar Gondanglegi (27 Okt 2026)
INSERT INTO supplier (nama_toko, nama_kontak, no_hp, alamat, barang_dipasok, created_at) VALUES
  ('UD Sumber Rejeki Bahan Kue', 'Pak Hendra', '081335648201', 'Jl. Raya Kepanjen No. 88, Kepanjen, Kab. Malang', 'Tepung, butter, gula, gula palem, cokelat, bubuk kakao, keju krim, biskuit', '2026-10-18 19:20+07'),  -- id 1: supplier tetap
  ('Toko Telur Barokah', 'Bu Sulastri', '085233906174', 'Jl. Raya Sepanjang No. 9, Gondanglegi, Kab. Malang', 'Telur ayam (per krat 30 butir)', '2026-10-18 19:21+07'),  -- id 2: supplier tetap
  ('Toko Bahan Kue Mawar', 'Mbak Lina', '082233871560', 'Jl. Raya Bululawang No. 17, Bululawang, Kab. Malang', 'Bubuk matcha, marshmallow, pewarna makanan', '2026-10-18 19:22+07'),  -- id 3: toko eceran
  ('Toko Plastik Sinar Jaya', 'Pak Andi', '081615092347', 'Jl. Raya Gondanglegi No. 120, Gondanglegi, Kab. Malang', 'Plastik kemasan cookies, stiker label', '2026-10-18 19:23+07'),  -- id 4: toko eceran
  ('Toko Sembako Bu Yati', 'Bu Yati', '085790418836', 'Los B-12 Pasar Gondanglegi, Kab. Malang', 'Gula pasir dan telur eceran', '2026-10-18 19:24+07');  -- id 5: toko eceran

-- Data awal bahan_baku (14 baris) — pemilik: Gerry Robbie AG (23083000147)
-- [AI] prompt: buatkan data awal bahan_baku untuk soft cookies 5 rasa beserta stok minimum (butter 2 kg,
--              gula 5 kg, telur 60 butir), kelipatan beli, dan supplier langganan; stok_saat_ini harus sama
--              dengan stok_sesudah terakhir di riwayat_stok (27 Okt 2026)
-- stok_saat_ini = posisi 27 Okt 2026 sore, sama dengan stok_sesudah terakhir per bahan di riwayat_stok
INSERT INTO bahan_baku (nama_bahan, jenis, satuan, stok_saat_ini, stok_minimum, kelipatan_beli, harga_satuan_terakhir, id_supplier, created_at) VALUES
  ('Tepung terigu protein sedang', 'bahan', 'kg', 8.27, 5, 1, 13500, 1, '2026-10-18 19:30+07'),  -- id 1
  ('Butter', 'bahan', 'kg', 1.98, 2, 1, 145000, 1, '2026-10-18 19:30+07'),  -- id 2
  ('Gula pasir', 'bahan', 'kg', 6.672, 5, 1, 18500, 1, '2026-10-18 19:30+07'),  -- id 3
  ('Gula palem', 'bahan', 'kg', 2.872, 1, 1, 32000, 1, '2026-10-18 19:30+07'),  -- id 4
  ('Telur ayam', 'bahan', 'butir', 108.6, 60, 30, 1900, 2, '2026-10-18 19:30+07'),  -- id 5
  ('Dark chocolate chip', 'bahan', 'kg', 2.326, 1, 1, 88000, 1, '2026-10-18 19:30+07'),  -- id 6
  ('Bubuk kakao', 'bahan', 'kg', 0.961, 0.5, 0.5, 95000, 1, '2026-10-18 19:30+07'),  -- id 7
  ('Bubuk matcha', 'bahan', 'kg', 0.258, 0.1, 0.1, 560000, NULL, '2026-10-18 19:30+07'),  -- id 8, hanya dibeli eceran
  ('Keju krim', 'bahan', 'kg', 1.28, 0.5, 1, 120000, 1, '2026-10-18 19:30+07'),  -- id 9
  ('Marshmallow', 'bahan', 'kg', 1.234, 0.5, 1, 65000, NULL, '2026-10-18 19:30+07'),  -- id 10, hanya dibeli eceran
  ('Biskuit cokelat krim (remuk)', 'bahan', 'kg', 0.028, 0.5, 1, NULL, 1, '2026-10-18 19:30+07'),  -- id 11
  ('Pewarna makanan merah (pasta 30 ml)', 'bahan', 'botol', 1.7, 1, 1, 9000, NULL, '2026-10-18 19:30+07'),  -- id 12, hanya dibeli eceran
  ('Pewarna makanan biru (pasta 30 ml)', 'bahan', 'botol', 1.92, 1, 1, 9000, NULL, '2026-10-18 19:30+07'),  -- id 13, hanya dibeli eceran
  ('Plastik kemasan cookies', 'kemasan', 'pcs', 178, 100, 100, 450, NULL, '2026-10-18 19:30+07');  -- id 14, hanya dibeli eceran

-- Data awal pembelian_bahan (6 baris) — pemilik: Gerry Robbie AG (23083000147)
-- [AI] prompt: buatkan data awal pembelian_bahan: PO supplier (diterima dan masih dipesan) dan belanja eceran
--              Oktober 2026; total_biaya = jumlah qty_diterima x harga + ongkir (27 Okt 2026)
INSERT INTO pembelian_bahan (nomor, jenis, id_supplier, dicatat_oleh, tanggal, cara_terima, status, tanggal_diterima, ongkir_supplier, total_biaya, catatan) VALUES
  ('PO-2610-001', 'po', 1, 1, '2026-10-19', 'ambil', 'diterima', '2026-10-19', 0, 656000, 'Diambil sendiri ke toko'),  -- id 1
  ('PO-2610-002', 'po', 2, 1, '2026-10-20', 'kirim', 'diterima', '2026-10-21', 10000, 177200, 'Dipesan 3 krat; 2 butir pecah saat pengiriman'),  -- id 2
  ('EC-2610-001', 'eceran', 4, 1, '2026-10-22', NULL, 'diterima', '2026-10-22', 0, 90000, NULL),  -- id 3
  ('EC-2610-002', 'eceran', 3, 1, '2026-10-23', NULL, 'diterima', '2026-10-23', 0, 195000, NULL),  -- id 4
  ('EC-2610-003', 'eceran', 5, 1, '2026-10-24', NULL, 'diterima', '2026-10-24', 0, 37000, 'Gula menyentuh stok minimum setelah produksi 24 Okt'),  -- id 5
  ('PO-2610-003', 'po', 1, 1, '2026-10-26', 'kirim', 'dipesan', NULL, 0, 0, 'Dibuat dari saran beli (butter dan biskuit di bawah stok minimum); dijadwalkan dikirim 28 Okt pagi');  -- id 6

-- Data awal detail_pembelian (17 baris) — pemilik: Gerry Robbie AG (23083000147)
-- [AI] prompt: buatkan data awal detail_pembelian sesuai header pembelian_bahan (27 Okt 2026)
INSERT INTO detail_pembelian (id_pembelian, id_bahan, qty_dipesan, qty_diterima, harga_satuan) VALUES
  (1, 1, 5, 5, 13500),
  (1, 2, 1, 1, 145000),
  (1, 3, 2, 2, 18000),
  (1, 4, 2, 2, 32000),
  (1, 6, 2, 2, 88000),
  (1, 7, 0.5, 0.5, 95000),
  (1, 9, 1, 1, 120000),
  (2, 5, 90, 88, 1900),
  (3, 14, 200, 200, 450),
  (4, 8, 0.2, 0.2, 560000),
  (4, 10, 1, 1, 65000),
  (4, 12, 1, 1, 9000),
  (4, 13, 1, 1, 9000),
  (5, 3, 2, 2, 18500),
  (6, 2, 3, NULL, 145000),
  (6, 11, 1, NULL, 58000),
  (6, 1, 5, NULL, 13500);

