-- #####################################################################
-- 00_reset.sql — mengosongkan basis data sebelum skrip modul dijalankan
-- Kelompok 4 (7A1) — Tugas 6 Implementasi Basis Data
-- Dijalankan di localhost / branch Neon dev saja. JANGAN dijalankan di branch Neon main (produksi).
-- #####################################################################

-- [AI] prompt: buatkan perintah DROP TABLE IF EXISTS untuk 13 tabel skema Tugas 5 agar skrip bisa
--              dijalankan ulang dari database kosong (27 Okt 2026)
DROP TABLE IF EXISTS
    riwayat_stok, pembayaran,                                          -- modul Pembayaran & Produksi
    detail_pesanan, pesanan, kuota_harian, resep_kue, kue,             -- modul Katalog & Pemesanan
    detail_pembelian, pembelian_bahan, bahan_baku, supplier,           -- modul Inventori & Pembelian
    pengeluaran_operasional, pengguna                                  -- modul Akun, Keuangan & Laporan
CASCADE;
