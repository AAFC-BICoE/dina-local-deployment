---
name: git-commit-message
description: Generates a git commit message from the user's staged changes (or unstaged changes if nothing is staged), with a header derived from the current branch name and a bullet list of what was done. Use this whenever the user asks for a commit message, git message, "what should I commit this as", wants a summary of their current changes for a commit, or says things like "write my commit", "commit message please", or "message for my changes", even if they don't mention staged or unstaged. It appends a disclosure line saying the content includes AI-generated code by default (asking the user first when they're available, and omitting it only if they explicitly say no AI was involved). This skill ONLY returns text. It never runs git commit, git push, or any command that modifies the repo.
---

# Git Commit Message

Produce a ready-to-paste commit message based on the user's current changes and branch name. The user does the actual committing themselves, so this skill is strictly read-only.

## Hard rule: never change the repo

Only run read-only git commands (`git status`, `git diff`, `git branch`, `git log`, `git show`). Never run `git commit`, `git push`, `git add`, `git stash`, `git reset`, `git checkout`, or anything else that alters the working tree, index, or remote. The user wants to review and commit on their own terms, so the deliverable is text only. If the user asks you to commit or push, remind them this skill only writes the message.

## Step 1: Pick which changes to describe

1. Run `git diff --cached --stat`. If there is output, there are staged changes: describe **only the staged changes** (use `git diff --cached` for details). Staged wins because it reflects what the user is about to commit.
2. If nothing is staged, run `git diff --stat`. If there is output, describe the **unstaged changes** (use `git diff`).
3. Also run `git status --short`. Untracked files (`??`) don't appear in diffs, so read them directly if they look relevant (new components, tests, etc.) and include them when describing unstaged work.
4. If there are no changes at all, say so and stop. Don't invent a message.

Start with the `--stat` output to get the shape of the change, then read the full diff for the files that matter. For very large diffs, skim generated or noisy files (lockfiles, snapshots, build output) and only read them closely enough to report something meaningful, such as which versions changed.

Briefly tell the user which set you used ("Based on your staged changes" / "Nothing staged, so based on your unstaged changes") so there's no confusion about what the message covers.

## Step 2: Build the header from the branch name

Run `git branch --show-current`. Branch names look like `feature-81538-visualize-empty-fields-on-view-pages` or `task-81499-upgrade-dependencies`. Parse three parts:

- **Type**: the leading word (`feature`, `task`, `bug`, `fix`, ...), capitalized. Map `fix`/`bugfix`/`hotfix` to `Bug`.
- **Number**: the ticket id, rendered as `#81538`.
- **Title**: the remaining slug words, converted to a human-readable Title Case phrase.

Format: `<Type> #<number> - <Title>`

Branches sometimes carry a folder or username prefix (`feature/81538-...`, `jsmith/feature-81538-...`). Ignore that prefix and separators like `/`, `-`, `_` when parsing.

Keep the title faithful to the branch. Light polish for readability is fine (for example `visualize-empty-fields` can read as "Visualizing Empty Fields"), but don't invent scope the branch doesn't state.

If the branch doesn't follow this pattern (`main`, `develop`, no ticket number), don't guess a ticket. Write a short descriptive header from the changes themselves and add a one-line note telling the user the branch had no ticket to derive it from.

## Step 3: Write a simplified message

Keep the message short. Always use this format:

- Use one bullet for most changes. Use at most three bullets, and only when the commit has clearly separate purposes.
- Each bullet is one short sentence in past tense, starting with a verb. Aim for under 12 words.
- Don't list file names, function names, reasons, or test and formatting notes unless they are the whole change.
- For dependency bumps, name the package and the old and new versions.

## Step 4: AI-generated code disclosure (included by default)

Whether code was AI-generated or AI-assisted is something only the user knows, and a diff can't reveal it. The safe default is to **always include** the disclosure line, because a missing disclosure is worse than an unnecessary one. Only leave it out when the user has explicitly said the changes contain no AI-generated or AI-assisted code.

Add this as the last line of the message, separated from the bullets by a blank line, worded exactly:

`Content of the commit includes AI generated code`

Keep the wording exactly as written, since it may be matched by team tooling or conventions.

Decide how to handle it like this:

- **The user is available to respond:** After reading the changes (Steps 1-3), ask one short question before the final message: "Does this commit include AI-generated or AI-assisted code?" Use a tappable-options tool (such as `ask_user_input_v0`) with "Yes" and "No" when one is available; otherwise ask in plain text. Include the line for "Yes" or "partly". Omit it only for a clear "No".
- **The user already said in their request:** If they stated it up front ("Claude wrote most of this", "all handwritten"), skip the question and follow what they said.
- **The user is not available to respond:** This includes autonomous or autopilot runs, such as a message saying the user is unavailable, will review later, or that you should work autonomously. Don't ask and don't wait. Include the line, and mention in the note above the code block that it was added by default because the user couldn't be asked.
- **No answer, or an unclear answer:** Include the line.

## Output format

Return the message inside a single fenced code block so it can be copied cleanly, with a one-line note above it about which changes were used. The AI disclosure line (included by default) goes at the very bottom inside the block. No extra commentary after the block unless something needs flagging (such as a branch with no ticket, or a diff that seems to mix unrelated work that might deserve separate commits).

## Examples

**Example 1** (staged changes across several components, with tests):

```
Feature #81538 - Visualizing Empty Fields on View Pages

- Showed a muted dash for empty fields on view pages.
```

**Example 2** (small follow-up on the same branch):

```
Feature #81538 - Visualizing Empty Fields on View Pages

- Applied dim logic to String Array field.
```

**Example 3** (dependency work on a task branch):

```
Task #81499 - Upgrade Dependencies

- Bumped next and eslint-config-next from 16.2.12 to 16.3.5.
```

**Example 4** (default, or the user said the changes include AI-assisted code; also used in autonomous runs):

```
Feature #81538 - Visualizing Empty Fields on View Pages

- Applied dim logic to String Array field.

Content of the commit includes AI generated code
```
