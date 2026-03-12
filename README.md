# decK Quickstart: OpenAPI -> Konnect

This example repository shows a minimal command-line workflow for a Konnect customer who starts with only an OpenAPI specification.

The workflow does all of the following:

1. Converts OpenAPI to a Kong decK state file.
2. Merges plugin overlays from a `plugins/` folder.
3. Applies `_info.select_tags` from an environment variable via `_info.yaml`.
4. Syncs to a Konnect control plane selected by environment variable.

## Prerequisites

- `deck` installed and available on `PATH`
- Access to a Konnect control plane
- A Konnect token with permissions to run `deck gateway diff/sync`

No `make` command is required for this repository.

## Repository Layout

- `openapi/spec.yaml`: sample OpenAPI input (replace with your own spec)
- `plugins/rate-limiting.yaml`: example rate-limiting plugin overlay
- `plugins/oidc.yaml`: example OpenID Connect plugin overlay
- `config/_info.yaml.tmpl`: source template for `_info.select_tags`
- `scripts/render-info.sh`: renders `build/_info.yaml` using `DECK_SELECT_TAG`
- `scripts/build-state.sh`: build pipeline to produce `build/kong.yaml`
- `scripts/sync-konnect.sh`: diff + sync to Konnect

## Configure Environment

Copy `.env.example` values into your shell (or a `.envrc`/CI secret store):

```bash
export DECK_SELECT_TAG=customer-team-a
export DECK_KONNECT_CONTROL_PLANE_NAME=example-control-plane
export DECK_KONNECT_TOKEN=replace-with-konnect-token
export DECK_KONNECT_ADDR=https://us.api.konghq.com
```

### Set Up The Konnect Access Token

`decK` uses `DECK_KONNECT_TOKEN` to authenticate to Konnect.

1. In Konnect, create a Personal Access Token (PAT) with permission to read/write gateway configuration for the target control plane.
2. Copy the token value when it is created.
3. Export it in your shell:

```bash
export DECK_KONNECT_TOKEN='paste-token-value-here'
```

Optional: prompt for the token without echoing it in your terminal history.

```bash
read -s "DECK_KONNECT_TOKEN?Konnect token: "
export DECK_KONNECT_TOKEN
```

Quick check:

```bash
[[ -n "$DECK_KONNECT_TOKEN" ]] && echo "DECK_KONNECT_TOKEN is set"
```

### Why `DECK_SELECT_TAG` Matters

`DECK_SELECT_TAG` is the safety boundary for this workflow.

It is used in two places:

1. `build/_info.yaml` sets `_info.select_tags` from `DECK_SELECT_TAG`.
2. `deck gateway diff/sync` uses that `_info.select_tags` value to scope operations.

When `deck gateway diff` and `deck gateway sync` run against `build/kong.yaml`, decK uses `_info.select_tags` to limit management to entities that match that tag.

This means:

- decK only compares and updates resources in the tagged scope.
- Resources outside that tag scope are ignored by this state file.
- You can safely split ownership across teams/control planes by giving each pipeline a different tag.

In short, `DECK_SELECT_TAG` keeps this pipeline focused on one bounded slice of configuration instead of the entire control plane.

## Command Line Operations

### 1) Convert OpenAPI to Kong config

```bash
deck file openapi2kong \
  --spec openapi/spec.yaml \
  --output-file build/01-openapi.yaml
```

### 2) Merge plugin overlays from folder

```bash
deck file add-plugins \
  --state build/01-openapi.yaml \
  --output-file build/02-with-plugins.yaml \
  plugins/rate-limiting.yaml \
  plugins/oidc.yaml
```

### 3) Render `_info.yaml` using environment-driven select tag

```bash
./scripts/render-info.sh
```

This produces `build/_info.yaml`:

```yaml
_format_version: "3.0"
_info:
  select_tags:
    - ${DECK_SELECT_TAG}
```

### 4) Merge into final state file

```bash
deck file merge \
  --output-file build/kong.yaml \
  build/02-with-plugins.yaml \
  build/_info.yaml
```

### 5) Review and apply changes to Konnect control plane

The control plane is selected through `DECK_KONNECT_CONTROL_PLANE_NAME`.

```bash
deck gateway diff build/kong.yaml
deck gateway sync build/kong.yaml
```

## One-Command Workflow

Run the full build and sync sequence:

```bash
./scripts/sync-konnect.sh
```

Or build only:

```bash
./scripts/build-state.sh
```

## Notes

- `DECK_SELECT_TAG` drives both generated entity tags and `_info.select_tags` scope control.
- `deck gateway sync` is destructive for out-of-state resources in the selected scope; always run `diff` first.
- Replace the sample OpenID Connect values in `plugins/oidc.yaml` with your IdP details.
