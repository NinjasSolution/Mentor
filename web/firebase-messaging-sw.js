// This is an empty service worker to prevent the 404 error on web.
// Firebase Cloud Messaging (FCM) requires this file to exist in the web root.

importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker by passing in
// your app's Firebase config object.
// You can find your project's config object in your Firebase project settings.
firebase.initializeApp({
  apiKey: "AIzaSyCYgvQtWUewh1LDsWIoxWr29V_ARhMAucw",
  appId: "1:661763042710:web:b36c3832930a6403dc81b7",
  messagingSenderId: "661763042710",
  projectId: "bgnu-mentor"
});

const messaging = firebase.messaging();
