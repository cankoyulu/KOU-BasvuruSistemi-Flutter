#!/bin/sh
# Generates web/firebase-config.js from environment variables
# This initializes Firebase via the JS SDK before Flutter loads,
# bypassing the firebase_core Dart-JS interop issue on web.
printf 'window.firebase.initializeApp({apiKey:"%s",authDomain:"%s",projectId:"%s",storageBucket:"%s",messagingSenderId:"%s",appId:"%s"});\n' \
  "$FIREBASE_API_KEY" "$FIREBASE_AUTH_DOMAIN" "$FIREBASE_PROJECT_ID" "$FIREBASE_STORAGE_BUCKET" "$FIREBASE_MESSAGING_SENDER_ID" "$FIREBASE_APP_ID" \
  > web/firebase-config.js
echo "Generated web/firebase-config.js"
