# Spesifikasi Aplikasi Dating dengan Premium Content

## 1. Autentikasi

### 1.1 Login
- **Metode**: Phone number atau Email + Password
- **Tidak ada social login** (Google, Facebook, dll)
- Session management dengan token JWT
- Auto-logout setelah 30 hari tidak aktif

### 1.2 Register
**Field Wajib:**
- Nama lengkap
- Nomor telepon
- Email
- Tanggal lahir (validasi min. 18 tahun)
- Jenis kelamin (Pria/Wanita/Non-binary)
- Password

**Validasi:**
- Email: format valid & unique
- Phone: format Indonesia valid & unique
- Password: minimal 8 karakter, kombinasi huruf + angka
- Umur: minimal 18 tahun (hitung dari tanggal lahir)

**Verifikasi:**
- Kirim OTP 6 digit via SMS/Email
- OTP berlaku 5 menit
- Maksimal 3x salah input OTP
- Bisa kirim ulang OTP setelah 60 detik

### 1.3 Keamanan
- Enkripsi password dengan bcrypt/argon2
- Rate limiting login (max 5x gagal dalam 15 menit)
- Forgot password via email/SMS dengan link reset
- Link reset password berlaku 1 jam

---

## 2. Onboarding Profile

### 2.1 Section Profile
**Data Required:**
- Kota tempat tinggal (dropdown/autocomplete)
- Headline (max 50 karakter)
- Bio/deskripsi (max 500 karakter)
- Pekerjaan (optional)
- Pendidikan (optional)
- Tinggi badan (optional)

### 2.2 Section Minat
- Pilih minimal 1, maksimal 4 minat
- **Kategori minat:**
  - Musik (Pop, Rock, Jazz, K-pop, Indie, dll)
  - Olahraga (Futsal, Gym, Yoga, Berenang, dll)
  - Hobi (Fotografi, Traveling, Memasak, Gaming, dll)
  - Film & Series (Drama, Horror, Comedy, dll)
  - Lainnya (Membaca, Teknologi, Fashion, dll)

### 2.3 Section Photo
- Upload minimal 2 foto, maksimal 6 foto
- Foto pertama = foto profil utama
- **Validasi:**
  - Format: JPG, PNG (max 5MB per foto)
  - Resolusi minimal 800x800px
  - AI detection untuk:
    - Blur/low quality
    - Konten dewasa/NSFW
    - Tidak ada wajah manusia
- **Verifikasi foto (optional):**
  - Selfie real-time dengan pose random
  - AI face matching dengan foto profil
  - Badge "Terverifikasi" di profil

---

## 3. Halaman Swipe (Discover)

### 3.1 Fitur Swipe
- **Swipe kiri**: Pass/tidak suka
- **Swipe kanan**: Like/suka
- **Undo**: 1x kesempatan undo untuk swipe terakhir (free user: 1x/hari, premium: unlimited)
- **Tap foto**: buka profil detail dengan semua foto
- Algoritma: prioritaskan user aktif & lokasi terdekat

### 3.2 Filter Pencarian
**Filter Available:**
- Jarak: 5km, 15km, 30km, 50km, unlimited
- Jenis kelamin: Pria/Wanita/Semua
- Umur: range slider (18-60+)
- Terakhir aktif: 24 jam, 1 minggu, 1 bulan

**Lokasi:**
- Gunakan GPS real-time
- **Pengaturan privasi:**
  - Tampilkan lokasi persis (accuracy: 1km)
  - Tampilkan lokasi kira-kira (accuracy: 5km)
  - Sembunyikan lokasi (hanya tampilkan kota)

### 3.3 Boost Profile (Premium Feature)
- User bisa boost profile untuk 30 menit/1 jam/3 jam
- Profile muncul lebih sering & di urutan teratas
- Harga: Rp 10.000 (30 menit), Rp 25.000 (1 jam), Rp 50.000 (3 jam)

---

## 4. Who Likes Me (Siapa yang Menyukai Saya)

### 4.1 Fitur
- Tampilkan daftar user yang like profil kita
- **Free user**: foto blur, hanya lihat jumlah likes
- **Premium user**: foto jelas, bisa lihat semua
- Tap profile → like balik atau pass

### 4.2 Action
- **Like balik**: instant match → langsung bisa chat
- **Pass**: user hilang dari list & tidak muncul lagi di swipe
- Sorting: terbaru di atas

---

## 5. Chatting

### 5.1 Fitur Chat
- **Status pengiriman:**
  - ✓ (1 centang): terkirim ke server
  - ✓✓ (2 centang): terkirim ke penerima
  - ✓✓ biru: sudah dibaca
- **Typing indicator**: "sedang mengetik..." real-time
- **Media support:**
  - Teks & emoji
  - Foto (max 10MB)
  - Video (max 50MB, duration max 60 detik)
  - Stiker (optional)

### 5.2 Keamanan Chat
- **End-to-end encryption** (E2EE)
- Screenshot detection dengan notifikasi ke pengirim (optional)
- Pesan yang dihapus hanya hilang di sisi pengirim
- Chat history tersimpan di server (encrypted)

### 5.3 UX Chat
- Push notification untuk pesan baru
- Badge unread counter
- Last seen/online status (bisa disembunyikan di settings)
- Search chat history
- Block & report langsung dari chat

---

## 6. Pemblokiran & Privasi

