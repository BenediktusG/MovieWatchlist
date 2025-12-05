import admin from "firebase-admin";
import { createRequire } from "module";
const require = createRequire(import.meta.url);

const serviceAccount = require("../key/firebase-private-key.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

export { admin };
