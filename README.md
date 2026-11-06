<p align="center">
  <img src="https://raw.githubusercontent.com/storytold/cadcraft/main/assets/app-icon/hicolor/256x256/apps/ai.storyteller.cadcraft.png" width="128" height="128" alt="CADCraft application icon">
</p>

<h1 align="center">CADCraft Web — Docker Image</h1>
<p align="center">
  A community-maintained Docker image for
  <a href="https://github.com/storytold/cadcraft">CADCraft</a>,
  providing its browser-based 2D and 3D CAD drafting application through a self-hosted web interface.
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

The official CADCraft project provides a WebAssembly-based version that can be hosted as a static website. This repository packages the web application into a Docker image to simplify self-hosting.

The goals are to:

- Publish a matching GitHub Release only after the Docker build and push succeed.
- Build the CADCraft Web application from the upstream source code.
- Publish a ready-to-run Docker image to GHCR.
- Automatically rebuild the image every week to incorporate upstream changes.
- Provide a convenient deployment option for Unraid Community Applications.
- Offer a simple Docker Compose configuration for users who prefer managing containers with Compose.
- Keep the packaging and deployment configuration separate from the upstream CADCraft project.

This is a packaging and distribution project, not a fork intended to develop a separate CAD application.

## How it works

CADCraft Web runs directly in the user's browser using WebAssembly. The Docker container serves the static web application through NGINX; it does not provide a remote Linux desktop or a server-side CAD engine.

- **Browser-based CAD interface:** create and edit technical drawings in a modern web browser.
- **WebAssembly application:** the Rust application is compiled to WebAssembly and runs client-side.
- **Drawing tools:** work with geometry, layers, dimensions, hatches, blocks, constraints and layouts supported by the current web build.
- **Drawing files:** the application works with CAD drawing formats including DXF; supported file operations are handled by the browser application.
- **Web graphics:** the browser build requires WebGPU or WebGL2.
- **Self-hosted:** serve the static application from your own server and access it over your local network or through a properly configured reverse proxy.

The container serves only the application files. Drawing, editing and rendering take place in the browser; the container does not store drawings or run CAD processing on the server.

### Important limitations

CADCraft is in active development and its feature parity is still evolving. Some desktop capabilities and workflows may differ in the WebAssembly build. Consult the upstream roadmap and gaps documentation before relying on a particular feature or file-format workflow.

The upstream project notes that the web build has no system fonts. It can embed a limited set of fonts when built with the optional `craft-fonts` input; the web build includes BIZ UDPGothic Regular and Noto Sans Arabic. Other fonts and some text fallback behaviour depend on the browser and embedded font set.

## Docker image

The image is published to GitHub Container Registry:

```text
ghcr.io/mikapst/cadcraft-web:latest
```

Each official upstream release is also published under its exact version tag, for example:

```text
ghcr.io/mikapst/cadcraft-web:vX.Y.Z
```

Use a versioned tag if you want to keep a deployment on a specific release. The `latest` tag updates when an image is published.

### Option 1 — Docker Compose (recommended)

A `docker-compose.yml` file is provided at the root of this repository. It is the simplest way to start and maintain CADCraft Web with Docker Compose.

```yaml
services:
  cadcraft-web:
    image: ghcr.io/mikapst/cadcraft-web:latest
    container_name: cadcraft-web
    ports:
      - "8080:8080"
    restart: unless-stopped
```

From the repository root, start the application with:

```bash
docker compose up -d
```

Open the application in your browser:

```text
http://YOUR_SERVER_IP:8080
```

Replace `YOUR_SERVER_IP` with the IP address or hostname of your server. If Docker is running on your own computer, you can use `http://localhost:8080`.

#### Useful Compose commands

```bash
# View container logs
docker compose logs -f

# Pull the latest image and recreate the container
docker compose pull
docker compose up -d

# Stop and remove the container
docker compose down
```

No `.env` file or persistent volume is required for this basic setup. The host port is configured in `docker-compose.yml`; by default, port `8080` on the host is mapped to port `8080` in the container. To use a different host port, change the left-hand side of the mapping. For example, `8081:8080` exposes the application on host port `8081`.

The container serves only static files and does not provide persistent drawing storage or a server-side CAD backend.

### Option 2 — Run directly with Docker

If you prefer not to use Docker Compose, you can run the container directly:

```bash
docker pull ghcr.io/mikapst/cadcraft-web:latest

docker run -d \
  --name cadcraft-web \
  --restart unless-stopped \
  -p 8080:8080 \
  ghcr.io/mikapst/cadcraft-web:latest
```

Open the application at:

```text
http://YOUR_SERVER_IP:8080
```

Drawing operations and rendering run in the browser. Performance therefore depends on the client device, browser and available graphics support, not only on the Docker host.

