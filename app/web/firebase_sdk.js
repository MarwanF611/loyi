// Loads the Firebase JS SDK from a file, then starts Flutter.
//
// FlutterFire normally injects the SDK with inline <script> tags, which the
// Content-Security-Policy in firebase.json blocks (no 'unsafe-inline'). When
// window.firebase_core already exists, FlutterFire skips that and uses these.
// The version must match firebase_core_web's supportedFirebaseJsSdkVersion;
// test/firebase_sdk_version_test.dart fails when a package upgrade changes it.
// The SDK is served from Loyi's own hosting (web/firebase/<v>/, made by
// scripts/vendor-firebase-sdk.sh), not Google's CDN, so loading the app sends no visitor
// data to a third party.
const v = "12.19.0";
const sdk = (name) => import(`./firebase/${v}/firebase-${name}.js`);

// firebase-app first: the other bundles import it (see flutterfire#18436 for the Safari race).
window.firebase_core = await sdk("app");
const [auth, firestore, appCheck] = await Promise.all([sdk("auth"), sdk("firestore-pipelines"), sdk("app-check")]);
window.firebase_auth = auth;
window.firebase_firestore = firestore;
window.firebase_app_check = appCheck;

const bootstrap = document.createElement("script");
bootstrap.src = "flutter_bootstrap.js";
bootstrap.async = true;
document.body.append(bootstrap);
