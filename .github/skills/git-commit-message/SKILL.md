---
name: git-commit-message
description: Generates a git commit message from the user's staged changes (or unstaged changes if nothing is staged), with a header derived from the current branch name and a bullet list of what was done. Use this whenever the user asks for a commit message, git message, "what should I commit this as", wants a summary of their current changes for a commit, or says things like "write my commit", "commit message please", or "message for my changes", even if they don't mention staged or unstaged. This skill ONLY returns text. It never runs git commit, git push, or any command that modifies the repo.
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

## Step 3: Write the bullets

Below the header, leave a blank line, then one bullet per logical change. The goal is for a teammate to understand what the commit did without opening the diff.

- Group by purpose, not by file. Three files changed for one reason is one bullet.
- Use past tense and start with a verb ("Added", "Fixed", "Bumped", "Applied", "Dimmed").
- Name the specific components, packages, or functions involved when that makes the bullet more useful, and say why when the reason isn't obvious (for example "...since they were bypassing it").
- For dependency changes, include the old and new versions.
- Mention test coverage if tests were added or changed ("Added test coverage.").
- Skip trivia like whitespace, import reordering, or formatting unless that's the whole change.
- Match the size of the change: a one-line fix gets one bullet; a broad change gets three to five. Don't pad.

## Output format

Return the message inside a single fenced code block so it can be copied cleanly, with a one-line note above it about which changes were used. No extra commentary after the block unless something needs flagging (such as a branch with no ticket, or a diff that seems to mix unrelated work that might deserve separate commits).

## Examples

**Example 1** (staged changes across several components, with tests):

```
Feature #81538 - Visualizing Empty Fields on View Pages

- Show a muted dash for empty fields on view pages, centralized in FieldWrapper/FieldView so it applies everywhere.
- Fixed ResourceSelectField, NumberRangeFields, and MaterialSampleStateWarning to actually pick this up since they were bypassing it.
- Dimmed the tooltip icon on empty fields too.
- Added test coverage.
```

**Example 2** (small follow-up on the same branch):

```
Feature #81538 - Visualizing Empty Fields on View Pages

- Applied dim logic to String Array field.
```

**Example 3** (dependency work on a task branch):

```
Task #81499 - Upgrade Dependencies

- Bumped next and eslint-config-next from 16.2.12 to 16.3.5
- Added resolutions for shell-quote and flattened
- Bumped immutable via scoped resolutions (5.1.9 for sass, 4.3.9 for react-awesome-query-builder).
```