### Network access and reverse proxies

The container listens for HTTP traffic on port `8080`. For external access, use a reverse proxy such as Traefik to terminate HTTPS and forward requests to the container over HTTP.

HTTPS is required for WebGPU outside `localhost`. Over plain HTTP on other hosts, CADCraft falls back to WebGL2. The upstream documentation also notes that clipboard access requires a secure context.

Do not expose an unencrypted HTTP port directly to the public Internet. Restrict access to your intended network or protect external access with HTTPS and appropriate access controls.

## Automated builds

GitHub Actions checks the official [CADCraft releases](https://github.com/storytold/cadcraft/releases), builds the WebAssembly application from the selected upstream tag and publishes the image to GHCR.

| Trigger | Behaviour |
|---|---|
| Weekly schedule | Checks the latest official CADCraft release and builds it if it has not already been published here |
| Manual workflow dispatch | Builds the latest official release, or a specified `upstream_tag` |
| Force rebuild | Rebuilds an already published version with `force_rebuild: true` |
| Changes to packaging files on `main` | Rebuilds the current official upstream release with the updated workflow |

### Published tags

- `latest` — the latest successfully published image (mutable tag).
- `<upstream-version>` — the exact official upstream tag, for example `vX.Y.Z`.
- `upstream-<commit>` — the upstream source commit used for the image (first 12 hexadecimal characters).

The image targets both `linux/amd64` and `linux/arm64`. The workflow checks out **the official upstream release tag**, rather than compiling `main` as the versioned source.

### GitHub Releases

After a successful Docker build and GHCR push, the workflow creates or updates a [GitHub Release](https://github.com/MikaPST/cadcraft-web/releases) matching the upstream tag. It includes the upstream release notes, source link and commit, Docker tags, supported architectures and (when available) the published image digest.

The Release badge at the top of this README updates automatically. Scheduled runs skip versions already released here. You can force a rebuild from **Actions → Build and publish CADCraft Web → Run workflow**.

> [!IMPORTANT]
> A GitHub Release is created only after the Docker image has been successfully published. The `latest` tag may change after a rebuild; pin a versioned image tag for a stable deployment. Auxiliary source repositories (for example `craft-fonts`) may be checked out separately and are not necessarily pinned to the upstream release commit.

## Unraid Community Applications

This image is intended to be distributed through the maintainer's existing Unraid Community Applications repository.

The Unraid template references the published GHCR image and provides configuration for the web port.

- **Unraid Community Applications repository:** [MikaPST/unraid-community-apps](https://github.com/MikaPST/unraid-community-apps)
- **CADCraft Web template:** to be added when the template is published.

This repository contains the image build, publication workflow and Docker Compose configuration. The Unraid Community Applications template is maintained separately.
- **Template:** [cadcraft-web.xml](https://github.com/MikaPST/unraid-community-apps/blob/main/templates/cadcraft-web.xml)

## Upstream project

CADCraft is an open-source, modern 2D and 3D computer-aided design and drafting application written in pure Rust by the ArtCraft Team and its contributors. It provides a CAD workflow with a command line, object snaps, layers, dimensions, hatches, blocks, constraints, layouts and DXF drawings.

- **Source code:** [storytold/cadcraft](https://github.com/storytold/cadcraft)
- **Official website:** [cadcraft.org](https://cadcraft.org/)
- **Official web build:** `apps/cadcraft-web` in the upstream repository
- **Official releases:** [CADCraft releases](https://github.com/storytold/cadcraft/releases)
- **Roadmap:** [ROADMAP.md](https://github.com/storytold/cadcraft/blob/main/ROADMAP.md)
- **Known gaps:** [docs/gaps.md](https://github.com/storytold/cadcraft/blob/main/docs/gaps.md)

The upstream web application is built with Trunk from `apps/cadcraft-web`. This repository builds that browser application from upstream source and packages the generated static files in an NGINX image. It does not modify the CADCraft application itself.

The MikaPST GitHub Release tracks the upstream version but represents independent Docker packaging, not an official CADCraft distribution.

## License and attribution

CADCraft is dual-licensed under the **MIT License or Apache License 2.0**, at the user's option. Copyright belongs to the ArtCraft Team and CADCraft contributors.

The upstream repository includes `NOTICE`, `ATTRIBUTION.md` and the applicable license files. These notices and license files must be preserved when redistributing the application and its bundled assets.

The Docker packaging files in this repository are maintained separately from the upstream application. This repository does not claim ownership of CADCraft or its bundled assets.

## Disclaimer

This is an independent community packaging project and is not affiliated with, endorsed by, or sponsored by the ArtCraft Team.

CADCraft is provided by its upstream authors under its own license and development status. Use this Docker image at your own risk and consult the official repository for the latest information, limitations and notices.
