# Konvensi Tim — Kelompok 4

Ringkasan Bagian C dan D dokumen Tugas 5. Bila ada perbedaan, dokumen Tugas 5 yang berlaku.

## Alur kerja Git

1. Selalu mulai dari branch modulmu: `git switch feature/<nama>-<modul>` lalu `git pull`.
2. Ambil perubahan terbaru dari dev sebelum mengerjakan fitur baru: `git merge origin/dev`.
3. Commit kecil dan rutin sepanjang minggu (riwayat commit menjadi bukti faktor kontribusi; commit menumpuk di malam tenggat dinilai negatif).
4. Push, lalu buka pull request ke `dev`. Minta satu anggota lain mereviu.
5. `dev` digabung ke `main` hanya saat demo atau rilis, oleh PJM fase berjalan.

## Pesan commit

Awalan wajib, deskripsi bahasa Indonesia:

```
feat: simpan pesanan dengan kunci baris kuota
fix: kalender masih menampilkan tanggal kurang dari H-2
docs: perbarui README cara menjalankan lokal
test: uji potong stok saat stok kurang
```

## Penamaan

| Objek | Aturan | Contoh |
| --- | --- | --- |
| Tabel, kolom | snake_case, bahasa Indonesia, tunggal | `detail_pesanan`, `stok_saat_ini` |
| Primary key | `id_<entitas>` | `id_pesanan` |
| Foreign key | sama dengan PK yang dirujuk, atau nama peran | `id_kue`, `dicatat_oleh` |
| Constraint, index | `ck_`, `uq_`, `fk_`, `idx_` + tabel + arti | `ck_pesanan_kirim` |
| Objek skema Drizzle | camelCase | `export const detailPesanan = pgTable('detail_pesanan', …)` |
| Variabel | camelCase; boolean diawali `sudah`/`ada`/`bisa` | `stokTersedia`, `sudahLunas` |
| Fungsi | camelCase diawali kata kerja; baca data `ambil…` | `buatPesanan()`, `ambilJadwalProduksi()` |
| Konstanta | UPPER_SNAKE_CASE | `KUOTA_DEFAULT = 15` |
| Komponen React | PascalCase, file kebab-case | `KartuKue` di `kartu-kue.tsx` |
| Rute, folder | kebab-case | `app/admin/laporan/laba-bersih/page.tsx` |
| Aturan bisnis | `ab-<nomor>-<nama>.ts` | `lib/aturan/ab-02-kuota.ts` |
| Kode dokumen | prefiks + tanggal + urut 3 digit | `YF-261114-004`, `PO-2611-003` |

## Menulis ke tabel milik orang lain

Boleh membaca tabel mana pun. Menulis ke tabel milik anggota lain hanya lewat fungsi yang disediakan pemiliknya:

| Kebutuhan | Fungsi | Pemilik |
| --- | --- | --- |
| Ubah status pesanan | `ubahStatusPesanan(tx, idPesanan, statusBaru)` | Jiyad |
| Tambah/kurangi stok | `catatMutasiStok(tx, idBahan, jumlah, jenis, sumber)` → `ubahStokBahan()` | Adelio, Gerry |
| Kebutuhan bahan dari pesanan | `ambilKebutuhanBahan(tanggalMulai)` | Jiyad |
| Sesi dan peran | `auth()`, `wajibPeran(peran)`, `ambilProfil(id)` | Willy |

## Komentar kode bantuan AI (Buku Panduan Bab 8)

Setiap blok kode atau SQL yang dibantu AI wajib diberi komentar prompt **tepat di atas bloknya**. Tanpa komentar, komponen terkait bernilai 0 untuk seluruh kelompok.

```ts
// [AI] prompt: buatkan Server Action yang mengunci baris kuota_harian lalu menyimpan pesanan bila slot masih ada
export async function buatPesanan(data: DataCheckout) { … }
```

```sql
-- [AI] prompt: buatkan CREATE TABLE pesanan dengan CHECK status dan FK ke kuota_harian
-- Pemilik tabel: Muhammad Jiyad Al Islamy Putra Liony (23083000162) · Modul Katalog & Pemesanan
CREATE TABLE pesanan ( … );
```

Pemilik modul wajib menguji blok tersebut dengan kasus uji sendiri dan mampu menjelaskannya tanpa AI.

## Rahasia

Jangan commit `.env` atau `.env.local`. Yang di-commit hanya `.env.example`.
