---
name: build-dina-images
description: Build local Docker images of DINA API modules (collection-api, object-store-api, agent-api, seqdb-api, dina-search-api's search-ws / search-cli, etc.) and wire them into dina-local-deployment so local code changes can be tested, including changes to the dina-base-api library consumed by those modules. Use this skill whenever the user asks to build a local/dev image of a DINA module, test their API or dina-base-api changes in the local deployment, point docker-compose.local.yml at a local image, rebuild or restart after further changes, or revert back to the Docker Hub images. Do not use it for dina-ui (it has its own live-reload setup). Only run the build/deploy commands when the user explicitly asks for them (see Ground rules).
---

# Build DINA Images

By default, `dina-local-deployment` runs the API modules published on Docker Hub. This skill swaps one or more of those for images built from the user's local source so they can test API changes end to end.

The examples below use `collection-api`, but the steps are identical for every other API module. (UI work is different: `dina-ui` has its own live-reloading development setup, so don't use this workflow for UI changes.)

Normally this is done when the user has changes in the API code and wants to test them in the local deployment.

## Ground rules

These matter more than anything else in this skill:

- **Only start the workflow when the user explicitly asks.** Don't build, rebuild, or edit the compose file on your own initiative — for example, don't kick off a build just because you finished editing API code. If it seems like a rebuild would help, suggest it and wait for a yes. Once the user has asked for a build, carry out the whole workflow, including the restart in step 4 and the verification in step 5, without asking again.
- **Never push images to Docker Hub** (or any registry). These images are for local use only. That means no `docker push`, no `docker login`, and no tagging images with a Docker Hub namespace (e.g. `aafcbicoe/...`). Use a plain local tag like `collection-api:dev`.

### What counts as an explicit ask

| Counts as a request (start the workflow) | Does not count (finish the task, then suggest a build and wait) |
|---|---|
| "Build collection-api locally and run it" | "I finished the new endpoint" |
| "Rebuild and restart object-store-api" | "Can you fix this bug in collection-api?" |
| "Test my base-api changes with collection-api" | "Add a field to the Specimen resource" |
| "Point the local deployment at my agent-api build" | "Does this change look right?" |
| "Revert to the Docker Hub images" | |

After finishing a code change that the user hasn't asked to build, a one-line suggestion is fine: "Want me to build and restart collection-api so you can test this?"

## Before starting

Confirm (or find out) the following. If anything is unclear, ask rather than guess:

1. **Which module(s)** to build.
2. **Where the module's source lives.** The paths in this skill (`~/collection-api`, `~/dina-local-deployment`, ...) are examples. Look for the repos first, for example as sibling directories of `dina-local-deployment` or in the current working directory. Only ask if you cannot find them.

### Finding the available APIs and their services

`dina-local-deployment/docker-compose.local.yml` is the source of truth for which API modules can be swapped for a local image. Read it to find the service name for the module the user wants (the service name is usually the module name, but check). Each API service's `image` line is the one step 3 changes.

Don't use `docker-compose.base.yml` to pick services to build. It holds the shared infrastructure services (such as `initdb`) that aren't API modules, so there's nothing to build for them.

Once you know the service, find the module's `Dockerfile` in its repo. It's usually at the repo root, except for repos with several containers (see the `dina-search-api` special case). Use `<module-name>:dev` as the local tag. If you can't tell which service matches the module, ask the user.

## Workflow

### 1. Clean and build the API

From the root of the API project:

```shell
cd ~/collection-api
mvn clean install -DskipTests
```

`-DskipTests` skips the test suite for a faster build. Use it by default; drop it if the user wants tests to run. If the Maven build fails, stop and report the error — there's no point building an image from a broken jar. A common cause is the wrong Java version, so if the error looks like a compiler or toolchain problem, compare `java -version` with what the project's `pom.xml` expects.

### 2. Build the Docker image

Each API module contains a `Dockerfile`. From the same directory, build and tag the image:

```shell
docker build -t collection-api:dev .
```

Use `<module-name>:dev` as the tag unless the user asks for something else. The tag is what step 3 references. If the build fails because the Docker daemon isn't reachable, ask the user to start Docker and try again.

### 3. Point docker-compose.local.yml at the local image

First, check whether the compose file already has uncommitted changes, and remember the answer for the revert step:

```shell
cd ~/dina-local-deployment
git diff --stat docker-compose.local.yml
```

Then, in `dina-local-deployment/docker-compose.local.yml`, find the module's service and change its `image` to the tag from step 2. Change only the `image` line; leave everything else alone:

```yml
  collection-api:
    image: collection-api:dev
    environment:
      keycloak.enabled: "true"
```

Note what the original image was before changing it (for example `aafcbicoe/collection-api:<version>`), so you can tell the user what they've swapped out.

If Docker Compose tries to pull `collection-api:dev` from Docker Hub instead of using the local image, see Troubleshooting below.

### 4. Restart the container

From inside the `dina-local-deployment` repo, restart only the service(s) you just built. Run this automatically as part of the workflow — don't ask for permission first:

```shell
./start_stop_dina.sh up -d collection-api
```

Always use the name of the container you actually built (e.g. `./start_stop_dina.sh up -d object-store-api` for object-store-api). If you built more than one, list them all in the same command:

```shell
./start_stop_dina.sh up -d search-ws search-cli
```

### 5. Verify the new container is running

Don't assume the restart worked. Run these checks for each restarted service:

```shell
docker ps --filter name=collection-api
docker inspect --format '{{.Config.Image}}' collection-api
docker logs --tail 50 collection-api
```

- `docker inspect` should print the local tag (`collection-api:dev`). If it prints the Docker Hub image, the container wasn't recreated; see Troubleshooting.
- `docker ps` should show the container as `Up`, not restarting or exited.
- In the logs, look for the application starting normally. Startup can take a little while, so if the app hasn't finished starting, check again after a short wait before drawing conclusions.

If the container is restarting, exited, or the logs show a startup error, stop and report the relevant log lines to the user. Don't keep rebuilding in a loop.

The user is now running their local changes.

## Iterating on further changes

The container runs the jar produced in step 1, so later code changes aren't picked up automatically. When the user asks to test newer changes, repeat steps 1, 2, 4, and 5. Step 3 only needs repeating if the tag changes — if `docker-compose.local.yml` already points at `collection-api:dev`, just rebuild and restart.

## Special case: dina-search-api

`dina-search-api` contains two containers, `search-ws` and `search-cli`, each with its own Dockerfile in a subdirectory. Run the Maven build from the repo root, then `cd` into the relevant subdirectory before building the image:

```shell
cd ~/dina-search-api
mvn clean install -DskipTests

cd search-ws
docker build -t search-ws:dev .
```

Do the same in `search-cli` if the user wants that one too (tag `search-cli:dev`). Then update the matching service(s) in `docker-compose.local.yml` and restart and verify them as in steps 4 and 5. If it isn't clear which of the two the user changed, ask.

## Special case: dina-base-api changes

`dina-base-api` is a shared library, not a container, so it has no image of its own. To test changes to it, install a snapshot build into the local Maven repository, point a consuming API at that snapshot, and then build that API as usual. The user will say which API to test with (e.g. "test my base-api changes with collection-api"). If they don't, ask.

### A. Make sure dina-base-api has a -SNAPSHOT version

Check the `<version>` in `dina-base-api`'s root `pom.xml`. It needs to be a snapshot version such as `0.204-SNAPSHOT`.

- If it already ends in `-SNAPSHOT`, use it as is.
- If it's a release version (e.g. `0.203`), propose the next version with `-SNAPSHOT` (e.g. `0.204-SNAPSHOT`) and confirm it with the user before changing anything, since the team may follow its own versioning convention. Once confirmed, change it and tell the user you did. If the project has child modules, their `<parent>` versions must match too. The simplest way to keep them all in step is:

  ```shell
  mvn versions:set -DnewVersion=0.204-SNAPSHOT -DgenerateBackupPoms=false
  ```

A snapshot version keeps the local build clearly separate from the published releases, so the consuming API picks up the user's local code rather than a release from the remote repository.

### B. Build and install dina-base-api

```shell
cd ~/dina-base-api
mvn clean install -DskipTests
```

`install` puts the jar into the local Maven repository (`~/.m2`), which is where the consuming API will find it. If the build fails, stop and report the error.

### C. Point the consuming API at the snapshot

In the consuming API's `pom.xml`, update the dina-base-api version to the snapshot version from step A. Look for where the version is actually set. It's usually a property (something like `<dina-base-api.version>`), but it may be the `<version>` of the dina-base-api dependency or a `<parent>` block. Change only that version value. If it's already set to the snapshot version, leave the POM as is and carry on to step D.

### D. Build the consuming API like normal

Run the regular workflow (steps 1–5) for the consuming API: `mvn clean install -DskipTests`, `docker build`, update `docker-compose.local.yml`, restart its container, and verify it.

Always run `mvn clean install` on the consuming API, even when its POM didn't change. The API's jar bundles the dina-base-api code from the time it was last built. Without a fresh Maven build it keeps the old base-api code, and the new Docker image would be built from that stale jar.

To confirm the snapshot made it into the consuming API's jar, check after the Maven build:

```shell
unzip -l target/collection-api-*.jar | grep dina-base-api
```

The listed dina-base-api jar should carry the snapshot version. If it shows a release version, the POM change in step C didn't take effect; fix that before building the image.

### Testing base-api changes with several APIs

If the user wants to test the same base-api changes with more than one API, build and install dina-base-api once (step B). Then, for each consuming API, repeat step C and steps 1–5. Restart all of them in one `up -d` command if convenient.

### Iterating on dina-base-api changes

Once the versions are set up, further base-api changes don't need any POM edits. They do still need both Maven builds, every time. Re-run step B on dina-base-api, then steps 1, 2, 4, and 5 for each consuming API. Step 1 (`mvn clean install` on the consuming API) is what pulls the freshly installed snapshot into its jar, so don't skip it just because the POM is unchanged.

### Reverting

Reverting the local images only resets `docker-compose.local.yml`. The POM version changes in `dina-base-api` and the consuming API are left alone, since they're in the user's working copies. Mention them so the user doesn't commit them by accident. Only reset them if the user asks.

## Reverting to the Docker Hub images

When the user asks to revert the local images, first check which services currently point at local images and what else has changed in the file:

```shell
cd ~/dina-local-deployment
git diff docker-compose.local.yml
```

Then choose how to revert:

- **The only changes are the image swaps, and the user wants to revert everything:** reset the file in git.

  ```shell
  git checkout -- docker-compose.local.yml
  ```

- **The file already had uncommitted edits before the skill touched it (custom environment variables, ports, etc.), or the user wants to revert only some modules:** don't use `git checkout`, because it would throw away those edits. Instead, restore just the original `image:` lines by hand, using the original images you noted in step 3 (or the `-` lines in the diff).

- **You're not sure:** show the diff to the user and ask.

`git checkout` discards every uncommitted change in that file, not just the image lines. If the diff shows edits other than image swaps, mention that to the user before resetting.

Then restart the services that were reverted, the same way as step 4, so they go back to the Docker Hub images, and verify them as in step 5 (`docker inspect` should now print the Docker Hub image):

```shell
cd ~/dina-local-deployment
./start_stop_dina.sh up -d collection-api
```

Optionally, offer to remove the old local images with `docker rmi collection-api:dev`. Only do it if the user says yes.

## Troubleshooting

- **`docker build` can't connect to the Docker daemon:** Docker isn't running. Ask the user to start Docker Desktop (or the Docker service) and retry.
- **Maven fails with a compiler or toolchain error:** compare `java -version` with the Java version the project's `pom.xml` expects.
- **Compose tries to pull `collection-api:dev` from Docker Hub:** the local image doesn't exist under that exact tag. Check `docker images | grep collection-api`, make sure the build in step 2 succeeded, and make sure the tag in the compose file matches. Setting `pull_policy: never` on the service prevents accidental pulls, but that is an extra edit to the compose file, so mention it to the user before adding it.
- **Container still runs the old image after `up -d`:** Compose normally recreates a container when its image changes. If `docker inspect` still shows the old image, rerun with `--force-recreate`, for example `./start_stop_dina.sh up -d --force-recreate collection-api`.
- **Container still has old code after a rebuild with the same tag:** the container may not have been recreated. Use `--force-recreate` as above.
- **Port already in use on restart:** another process or container is holding the port. Report the conflict to the user rather than killing things yourself.
- **Container exits or restarts right after starting:** read `docker logs --tail 100 <container>` and report the error. A broken config or a failed dependency is more likely than a build problem.
- **Images are arm64 on Apple Silicon:** local builds target the host architecture. That's fine for local testing; just don't expect these images to run on amd64 machines.

## Summary to give the user

After finishing a build/deploy, briefly report: which module(s) were built, the image tag(s), which service(s) in `docker-compose.local.yml` now point at them (and what they pointed at before), which container(s) were restarted, and what the verification showed.

Example for a plain API build (the Docker Hub tag is illustrative):

```
Built: collection-api (image collection-api:dev)
Compose: collection-api now uses collection-api:dev (was aafcbicoe/collection-api:<version>)
Restarted: collection-api
Verified: container is Up and running collection-api:dev; logs show a normal startup
```

For a dina-base-api test, also report the snapshot version used and which POMs were changed:

```
Built: dina-base-api 0.204-SNAPSHOT (installed to ~/.m2), then collection-api (image collection-api:dev)
Compose: collection-api now uses collection-api:dev (was aafcbicoe/collection-api:<version>)
Restarted: collection-api
Verified: container is Up and running collection-api:dev; consuming jar contains dina-base-api 0.204-SNAPSHOT
POMs changed: dina-base-api/pom.xml (0.203 -> 0.204-SNAPSHOT), collection-api/pom.xml (dina-base-api version)
Reminder: these POM edits are uncommitted in your working copies, so don't commit them by accident.
```
