# Moving the site to the `lsherbini` account

> Historical guide. On September 15 the owner reversed this move and asked to
> return all code and deployment links to `Asherbinyy/asherbinyy.github.io`.
> Do not follow the migration steps below for the current setup. A future
> custom domain can be attached to the original repository.

Written for the owner. Everything here is reversible until the last step.

## What is actually being moved

One repository. `nocturne` and `nocturne-admin` are two checkouts of the
**same** repo (`Asherbinyy/asherbinyy.github.io`) on different branches, so
moving it moves both. 216 commits, 37 branches, 4 tags, 161MB of history.

Two things live outside GitHub and do **not** move with it:

- **The Cloudflare Worker** (`nocturne-analytics.asherbinyy.workers.dev`). It
  keeps running untouched — but see step 5, because it will start refusing the
  new site.
- **The domain.** There is no custom domain; the site is served at
  `asherbinyy.github.io` purely because the repo is named that, under that
  account.

## The one decision to make first

**Copy** (recommended) or **transfer**.

| | Copy | Transfer |
|---|---|---|
| History, branches, tags | all preserved | all preserved |
| Issues, stars, releases | not carried | carried |
| Old repo | stays exactly as it is | leaves the old account |
| Old site keeps serving | yes, until you turn it off | no |
| Reversible | completely | needs a transfer back |

Copy is recommended because the live site keeps working the entire time and
nothing is at risk while the new one is proved. This repo has no issues or
stars to lose.

## What you do

**1. Create the repository.** On the `lsherbini` account, a new repository
named **exactly `lsherbini.github.io`** — lowercase, matching the username.
Public. **Do not** tick "add a README", a licence or a `.gitignore`: it has to
be empty or the first push is refused.

The name matters more than it looks. A repo named anything else is a *project*
site served from `lsherbini.github.io/<repo-name>/`, which forces
`--base-href` to change, bakes the repo name into every asset path, and makes
a later move to a custom domain a rebuild rather than a DNS change.

**2. Give this machine push access to it.** The catch: **an SSH key can only be
attached to one GitHub account**, and the key here already belongs to
`Asherbinyy`. Two ways round it, pick one:

- *Simplest.* `gh auth login` as `lsherbini`, choosing **HTTPS**. The new
  remote then authenticates over HTTPS with a token and the old SSH remote is
  untouched.
- *Tidier if you will work with both accounts long-term.* Generate a second key
  (`ssh-keygen -t ed25519 -C lsherbini`), add it to the new account, and give
  it a host alias in `~/.ssh/config`.

**3. Tell me to push.** I do the rest of the mechanical work — see below.

**4. Turn on Pages in the new repo.** Settings → Pages → Source:
**GitHub Actions**. Not "Deploy from a branch": this repo builds the site in
the workflow and uploads it as an artifact.

**5. Point the Worker at the new origin.** In the Cloudflare dashboard, the
analytics Worker's `SITE_ORIGIN` variable, currently
`https://asherbinyy.github.io`. It is used for the CORS check and the
content-security policy, so until it is changed the new site's analytics beacon
and the admin panel's preview will both be refused. Change it and redeploy the
Worker.

**6. Decide what happens to the old one.** While both exist, two identical
sites are live and search engines may index both. When you are satisfied the
new one works, either make the old repo private (its Pages site stops serving)
or leave a one-page redirect in it — say the word and I will write that page.

**7. Update the link where you have published it.** GitHub does not redirect a
user site to another account. `asherbinyy.github.io` is in your CV, your
Linktree, LinkedIn and Medium; those are yours to change.

## What I do

- Add the new remote alongside `origin`, leaving `origin` exactly as it is, and
  push every branch and tag. Nothing is deleted anywhere.
- Change every hard-coded reference to the old account:
  - `tool/generate_static.dart` — `baseUrl`, which is what the canonical links,
    the sitemap and the static CV/Brief pages are built from.
  - `web/index.html` — the canonical link, `og:url`, the icon URLs, and the
    `sameAs` GitHub profile in the structured data.
  - `test/unit/tool/generate_static_test.dart` — which asserts those URLs, so
    it fails if one is missed.
  - `README.md`, `CHANGELOG.md`, `START-HERE.md`, `docs/08-GIT-AND-CI.md`.
- Re-run the four checks and the generators, then watch the first CI run on the
  new repo and confirm the site serves.
- Write the redirect page for the old repo, if you want one.

## What I cannot do

Create the repository, authenticate as the new account, enable Pages, or touch
Cloudflare. All four need your credentials.

## Worth knowing

- **Visitor-side state resets.** The theme choice, the analytics consent and
  the game's best score are stored per origin. Everybody starts fresh on the
  new domain. Nothing is lost that matters; it is just not carried across.
- **The Worker's own name** still says `asherbinyy`. Renaming it is a separate
  job with its own redeploy and another `SITE_ORIGIN`-style edit, and it is not
  required for anything to work.
- **`pubspec.lock` is not committed on purpose**, so CI resolves dependencies
  fresh on the new repo exactly as it does here. The `dependency_overrides`
  block in `pubspec.yaml` is what keeps that reproducible; do not drop it
  without reading its comment.
