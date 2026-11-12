// Self-contained browser session for the LOCAL DINA deployment. Logs in through Keycloak and records problems while you drive the page.
// Setup once: `npm install` in this scripts/ folder, then `npx playwright install chromium`.
// import { start, go, snap } from "/home/<user>/dina-local-deployment/.agents/skills/test-dina-ticket/scripts/session.mjs";
//   const { browser, page, problems } = await start({ lang: "en" });
import { chromium } from "playwright";

const BASE = "https://dina.local";
const USERNAME = process.env.DINA_USERNAME ?? "dina-su";
const PASSWORD = process.env.DINA_PASSWORD ?? "dina-su";

export async function start({ lang = "en", headless = true } = {}) {
  const browser = await chromium.launch({ headless });
  const context = await browser.newContext({ ignoreHTTPSErrors: true, viewport: { width: 1400, height: 900 } });
  const page = await context.newPage();
  page.setDefaultTimeout(15000);
  await login(page);

  // Listen only after login so Keycloak's own login-page errors don't end up in problems.
  const problems = [];
  page.on("pageerror", (e) => problems.push(`pageerror: ${e.message}`));
  page.on("console", (m) => m.type() === "error" && problems.push(`console: ${m.text().slice(0, 300)}`));
  page.on("response", (r) => r.status() >= 400 && problems.push(`HTTP ${r.status()} ${r.request().method()} ${r.url().slice(0, 200)}`));

  if (lang !== "en") {
    // dina-ui keeps the language in localStorage as JSON (@rehooks/local-storage).
    await page.evaluate(([key, value]) => localStorage.setItem(key, JSON.stringify(value)), ["locale", lang]);
    await page.reload({ waitUntil: "domcontentloaded" });
  }
  return { browser, page, problems };
}

async function login(page) {
  await page.goto(BASE + "/", { waitUntil: "domcontentloaded" });
  // Unauthenticated users are redirected to the Keycloak login form.
  await page.waitForURL((u) => u.pathname.includes("/realms/dina/"), { timeout: 20000 });
  await page.locator("#username").fill(USERNAME);
  await page.locator("#password").fill(PASSWORD);
  await page.locator("#kc-login").click();
  await page.waitForURL((u) => u.hostname === "dina.local" && !u.pathname.includes("/auth/"), { timeout: 30000 });
  await page.waitForLoadState("networkidle").catch(() => {});
}

// Navigate within the local deployment, e.g. go(page, "/collection/material-sample/list").
export async function go(page, path) {
  const url = new URL(path, BASE);
  if (url.origin !== BASE) throw new Error(`Refusing non-local host: ${url.origin}`);
  await page.goto(url.href, { waitUntil: "domcontentloaded" });
  await page.waitForLoadState("networkidle").catch(() => {});
}

// Full-page screenshot to a file under the scratchpad/out dir.
export const snap = (page, file) => page.screenshot({ path: file, fullPage: true });