### 6.1 Block User
- **Syarat**: hanya bisa block user yang sudah match
- **Efek block:**
  - Tidak bisa saling melihat profil
  - Chat otomatis hilang dari list
  - Tidak muncul di swipe lagi
  - Block bersifat permanen (tidak bisa unblock)

### 6.2 Report User
- Bisa report ke admin untuk:
  - Fake profile
  - Pelecehan/harassment
  - Konten tidak pantas
  - Scam/penipuan
  - Spam
- Admin review dalam 1x24 jam
- User yang dilaporkan bisa di-suspend atau banned

---

## 7. Profile User

### 7.1 View Own Profile
**Statistik ditampilkan:**
- Jumlah teman/match
- Jumlah orang yang like
- Jumlah album yang dijual
- Total pendapatan (untuk creator)

### 7.2 Edit Profile
- Edit semua data onboarding (foto, bio, minat, dll)
- Ganti password
- Kelola album premium
- Settings privasi

### 7.3 Daftar Teman
- List semua match
- Tap untuk lihat profil detail
- Bisa langsung chat
- Sorting: terakhir chat, nama A-Z

---

## 8. Album Premium (Konten Berbayar)

### 8.1 Membuat Album
**Creator:**
- Upload foto/video ke album
- Set judul & deskripsi album
- Set harga: Rp 10.000 - Rp 500.000
- Preview: 1 foto thumbnail (blur untuk pembeli)
- Bisa buat album gratis untuk promosi

### 8.2 Proteksi Konten
- **Preview**: blur/mosaic untuk yang belum beli
- **Setelah dibeli:**
  - Streaming/viewing online only
  - **Tidak bisa download**
  - Screenshot detection (watermark otomatis)
  - Screen recording detection (optional)
- Watermark digital dengan ID pembeli (invisible)

### 8.3 Pembelian
- Gunakan saldo wallet internal
- Setelah beli: akses selamanya
- Bisa review album (rating & comment)

### 8.4 Kategori Album
- Personal (selfie, daily life)
- Professional (photoshoot, modeling)
- Behind the scenes
- Eksklusif/limited edition

---

## 9. Wallet System

### 9.1 Top-up Saldo
**Metode pembayaran:**
- Transfer bank (manual confirmation)
- E-wallet (GoPay, OVO, Dana, ShopeePay)
- Virtual account
- QRIS

**Nominal top-up:**
- Min: Rp 10.000
- Max: Rp 5.000.000/transaksi

### 9.2 Penggunaan Saldo
- Beli album premium
- Boost profile
- Beli fitur premium (optional: unlimited likes, dll)

### 9.3 Withdrawal (untuk Creator)
**Syarat:**
- Minimal saldo Rp 100.000
- Verifikasi KTP & rekening bank
- Fee withdrawal: 5% dari nominal

**Proses:**
- Request withdrawal
- Admin approve dalam 1-3 hari kerja
- Transfer ke rekening/e-wallet

---

## 10. Notifikasi

### 10.1 Push Notification
**Trigger notifikasi:**
- Ada yang like profil kita
- Match baru
- Pesan baru
- Album terjual
- Saldo masuk (untuk creator)
- Boost profile selesai

### 10.2 Pengaturan
- On/off per kategori notifikasi
- Quiet hours (misal: 22:00 - 08:00)
- Sound & vibration settings

### 10.3 In-app Notification
- Badge counter di tab
- Notification center (list semua notifikasi)
- Clear all notification

---

## 11. Premium Subscription (Optional)

### 11.1 Fitur Premium
- Unlimited likes per hari (free: 50/hari)
- Unlimited undo swipe
- See who likes you (foto tidak blur)
- Prioritas di swipe (muncul lebih sering)
- Hide ads
- Advanced filters (zodiac, religion, dll)

### 11.2 Harga
- 1 bulan: Rp 49.000
- 3 bulan: Rp 129.000 (save 12%)
- 6 bulan: Rp 229.000 (save 22%)

---

## 12. Admin Panel

### 12.1 User Management
- View all users
- Suspend/ban user
- Approve verification request
- Handle report

### 12.2 Content Moderation
- Review album yang dilaporkan
- AI flagging untuk konten tidak pantas
- Remove konten violation

### 12.3 Financial
- Dashboard pendapatan
- Approve withdrawal request
- Refund management

### 12.4 Analytics
- DAU/MAU metrics
- Conversion rate (swipe → match → chat)
- Revenue report
- Top creators

---

## Tech Stack: Supabase + Flutter

### Frontend (Mobile)
- **Flutter**: cross-platform iOS & Android
- **Provider/Riverpod/Bloc**: state management
- **GetIt**: dependency injection
- **Dio**: HTTP client
- **flutter_secure_storage**: menyimpan token

### Backend: Supabase (BaaS)
- **PostgreSQL**: database utama (built-in Supabase)
- **Supabase Auth**: authentication & user management
- **Supabase Storage**: image & video storage
- **Supabase Realtime**: real-time chat & presence
- **PostgREST**: auto-generated REST API
- **Row Level Security (RLS)**: database-level security

### Additional Services
- **Supabase Edge Functions**: custom logic (Deno runtime)
- **Firebase Cloud Messaging (FCM)**: push notifications
- **Cloudflare R2/Supabase Storage**: media storage
- **Midtrans/Xendit**: payment gateway

### AI & Moderation
- **Supabase Edge Functions + OpenAI/Hugging Face**: content moderation
- **AWS Rekognition** atau **Face++**: face verification (via Edge Functions)