---
name: update-dina-user-docs
description: Maintain the DINA User Guide (dina-documentation/asciidoc/user-guide) against the LOCAL deployment at https://dina.local - refresh outdated screenshots and the step text around them, capture French versions of screenshots and sync the French guide (fr/), or document a newly added feature (new steps, screenshots, English and French text). Use when the user asks to update/refresh/retake user-guide screenshots, check the guide against the current UI, produce French screenshots or French docs, or add a feature to the user guide. Local only.
---

# Update DINA User Docs

Keep the **DINA User Guide** in line with the current UI:

- **Refresh** screenshots and the step text around them after UI changes.
- **French**: capture French screenshots and keep `fr/*.adoc` in sync with the English guide.
- **New feature**: write new steps, screenshots and text (English and French).

Screenshots come from the **local** deployment (`https://dina.local`) using headless Chromium (Playwright). Write throwaway `.mjs` scripts in the scratchpad (never in the repos). If Playwright isn't installed there, run `npm i playwright && npx playwright install chromium`.

## Where things are

| What | Where |
|---|---|
| English guide | `~/dina-documentation/asciidoc/user-guide/*.adoc` (`index.adoc` includes the sections in order) |
| French guide | `.../user-guide/fr/*.adoc` (`fr/index.adoc` has `:imagesdir: ../images`) |
| English images | `.../user-guide/images/<area>/<Name>.png` (shared images at the root: `EditRevDelete.png`, `EditDelete.png`, `SignIn.png`) |
| French images | `.../user-guide/images/fr/<same path>`, referenced as `image::fr/<area>/<Name>.png[...]` |
| UI source | `~/dina-ui/packages/dina-ui` (pages, components), `intl/dina-ui-{en,fr}.ts`, `~/dina-ui/packages/common-ui/lib/intl/common-ui-{en,fr}.ts` |

If a repo isn't at that path, look for it next to `dina-local-deployment`.

## Ground rules

- **Local only.** Never capture from or write to dev2/test/prod.
- **Login** as `dina-su` / `dina-su`. Use `dina-admin` only when a page needs admin rights, and say so.
- **Replace an image only when the UI changed.** Compare the original with the current page first. Keep non-DINA images (e.g. the Windows file dialog) and unchanged pages (Keycloak `SignIn.png`).
- **Read every PNG you produce** before it goes into the repo. Check for leftover annotations, focus rings, cut-off dialogs, half-loaded thumbnails and other people's data.
- **The text must match the UI.** Put button and field names in backticks, exactly as shown (`Create New`, not `Create new`). When a flow changes, update the steps too, not just the image.
- **Writes:** do a read-only dry run first, then create the test records the walkthrough needs. Deleting or editing existing records needs the user's OK. After a failed save, check what exists (`dina-api` skill) before retrying.
- **Don't show other people's data.** Filter, sort or crop lists so only your test records appear.
- **Never print tokens.** Skip `/auth/` URLs when logging network traffic.
- **Preserve line endings.** Some `.adoc` files are CRLF and some LF. Edit with the Edit tool, not `sed`.
- **Don't commit or push** unless asked. Use the `git-commit-message` skill for commit messages.

## Capturing

