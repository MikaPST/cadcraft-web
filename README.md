<p align="center">
  <img src="https://raw.githubusercontent.com/storytold/cadcraft/main/assets/app-icon/hicolor/256x256/apps/ai.storyteller.cadcraft.png" width="128" height="128" alt="CADCraft application icon">
</p>

<h1 align="center">CADCraft Web — Docker Image</h1>
<p align="center">
  A community-maintained Docker image for
  <a href="https://github.com/storytold/cadcraft">CADCraft</a>,
  providing its browser-based CAD drafting and technical drawing interface through a self-hosted web application.
  <br>
  Build automation and image publication to GitHub Container Registry (GHCR).
</p>

<p align="center">
  <a href="https://github.com/MikaPST/cadcraft-web/actions/workflows/publish-image.yml">
    <img src="https://github.com/MikaPST/cadcraft-web/actions/workflows/publish-image.yml/badge.svg" alt="Build and publish CADCraft Web">
  </a>
  <a href="https://github.com/MikaPST/cadcraft-web/releases/latest">
    <img src="https://img.shields.io/github/v/release/MikaPST/cadcraft-web?label=Release&logo=github&color=blue" alt="Latest Release">
  </a>
  <a href="https://github.com/MikaPST/cadcraft-web/pkgs/container/cadcraft-web">
    <img src="https://ghcr-badge.egpl.dev/mikapst/cadcraft-web/latest_tag?trim=major&label=GHCR" alt="GHCR image tag">
  </a>
  <a href="docker-compose.yml">
    <img src="https://img.shields.io/badge/Docker%20Compose-ready-2496ED?logo=docker&logoColor=white" alt="Docker Compose configuration">
  </a>
</p>

---

## Why this repository?

The official CADCraft project includes a WebAssembly version that can be hosted as a static website. This repository packages it into a Docker image for straightforward self-hosting.

The goals are to:

- Build CADCraft Web from the **official upstream release source**, not an unrelated branch head.
- Publish ready-to-run Docker images to GHCR for `linux/amd64` and `linux/arm64`.
- Detect newly published official versions automatically and publish matching, versioned images.
- Create a matching GitHub Release with the official release notes **after** successful image publication.
- Provide a deployment option for Unraid Community Applications.
- Include a ready-to-use Docker Compose file.
- Maintain Docker, NGINX and build automation independently of the upstream application.
- Keep all packaging files version-controlled rather than generating Docker and NGINX configurations inside a workflow.

This is a packaging and distribution project, not a fork intended to develop a separate CAD application.

## How it works

CADCraft is an open-source CAD drafting and design application written in Rust. Its web version runs in the browser through WebAssembly and uses WebGPU with a WebGL2 fallback, depending on browser support.

- **Browser-based CAD:** create and edit technical drawings using the web application.
- **CAD tools:** geometry, layers, dimensions, hatches, blocks, snapping, constraints and drawing layouts as supported by the selected upstream release.
- **File operations:** browser-side opening, saving and exporting of supported CAD formats, including DXF; support varies by release.
- **No server-side CAD engine:** NGINX serves static files, without a desktop session, VNC, document database or server-side drawing storage.
- **Self-hosted:** run CADCraft on Unraid or another Docker host, with HTTPS behind a reverse proxy when externally accessed.

The upstream web application supports same-origin embedding with its host integration bridge (`?host=parent`). Browser-side panel layout preferences are saved in local storage and are **not** a replacement for drawings or backups. The upstream project is actively developed, so some desktop workflows and feature availability may differ from the browser build.

WebAssembly builds have no operating-system font fallback. CADCraft embeds a limited selection of font faces from the pinned official `craft-fonts` revision, including faces needed by the upstream web application. No graphics GPU is passed to the container; rendering uses the visitor's browser and hardware.

## Docker image

The image is published to GitHub Container Registry:

```text
ghcr.io/mikapst/cadcraft-web:latest
```

Each packaged official release is also published under its exact upstream version tag, for example:

```text
ghcr.io/mikapst/cadcraft-web:v0.21.0
```

### Option 1 — Docker Compose (recommended)

A `docker-compose.yml` file is included at the repository root:

```yaml
services:
  cadcraft-web:
    image: ghcr.io/mikapst/cadcraft-web:latest
    container_name: cadcraft-web
    ports:
      - "8080:8080"
    restart: unless-stopped
```

Start CADCraft Web from the repository root:

```bash
docker compose up -d
```

Open the interface:

```text
http://YOUR_SERVER_IP:8080
```

