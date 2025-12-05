import { admin } from "./firebase.js";
import fetch from "node-fetch";

const db = admin.firestore();
const messaging = admin.messaging();
const TMDB_API_KEY = process.env.TMDB_API_KEY;

const genreMap = {
  Action: 28,
  Adventure: 12,
  Animation: 16,
  Comedy: 35,
  Crime: 80,
  Documentary: 99,
  Drama: 18,
  Family: 10751,
  Fantasy: 14,
  History: 36,
  Horror: 27,
  Music: 10402,
  Mystery: 9648,
  Romance: 10749,
  "Science Fiction": 878,
  "TV Movie": 10770,
  Thriller: 53,
  War: 10752,
  Western: 37,
};

async function fetchMovies() {
  const today = new Date().toISOString().split("T")[0];

  const url = `https://api.themoviedb.org/3/discover/movie?api_key=${TMDB_API_KEY}&primary_release_date.gte=${today}&primary_release_date.lte=${today}`;
  const response = await fetch(url);
  const data = await response.json();
  return data.results || [];
}

function matchGenres(movie, favoriteGenres) {
  const favoriteIds = favoriteGenres.map((g) => genreMap[g]);
  return movie.genre_ids.some((id) => favoriteIds.includes(id));
}

const dailyMovieNotification = async () => {
  const todayMovies = await fetchMovies();

  const usersSnapshot = await db
    .collection("users")
    .where("isNotificationOn", "==", true)
    .get();

  const notifications = [];

  for (const doc of usersSnapshot.docs) {
    const user = doc.data();
    if (!user.fcmTokens) continue;
    if (!user.isNotificationOn) continue;

    const matchedMovies = todayMovies.filter((movie) =>
      matchGenres(movie, user.favoriteGenres)
    );
    if (matchedMovies.length === 0) continue;

    const title = "Movie Watchlist App";
    const body =
      matchedMovies.length > 1
        ? `${matchedMovies[0].title} and more films matched your interests!`
        : `${matchedMovies[0].title} just released today — check it out!`;

    console.log(user);

    for (const token of user.fcmTokens) {
      notifications.push(
        messaging.send({
          token,
          notification: { title, body },
          data: {
            movieCount: matchedMovies.length.toString(),
          },
        })
      );
    }
  }

  if (notifications.length > 0) {
    await Promise.all(notifications);
  }
};

export const handler = async (event) => {
  await dailyMovieNotification();
};
