// Logs in to the LOCAL deployment (reuses update-dina-user-docs/scripts/shot.mjs) and records problems while you drive the page.
// import { start } from "/home/<user>/dina-local-deployment/.agents/skills/test-dina-ticket/scripts/session.mjs";
//   const { browser, page, problems } = await start({ lang: "en" });
import { open, go } from "../../update-dina-user-docs/scripts/shot.mjs";

export { go };

export async function start(opts) {
  const { browser, page } = await open(opts);
  const problems = [];
  page.on("pageerror", (e) => problems.push(`pageerror: ${e.message}`));
  page.on("console", (m) => m.type() === "error" && problems.push(`console: ${m.text().slice(0, 300)}`));
  page.on("response", (r) => r.status() >= 400 && problems.push(`HTTP ${r.status()} ${r.request().method()} ${r.url().slice(0, 200)}`));
  return { browser, page, problems };
}

// Full-page screenshot to a file under the scratchpad/out dir.
export const snap = (page, file) => page.screenshot({ path: file, fullPage: true });