Replace `YOUR_SERVER_IP` with your server's address. On the Docker host itself, `http://localhost:8080` is also suitable.

#### Useful Compose commands

```bash
# Inspect logs
docker compose logs -f

# Pull updates and recreate the container
docker compose pull
docker compose up -d

# Stop and remove the container
docker compose down
```

This basic setup requires no `.env` file, database or persistent Docker volume. To select another host port, change the left side of the mapping, for example `8090:8080`.

### Option 2 — Run directly with Docker

```bash
docker pull ghcr.io/mikapst/cadcraft-web:latest

docker run -d \
  --name cadcraft-web \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/mikapst/cadcraft-web:latest
```

Open the application at `http://YOUR_SERVER_IP:8080`.

### Network access and reverse proxies

The container listens on port `8080` over HTTP. For public access, terminate HTTPS using a reverse proxy such as Traefik or NGINX Proxy Manager and restrict access as appropriate.

CADCraft uses WebGPU when available, which generally requires **HTTPS or localhost**. WebGL2 is the browser fallback. The upstream web hosting guide does not require special SharedArrayBuffer isolation headers.

NGINX serves `.wasm` with `application/wasm`, compresses static assets, revalidates `index.html` and caches content-hashed JavaScript and WebAssembly assets. If you embed CADCraft in an iframe, do not add `X-Frame-Options: DENY` or a `frame-ancestors` policy that forbids your embedding origin. The upstream host bridge (`?host=parent`) is restricted to the same origin.

## Repository structure

This repository maintains its own Docker packaging while retrieving the official CADCraft release source during the build.

```text
cadcraft-web/
├── .github/
│   └── workflows/
│       └── publish-image.yml
├── .dockerignore
├── Dockerfile
├── nginx.conf
├── docker-compose.yml
└── README.md
```

| File | Purpose |
|---|---|
| `Dockerfile` | Builds the NGINX runtime image from prepared static files, includes upstream notices and provides a health check. |
| `nginx.conf` | Configures WebAssembly MIME handling, caching, gzip, security headers and `/healthz`. |
| `.dockerignore` | Keeps the Docker build context limited to the generated site and required legal notices. |
| `docker-compose.yml` | Defines the standard Docker Compose deployment. |
| `.github/workflows/publish-image.yml` | Detects releases, builds the WebAssembly site, publishes multi-platform GHCR images and creates GitHub Releases. |
| `README.md` | Documents the application, deployment, packaging and attribution. |

### Docker build architecture

The image uses **official CADCraft release source code** and separate Docker packaging maintained in this repository. The official browser build is based on **Rust, WebAssembly and Trunk**.

The build process follows these steps:

1. GitHub Actions identifies the latest official CADCraft release or the requested published upstream tag.
2. The workflow checks out that exact release under `upstream/`.
3. It reads the `craft-fonts-ref` pinned in the selected release's `.github/workflows/release.yml` and checks out the matching `storytold/craft-fonts` revision, never a floating `main` branch.
4. It installs Rust `1.96.1`, the `wasm32-unknown-unknown` compilation target and Trunk.
5. It runs `trunk build --release` from `upstream/apps/cadcraft-web`; the official `Trunk.toml` writes to `upstream/dist/web/` and uses relative URLs.
6. The workflow validates `index.html`, generated `.js` and `.wasm` assets, and the absence of root-absolute asset paths.
7. It copies the generated site, the version-controlled `Dockerfile`, `nginx.conf`, `.dockerignore`, and upstream and font licenses to a temporary image context.
8. Docker Buildx publishes the static NGINX runtime image to GHCR for `linux/amd64` and `linux/arm64`.
9. Only after the image push completes does the workflow create or update the matching GitHub Release.

The browser application is compiled once and packaged as architecture-independent assets into two container runtime architectures. NGINX runs as a **non-root user** on port `8080`, serves WebAssembly with the proper MIME type and provides a `/healthz` Docker health check. No persistent volume or server-side CAD engine is required.

The pinned font input is mandatory in this packaging workflow (`CRAFT_FONTS_REQUIRED=1`), preventing silent loss of browser text fallback when an upstream dependency changes. Unlike WordCraft, no separate `craft-i18n` checkout is required by the inspected CADCraft build setup.

> [!NOTE]
> Future upstream releases may change Rust or font requirements, build outputs or asset paths. The GitHub Actions compilation remains the authoritative integration test.

## Automated builds

GitHub Actions monitors the official CADCraft releases, and packaging changes on this repository trigger rebuilding the latest upstream version.