- **Login:** go to `https://dina.local/` with `ignoreHTTPSErrors`, fill `#username` / `#password`, press Enter, and wait until the URL no longer contains `/auth/`. To switch language, click the header link `Français` / `English` and wait for `html[lang=fr]`.
- **Every page, after navigation:** wait for `networkidle`, then inject the Noto Sans font (it isn't installed in WSL, so text looks wrong without it): `addStyleTag({ url: "https://fonts.googleapis.com/css2?family=Noto+Sans:ital,wght@0,400;0,700;1,400&display=block" })`. Hide the Next.js dev badge (`nextjs-portal{display:none!important}`) and await `document.fonts.ready`.
- **Viewport:** 1440×900 at device scale 1. Make it taller (e.g. 1300) for tall dialogs.

### Visual conventions (measured from the original images)

- **Colour:** red `#ED1C24`.
- **Arrow:** 162×41 px, polygon `0,9 76,9 76,0 162,20.5 76,41 76,32 0,32` (points right; rotate it about the tip for other directions). Put the tip about 17 px from the target, or from the box outline when both are used. Add it as an absolutely positioned SVG with a high z-index and `pointer-events:none`.
- **Box:** 5 px stroke with about 8 px clearance. Use 1–4 px where 8 would cover nearby text.
- Use an arrow, a box, or both, following the original image for that step.
- **Crops:**
  - Page-width shots: x = 16 to 1424.
  - Homepage shots: y = 176 (below the nav bar) down to 16 px below the last Sequencing link (`/seqdb/thermocycler-profile/list`). Box the target link and point an arrow at it from the right (pointing left, 30 px gap).
  - "Create New" shots: from 10 px above the button down to 12 px below the Reset / Reset Filters button, with a right-pointing arrow on the button.
  - List shots: from 12 px above the `h1` down to just below the row being pointed at.
  - Button groups: tight crop with 4 px padding. Dialogs: the dialog plus 8 px padding.
  - **French images copy the English image's framing** (same edges and, where possible, same height). Compare them with `file`.
- **Test data names** (reuse them, and check with `dina-api` whether they already exist): `TEST Collection` (code `TESTC`), `TestSample-0/1/2`, `TestSample-1-a/-b`, `TestColEvent`, `TestProject`, `Test Building > Test Room > Test Plate`, `Bob D. Builder` (`bob.builder@example.com`), `TestTransaction`, `TestProtocol`, `TestAttribute`, `TestLink1/2`, `FASTASample.txt`, `BulkLink-1..4.txt`, workbook rows `Sample 1..10`, split configs `Normal Split`, `Molecular Split`, `Part to Part`.
- Keep the file name and path of the image being replaced. New images go next to their section's other images.

## Workflow

1. **Inventory.** Go through sections in `index.adoc` order. For each one, Read the `.adoc` and every image it references, noting framing, annotations and the data shown. Do shared images (`material-sample/Homepage.png`, `EditRevDelete.png`, ...) once, in the first section that uses them.
2. **Compare.** Take full-page screenshots of the current pages and list what changed: labels, icons, layout, new or removed steps, dialogs. When behaviour is unclear, **read the dina-ui source** rather than guessing. Form fields are wrapped in `label.<fieldName>-field`.
3. **Capture.** Run a dry run, Read every output, fix problems, then create data if the steps need it. Verify the result through the API.
4. **Update.** Copy the images into `images/<area>/` and update the step text.
5. **French.** Repeat with the UI in French and save to `images/fr/<same path>`. Point the `fr/*.adoc` references at `fr/...` (shared images too) and make the same structural changes as in English. Fix French wording to match the French UI:
   - `dina-ui-fr.ts` **overrides** `common-ui-fr.ts` (e.g. the UI shows `Créer`, not common-ui's `Créer nouveau`).
   - Some strings have no translation and show in English (`Global search`, `Split Configurations`, ...). Quote what the UI shows.
   - Find a label's key with `grep -n '"English label"' intl/dina-ui-en.ts`, then grep that key in the `-fr.ts` files.
   - `SignIn.png` (Keycloak): click `#kc-current-locale-link` → "French (Français)". Clip `{x:289, y:32, width:848, height:800}` and scale it down to 458×432 on a canvas with `imageSmoothingQuality="high"`. Don't use a fractional deviceScaleFactor: it adds colour fringes to the text.
6. **New feature:** find it in dina-ui (git log, pages, intl EN+FR) and check that the local UI has it. Either add steps to an existing section, or add a new `<feature>.adoc` + `fr/<feature>.adoc` and include them in both index files. Follow the guide's style: `[id=...]` anchors, `== Title`, numbered steps, `image::area/Name.png[align="center"]` between steps, `NOTE:`/`TIP:`/`WARNING:` admonitions. An `image::` ends the list, so the next step needs `[start=N]`.
7. **Check.**
   - Every `image::` target exists, and no image is left unused (check both `*.adoc` and `fr/*.adoc`).
   - Both guides build cleanly: `npx asciidoctor --failure-level WARN -D <tmp> index.adoc` and the same for `fr/index.adoc`.
   - Where the list structure changed, look at the rendered HTML to confirm the step numbering.

## Gotchas

- **Annotations survive client-side navigation.** Remove your overlays after every navigation.
- **Sticky bars** in full-page shots render at the current scroll position. Scroll to the top first, or for "scrolled" shots use a viewport capture with `position:fixed` annotations. Use `behavior:"instant"` scrolling and wait about 1 s.
- **Focus rings:** blur `document.activeElement` before capturing. react-select re-focuses right after a pick, so wait 300 ms first.
- **react-select:** click the `-control` ancestor, not the placeholder. `[class*=-menu]` also matches Bootstrap's `dropdown-menu`.
- **Toggles** (`react-switch`): click `.react-switch-bg`, not the hidden checkbox.
- **Selectors:** nav dropdowns share names with homepage links, so use `a[href="..."]`. Pass `exact: true` so `Save` doesn't match `Save & Copy To Next`. Bulk edit renders duplicate hidden panels, so add `:visible`.
- **Arrows:** aim at the text's rect for wide dropdown rows. Point from another side, or use a box alone, when an arrow would cover neighbouring buttons, other list rows, or French labels (which wrap and are longer).
- **Dev mode:** the first visit to a page compiles slowly. Wait for the URL, not a fixed timeout.
- **Search** treats file names as whole words (`FASTASample.txt`, not `FASTASample`). Use `Filename` + `Starts with`. Column sorting is localStorage only.
- **Workbook upload:** build the `.xlsx` with ExcelJS, because SheetJS files get a 415. Use sheet "Intake Sheet". Skipped columns show a "Proceed with warnings?" dialog (`Import anyway`).
- **File inputs:** use `setInputFiles()`. Thumbnails load late, so wait for them (or "No thumbnail available").
- **Collecting event:** "Collection Number" is `dwcFieldNumber`; `dwcRecordNumber` is "Collector's Number".
- **Reused data has state:** `TestSample-0` already has a collecting event, so use `TestSample-2` for "activate Collecting Event" shots. The split preview POSTs to the identifier generator, which creates nothing; nothing is saved until Save All.

## Report

- Images replaced / kept (and why) / added.
- Text changes per section, calling out workflow changes that need a human read.
- Test records created (name and id). Offer cleanup, one record at a time after the user confirms.
- What wasn't verified (e.g. French wording that needs a native-speaker review).
- Nothing committed. Offer a commit message.
