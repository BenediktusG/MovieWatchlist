module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:import/errors",
    "plugin:import/warnings",
    "plugin:import/typescript",
    "google",
    "plugin:@typescript-eslint/recommended",
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: ["tsconfig.json", "tsconfig.dev.json"],
    sourceType: "module",
  },
  ignorePatterns: [
    "/lib/**/*", // Ignore built files.
    "/generated/**/*", // Ignore generated files.
  ],
  plugins: [
    "@typescript-eslint",
    "import",
  ],
  rules: {
    "quotes": ["error", "double"],
    "import/no-unresolved": 0,
    
    // Matikan aturan yang rewel di Windows
    "linebreak-style": 0,
    "max-len": 0,
    "object-curly-spacing": 0,
    "quote-props": 0,
    "padded-blocks": 0,
    "no-trailing-spaces": 0,
    "eol-last": 0,
    "indent": 0, // Pastikan ini hanya muncul SATU KALI
    
    // Matikan warning TypeScript yang muncul di log kamu
    "@typescript-eslint/no-unused-vars": 0,
    "@typescript-eslint/no-explicit-any": 0
  },
};
