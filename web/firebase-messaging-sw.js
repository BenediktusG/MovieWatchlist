// web/firebase-messaging-sw.js

importScripts("https://www.gstatic.com/firebasejs/9.22.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.22.1/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: 'AIzaSyCB9JRwPZJsp8IexDqgHpw-r2_xElEmpz4',
  appId: '1:398685397061:web:087c6139d4c55e7746832c',
  messagingSenderId: '398685397061',
  projectId: 'movie-watchlist-f0a2d',
  authDomain: 'movie-watchlist-f0a2d.firebaseapp.com',
  storageBucket: 'movie-watchlist-f0a2d.firebasestorage.app',
  measurementId: 'G-V3FD3L54NX'
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log(
    '[firebase-messaging-sw.js] Received background message ',
    payload
  );
});