// .eslintrc.js -- generado por Antigravity AI
// Extiende las reglas AG-CORE. Personalizar segun el proyecto.
/** @type {import("eslint").Linter.Config} */
module.exports = {
  extends: ["next/core-web-vitals"],
  rules: {
    // AG-CORE-001: catch vacio prohibido
    "no-empty": ["error", { "allowEmptyCatch": false }],
    // AG-CORE-006: console.log prohibido en produccion
    "no-console": ["error", { "allow": [] }],
    // AG-CORE-003: async sin manejo de errores
    "no-async-promise-executor": "error",
    "no-return-await": "error",
    "no-await-in-loop": "warn",
    // Calidad general
    "prefer-const": "error",
    "no-var": "error",
  },
  overrides: [
    {
      // Tests pueden usar console
      files: ["**/*.test.ts", "**/*.spec.ts", "**/*.test.js"],
      rules: { "no-console": "off" },
    },
  ],
}