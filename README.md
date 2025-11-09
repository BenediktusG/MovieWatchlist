# Watchlist App

Aplikasi untuk melacak film dan serial TV. Dibuat dengan Flutter dan TMDB API.

## 🚀 Setup (Cara Menjalankan Proyek)

Untuk menjalankan proyek ini di komputer Anda, ikuti langkah-langkah berikut:

1.  **Clone Repository**
    ```bash
    git clone https://github.com/BenediktusG/MovieWatchlist
    cd MovieWatchlist
    ```

2.  **Dapatkan API Key TMDB**
    * Proyek ini memerlukan API key dari The Movie Database (TMDB).
    * Daftar dan dapatkan key gratis Anda di https://www.themoviedb.org/

3.  **Buat File .env**
    * Di folder utama (root) proyek, buat file baru bernama `.env`.
    * Salin API key v3 Anda ke dalam file tersebut seperti ini:

    ```
    TMDB_API_KEY=MASUKKAN_API_KEY_V3_ANDA_DI_SINI
    ```

4.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

5.  **Jalankan Aplikasi**
    ```bash
    flutter run
    ```