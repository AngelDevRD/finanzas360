#!/usr/bin/env node
/**
 * Valida la regla de versionado del framework: ninguna APK nueva puede publicarse con una
 * version igual o inferior a la ultima ya publicada. Pensado para correr como paso de CI en
 * los repos Flutter (finanzas360, snake_evolution, etc.) antes de crear el GitHub Release.
 *
 * Modo A — comparar dos versiones explicitas (uso tipico en CI, antes de crear el tag):
 *   node tools/verify-release-version.mjs --new v1.2.0 --previous v1.1.0
 *
 * Modo B — comparar contra el ultimo release ya publicado en GitHub:
 *   node tools/verify-release-version.mjs --repo AngelDevRD/finanzas360 --new v1.2.0
 *
 * Sale con codigo 1 y un mensaje de error si "new" no es estrictamente mayor que la version
 * previa (semver). Sale 0 si es valido o si no hay releases previos (primer release).
 */

const GITHUB_API = "https://api.github.com";

function arg(name) {
  const i = process.argv.indexOf(`--${name}`);
  return i === -1 ? undefined : process.argv[i + 1];
}

function parseSemver(raw) {
  const cleaned = String(raw).trim().replace(/^v/i, "");
  const match = cleaned.match(/^(\d+)\.(\d+)\.(\d+)/);
  if (!match) {
    throw new Error(`"${raw}" no es una version semver valida (esperado vMAJOR.MINOR.PATCH)`);
  }
  return [Number(match[1]), Number(match[2]), Number(match[3])];
}

function compareSemver(a, b) {
  const [aMaj, aMin, aPatch] = parseSemver(a);
  const [bMaj, bMin, bPatch] = parseSemver(b);
  if (aMaj !== bMaj) return aMaj - bMaj;
  if (aMin !== bMin) return aMin - bMin;
  return aPatch - bPatch;
}

async function fetchLatestPublishedVersion(repo) {
  const token = process.env.GITHUB_TOKEN;
  const res = await fetch(`${GITHUB_API}/repos/${repo}/releases?per_page=1`, {
    headers: {
      Accept: "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
  });
  if (!res.ok) {
    throw new Error(`No se pudo consultar releases de ${repo}: HTTP ${res.status}`);
  }
  const releases = await res.json();
  return releases[0]?.tag_name ?? null;
}

async function main() {
  const newVersion = arg("new");
  const explicitPrevious = arg("previous");
  const repo = arg("repo");

  if (!newVersion) {
    console.error("Uso: verify-release-version.mjs --new vX.Y.Z [--previous vX.Y.Z | --repo owner/repo]");
    process.exit(1);
  }

  let previousVersion = explicitPrevious ?? null;
  if (!previousVersion && repo) {
    previousVersion = await fetchLatestPublishedVersion(repo);
  }

  if (!previousVersion) {
    console.log(`OK: sin version previa que comparar (primer release). Nueva version: ${newVersion}`);
    return;
  }

  const cmp = compareSemver(newVersion, previousVersion);
  if (cmp <= 0) {
    console.error(
      `ERROR: la version nueva "${newVersion}" no es superior a la ultima publicada "${previousVersion}". ` +
        `Incrementa versionName/versionCode (o buildNumber) antes de publicar.`
    );
    process.exit(1);
  }

  console.log(`OK: ${newVersion} > ${previousVersion}`);
}

main().catch((err) => {
  console.error(`ERROR: ${err.message}`);
  process.exit(1);
});
