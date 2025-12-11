import * as functions from "firebase-functions/v1";
import * as admin from "firebase-admin";
import axios from "axios";

admin.initializeApp();

const messaging = admin.messaging();

const TMDB_API_KEY = functions.config().tmdb.apikey;
const TMDB_BASE_URL = "https://api.themoviedb.org/3";

export const sendNewMovieNotification = functions.pubsub
  .schedule("0 9,21 * * *")
  .timeZone("Asia/Makassar")
  // PERBAIKAN 2: Tambahkan tipe data ': functions.EventContext'
  .onRun() => {
    try {
      console.log("Memulai pengecekan film baru...");

      const today = new Date();
      const dateString = today.toISOString().split("T")[0];

      const response = await axios.get(`${TMDB_BASE_URL}/discover/movie`, {
        params: {
          "api_key": TMDB_API_KEY,
          "language": "id-ID",
          "sort_by": "popularity.desc",
          "primary_release_date.gte": dateString,
          "primary_release_date.lte": dateString,
          "page": 1,
        },
      });

      const movies = response.data.results;

      if (!movies || movies.length === 0) {
        console.log("Tidak ada film rilis hari ini.");
        return null;
      }

      const topMovies = movies.slice(0, 3);
      // Explicitly type 'm' as any to avoid TS error on movie object structure
      const movieTitles = topMovies.map((m: any) => m.title).join(", ");
      const firstMovieId = topMovies[0].id.toString();

      const message: admin.messaging.Message = {
        topic: "all_users",
        notification: {
          title: "🎬 Film Baru Rilis Hari Ini!",
          body: `Tonton sekarang: ${movieTitles}${movies.length > 3 ? " dan lainnya..." : ""}`,
        },
        data: {
          type: "new_release",
          movieId: firstMovieId,
        },
      };

      await messaging.send(message);
      console.log("Notifikasi film baru berhasil dikirim:", movieTitles);
    } catch (error) {
      console.error("Gagal mengirim notifikasi film baru:", error);
    }

    return null;
  });
