# CI/CD Integration for Appliance Mode Builds

## GitHub Actions Workflow

```yaml
name: Build Edge Artifacts

on:
  push:
    branches: [main]
    paths:
      - 'edge-config/**'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Earthly
        run: |
          curl -fsSL https://releases.earthly.dev/earthly-linux-amd64 -o earthly
          sudo mv earthly /usr/local/bin/ && sudo chmod +x /usr/local/bin/earthly
          earthly bootstrap

      - name: Clone CanvOS
        run: |
          git clone https://github.com/spectrocloud/CanvOS.git
          cd CanvOS
          LATEST_TAG=$(git describe --tags --abbrev=0)
          echo "Using CanvOS $LATEST_TAG"
          git checkout "$LATEST_TAG"

      - name: Copy Configuration
        run: |
          cp edge-config/.arg CanvOS/
          cp edge-config/user-data CanvOS/

      - name: Login to Registry
        run: echo "${{ secrets.REGISTRY_PASSWORD }}" | docker login -u ${{ secrets.REGISTRY_USER }} --password-stdin

      - name: Build Provider Images
        working-directory: CanvOS
        run: earthly +build-provider-images

      - name: Build ISO
        working-directory: CanvOS
        run: earthly +iso

      - name: Upload ISO Artifact
        uses: actions/upload-artifact@v4
        with:
          name: edge-installer-iso
          path: CanvOS/build/*.iso
```

## Recommended Repository Structure

Keep configuration separate from CanvOS:

```
edge-build-config/
├── .arg                    # Build parameters
├── user-data               # Installer configuration
├── k8s-versions.json       # Optional: filtered K8s versions
└── .github/
    └── workflows/
        └── build.yml       # CI/CD workflow
```

Clone CanvOS fresh each build, copy config files in.

## GitLab CI Example

```yaml
stages:
  - build

build-edge:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - apk add --no-cache curl git
    - curl -fsSL https://releases.earthly.dev/earthly-linux-amd64 -o /usr/local/bin/earthly
    - chmod +x /usr/local/bin/earthly
    - earthly bootstrap
  script:
    - git clone https://github.com/spectrocloud/CanvOS.git
    - cd CanvOS && LATEST_TAG=$(git describe --tags --abbrev=0) && echo "Using CanvOS $LATEST_TAG" && git checkout "$LATEST_TAG" && cd ..
    - cp .arg user-data CanvOS/
    - cd CanvOS
    - docker login -u $REGISTRY_USER -p $REGISTRY_PASSWORD
    - earthly +build-provider-images
    - earthly +iso
  artifacts:
    paths:
      - CanvOS/build/*.iso
```
