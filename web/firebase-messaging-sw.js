importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCCy9v_0bnpxEaDNbw3WXRVLVE3lJGFtJg",
  authDomain: "materialesya-54d7e.firebaseapp.com",
  projectId: "materialesya-54d7e",
  storageBucket: "materialesya-54d7e.firebasestorage.app",
  messagingSenderId: "82439942751",
  appId: "1:82439942751:web:90c83b1ebe3a5eb15521ea",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const { title, body } = payload.notification;
  self.registration.showNotification(title, {
    body,
    icon: "/icons/Icon-192.png",
  });
});
