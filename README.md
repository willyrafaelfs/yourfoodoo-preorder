# Yourfoodoo Pre-Order

Sistem Informasi Pemesanan Pre-Order Kue dan Manajemen Inventori Berbasis Web pada Toko Kue Yourfoodoo.
Proyek MK54 Project Sistem Informasi Terapan, Kelompok 4 (7A1), Semester Ganjil 2026/2027.

Rancangan yang menjadi acuan: **Tugas 5 — Rancangan Final** (salinannya di `docs/`).

## Tim dan kepemilikan modul

| Anggota | NIM | Modul | Branch | Tabel |
| --- | --- | --- | --- | --- |
| Muhammad Jiyad Al Islamy Putra Liony | 23083000162 | Katalog & Pemesanan | `feature/jiyad-katalog-pesanan` | kue, resep_kue, kuota_harian, pesanan, detail_pesanan |
| Adelio Raihan Aryasatya | 23083000152 | Pembayaran & Produksi | `feature/adelio-pembayaran-produksi` | pembayaran, riwayat_stok |
| Gerry Robbie AG | 23083000147 | Inventori & Pembelian | `feature/gerry-inventori-pembelian` | bahan_baku, supplier, pembelian_bahan, detail_pembelian |
| Willy Rafael F. Silalahi | 23083000168 | Akun, Keuangan & Laporan | `feature/willy-akun-laporan` | pengguna, pengeluaran_operasional |

## Stack (dikunci di Tugas 5)

Node.js 24 LTS · Next.js 16 (App Router) + React 19 + TypeScript 5 · Tailwind CSS 4 + shadcn/ui + Zod ·
Auth.js v5 · Drizzle ORM + drizzle-kit · PostgreSQL 18 di Neon (Free) · Netlify (Free) + Netlify Blobs.

Mengganti versi mayor atau stack harus seizin dosen pengampu.

## Branch

- `main` — siap produksi; hanya menerima merge dari `dev`; setiap push memicu deploy Netlify.
- `dev` — integrasi; menerima pull request dari branch feature setelah direviu satu anggota lain.
- `feature/<nama>-<modul>` — pengembangan individu; hanya pemilik modul yang commit.

Aturan commit, penamaan, dan komentar AI ada di [CONTRIBUTING.md](CONTRIBUTING.md).

## Menjalankan secara lokal

Kode aplikasi diinisialisasi pada Tugas 6. Setelah itu:

```bash
cp .env.example .env.local   # isi nilai dari PJM Fase 3
npm install
npm run dev
```
