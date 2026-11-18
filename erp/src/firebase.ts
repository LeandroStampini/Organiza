import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

// Mesma configuração web usada pelo app Flutter (lib/firebase_options.dart).
const app = initializeApp({
  apiKey: 'AIzaSyApZbSoD4_j7-hRo0v0IY3sQ-OTh9A9dcU',
  appId: '1:355231076214:web:4d53aefe30a02e5b86f457',
  messagingSenderId: '355231076214',
  projectId: 'oragnizamais',
  authDomain: 'oragnizamais.firebaseapp.com',
  storageBucket: 'oragnizamais.firebasestorage.app',
});

export const auth = getAuth(app);
export const db = getFirestore(app);