| Trigger | Behaviour |
|---|---|
| Daily schedule | Checks the latest published official CADCraft release and builds it if it is not published here |
| Manual workflow dispatch | Builds the latest official release, or a selected `upstream_tag` |
| Force rebuild | Rebuilds an already published version and updates its matching GitHub Release |
| Packaging changes on `main` | Rebuilds the latest upstream release when the README, workflow, Dockerfile, NGINX, `.dockerignore` or Compose configuration changes |

### Published tags

Every successful build publishes these image tags:

- `latest` — the most recently packaged official release (mutable).
- `<upstream-version>` — the exact upstream tag, such as `v0.21.0`.
- `upstream-<commit>` — the first 12 characters of the upstream source commit.

The image is built for `linux/amd64` and `linux/arm64`. Its contents are derived from the official upstream tag and the independent packaging files in this repository.

### GitHub Releases

After Docker Buildx successfully publishes the multi-platform image to GHCR, the workflow creates or updates a [GitHub Release](https://github.com/MikaPST/cadcraft-web/releases) using the corresponding upstream tag.

Each published release contains:

- A link to the official upstream release and its notes.
- The exact upstream release tag and source commit.
- The `craft-fonts` commit used during the build.
- The published Docker tags (`latest`, the upstream version and `upstream-<commit>`).
- Supported architectures: `linux/amd64` and `linux/arm64`.
- The Docker manifest digest, when available.
- A notice that this is community-maintained packaging, not an official ArtCraft distribution.

The Release badge at the top reflects the latest version published **in this repository**.

Scheduled and ordinary manual checks skip versions already released here. To rebuild, open **Actions → Build and publish CADCraft Web → Run workflow** and enable `force_rebuild`. Packaging changes on `main` rebuild the latest upstream version automatically.

> [!IMPORTANT]
> A GitHub Release is created or updated **only after** a successful GHCR push. The `latest` tag is mutable, and forcing a rebuild may also replace versioned tags. Pin a digest if exact reproducibility is required.

CADCraft is actively developed. Test a new image before depending on it for important drawings.

## Unraid Community Applications

CADCraft Web is available through the maintainer's separate Unraid Community Applications template repository:

- **Unraid Community Applications repository:** [MikaPST/unraid-community-apps](https://github.com/MikaPST/unraid-community-apps)
- **CADCraft Web template:** [cadcraft-web.xml](https://github.com/MikaPST/unraid-community-apps/blob/main/templates/cadcraft-web.xml)
- **Container port:** `8080` (the current Unraid template defaults to host port `8090`)

The template references `ghcr.io/mikapst/cadcraft-web:latest` and is maintained separately from this packaging project.

## Upstream project

CADCraft is an open-source CAD design and technical drafting application developed by the ArtCraft team and contributors.

- **Source code:** [storytold/cadcraft](https://github.com/storytold/cadcraft)
- **Official website:** [getartcraft.com/apps/cadcraft](https://getartcraft.com/apps/cadcraft)
- **Official web hosting guide:** [Hosting CADCraft for the web](https://github.com/storytold/cadcraft/blob/main/packaging/web/README.md)
- **Official releases:** [CADCraft releases](https://github.com/storytold/cadcraft/releases)

The MikaPST GitHub Releases reflect independently maintained Docker packaging, not official upstream distributions.

## License and attribution

CADCraft is dual-licensed under **MIT or Apache-2.0**, at the user's option. Copyright remains with the upstream authors and contributors.

The upstream project includes licenses, notices and third-party asset attribution. The Docker image copies available `LICENSE-MIT`, `LICENSE-APACHE`, `NOTICE`, and `ATTRIBUTION.md` files, plus the `OFL.txt` font licenses found in the pinned `craft-fonts` checkout, into `/usr/share/licenses/cadcraft/`.

- [MIT License](https://github.com/storytold/cadcraft/blob/main/LICENSE-MIT)
- [Apache 2.0 License](https://github.com/storytold/cadcraft/blob/main/LICENSE-APACHE)
- [NOTICE](https://github.com/storytold/cadcraft/blob/main/NOTICE)
- [Asset attribution](https://github.com/storytold/cadcraft/blob/main/ATTRIBUTION.md)

The upstream application's licenses do not automatically set the license for this repository's independently maintained packaging configuration. Refer to a repository `LICENSE` file if one is published.

The CADCraft and ArtCraft names, branding and logos retain their own trademark and usage terms. This repository is independently maintained and **is not affiliated with or endorsed by** the original project maintainers.

## Disclaimer

CADCraft is actively developed and its behaviour, file compatibility and supported features may change between releases. Use the application and keep independent backups of important drawing files.
