---
name: spectrocloud-appliance-mode
description: Build and deploy Spectro Cloud Palette Edge clusters using Appliance Mode. Covers CanvOS builds, provider images, ISOs, content bundles, 2-node deployments, and CI/CD integration patterns.
---

# Spectro Cloud Appliance Mode

Appliance Mode creates immutable edge deployments using Kairos-based images built with CanvOS. Unlike Agent Mode (install agent on existing OS), Appliance Mode builds the complete OS + Kubernetes stack as container images.

## When to Use Appliance Mode

| Use Case | Mode |
|----------|------|
| Immutable, locked-down edge | Appliance |
| 2-node HA clusters | Appliance (only option) |
| Existing OS/golden images | Agent |
| Quick testing on VMs | Agent |

## Key Concepts

- **CanvOS**: Earthly-based build system that creates edge artifacts
- **Provider Image**: Container image with OS + specific K8s version
- **Installer ISO**: Bootable image containing Palette agent + user-data
- **Content Bundle**: Pre-cached images for offline/low-bandwidth deployments

## Prerequisites

### Build Machine Requirements
- Linux with AMD64 architecture
- 4+ CPUs, 8GB+ RAM, 150GB+ storage
- Git, Docker
- Earthly (recommended over earthly.sh wrapper)

### Install Earthly
```bash
curl -fsSL https://releases.earthly.dev/earthly-linux-amd64 -o earthly
sudo mv earthly /usr/local/bin/
sudo chmod +x /usr/local/bin/earthly
earthly bootstrap
```

## Build Process Overview

**Before building, ask the user:**
1. Where will provider images be pushed? (ttl.sh for <24hr testing, or specify registry)
2. What K8s version? (default: n-1 minor version with kubeadm)
3. Is this for 2-node deployment? (requires different OS/config)
4. Do you need content bundles for offline deployment?

## Standard Build (1-node or 3+ nodes)

### Step 1: Clone CanvOS
```bash
git clone https://github.com/spectrocloud/CanvOS.git
cd CanvOS
```

### Step 2: Create .arg Configuration

```bash
cat << 'EOF' > .arg
# OS Configuration
OS_DISTRIBUTION=ubuntu
OS_VERSION=22

# Kubernetes Configuration
K8S_DISTRIBUTION=kubeadm
K8S_VERSION=1.30.4

# Registry Configuration (ask user)
IMAGE_REGISTRY=ttl.sh
IMAGE_REPO=my-edge-images
CUSTOM_TAG=demo

# Architecture
ARCH=amd64

# Security (defaults)
FIPS_ENABLED=false
CIS_HARDENING=false
IS_UKI=false
TWO_NODE=false
EOF
```

**Registry options:**
- `ttl.sh` - Free ephemeral registry, images expire in 24 hours
- `gcr.io/your-project` - Google Container Registry
- `your-registry.io` - Private registry (requires docker login first)

### Step 3: Create user-data

```bash
cat << 'EOF' > user-data
#cloud-config
install:
  reboot: true

stylus:
  site:
    paletteEndpoint: api.spectrocloud.com
    edgeHostToken: <registration-token>
    projectName: <project-name>
EOF
```

**Advanced user-data options:**
```yaml
#cloud-config
install:
  reboot: true
  device: /dev/sda              # Explicit install device

stylus:
  site:
    paletteEndpoint: api.spectrocloud.com
    edgeHostToken: <token>
    projectName: <project>
    name: custom-hostname        # Custom edge host name
    network:
      httpProxy: http://proxy:8080
      httpsProxy: http://proxy:8080
      noProxy: localhost,127.0.0.1
    caCerts:
      - |
        -----BEGIN CERTIFICATE-----
        <CA cert content>
        -----END CERTIFICATE-----
```

### Step 4: Build Provider Images

```bash
# Login to registry first (skip for ttl.sh)
docker login <registry>

# Build provider images
earthly +build-provider-images

# Images are automatically pushed to registry
```

### Step 5: Build Installer ISO

```bash
earthly +iso

# Output: build/palette-edge-installer.iso
```

### Step 6: Verify Artifacts

```bash
# Check ISO
ls -lh build/*.iso

# Verify provider image in registry
docker pull <IMAGE_REGISTRY>/<IMAGE_REPO>:<K8S_DISTRIBUTION>-<K8S_VERSION>-<CUSTOM_TAG>
```

## 2-Node Deployment

2-node HA uses Postgres + Kine backend (not etcd). This is **appliance-mode only**.

### Constraints
- Tech preview status
- Central management only (not local)
- Cannot expand to 3+ nodes later
- Cannot convert to etcd-backed cluster

### 2-Node .arg Configuration

```bash
cat << 'EOF' > .arg
OS_DISTRIBUTION=ubuntu
OS_VERSION=22
K8S_DISTRIBUTION=kubeadm
K8S_VERSION=1.30.4
IMAGE_REGISTRY=ttl.sh
IMAGE_REPO=my-edge-2node
CUSTOM_TAG=2node
ARCH=amd64

# Critical for 2-node
TWO_NODE=true
EOF
```

### 2-Node Cluster Profile

When creating the cluster profile in Palette:
1. Select Edge Native cloud type
2. Add BYOOS pack with provider image reference
3. Configure for 2-node topology (Postgres + Kine backend)
4. Profile cannot be changed to 3+ node topology later

## Content Bundles

Content bundles pre-cache container images for offline or low-bandwidth deployments.

### Build Content Bundle with Palette CLI

```bash
# Install Palette CLI if needed
curl -LO https://github.com/spectrocloud/palette-cli/releases/latest/download/palette-linux-amd64
chmod +x palette-linux-amd64
sudo mv palette-linux-amd64 /usr/local/bin/palette

# Build content bundle
palette content build \
  --arch amd64 \
  --project-id <project-uid> \
  --cluster-profile-ids <profile-id-1>,<profile-id-2> \
  --name my-content-bundle \
  --output ./content-bundle.tar.zst
```

### Build Content Bundle with Palette Edge CLI

```bash
# For air-gapped environments
palette-edge build \
  --api-key <api-key> \
  --project-id <project-id> \
  --cluster-profile-ids <profile-ids>
```

### Include Content Bundle in ISO

Place the content bundle in CanvOS before building ISO:
```bash
mkdir -p content
cp content-bundle.tar.zst content/
earthly +iso
```

## Narrowing K8s Versions

By default, CanvOS builds provider images for ALL K8s versions in `k8s_version.json`. To build specific versions only:

### Option 1: Specify in .arg
```bash
K8S_VERSION=1.30.4
```

### Option 2: Edit k8s_version.json
```bash
# Keep only versions you need
cat k8s_version.json | jq 'map(select(.version | startswith("1.30") or startswith("1.29")))' > k8s_version.json.new
mv k8s_version.json.new k8s_version.json
```

## Validate and Deploy

### Boot from ISO

1. Upload ISO to hypervisor (Proxmox, VMware, etc.)
2. Create VM with 4+ CPU, 8GB+ RAM, 100GB+ disk
3. Boot from ISO
4. Installation proceeds automatically, reboots when complete

### Verify Registration

1. Log into Palette console
2. Navigate to **Clusters > Edge Hosts**
3. Verify host appears with status **Registered**

### Create Cluster

1. Go to **Clusters > Add New Cluster > Edge Native**
2. Select registered edge host(s)
3. Choose cluster profile with BYOOS pack referencing your provider image
4. Deploy cluster

## CI/CD Integration Pattern

### GitHub Actions Example

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
        run: git clone https://github.com/spectrocloud/CanvOS.git

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

### Keep Config Separate from CanvOS

Recommended repo structure for customers:
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

## FIPS Compliance (Advanced)

For federal compliance requirements:

### Requirements
- OS: RHEL or Ubuntu Pro with active subscription
- K8s: RKE2 or kubeadm-fips only (NOT k3s, kubeadm, nodeadm)
- Secure Boot: Must be DISABLED on target devices

### .arg for FIPS
```bash
OS_DISTRIBUTION=rhel
OS_VERSION=9
K8S_DISTRIBUTION=rke2
FIPS_ENABLED=true
```

## Trusted Boot (Advanced)

SecureBoot + Full Disk Encryption + Measured Boot:

### .arg for Trusted Boot
```bash
IS_UKI=true
AUTO_ENROLL_SECUREBOOT_KEYS=true
```

Requires UEFI-capable hardware with TPM 2.0.

## Troubleshooting

### Build fails with registry errors
```bash
# Verify docker login
docker login <registry>

# For ttl.sh, no login needed but images expire in 24h
```

### ISO boot hangs
- Verify EFI partition size > combined ISO + provider image EFI sizes
- Check UEFI vs Legacy BIOS boot mode matches ISO type

### Edge host not registering
- Verify user-data has correct paletteEndpoint and edgeHostToken
- Check network connectivity to Palette API
- Review agent logs: `journalctl -u spectro-stylus-agent.service -f`

## Quick Reference

| Item | Value |
|------|-------|
| CanvOS repo | `https://github.com/spectrocloud/CanvOS` |
| Default OS | Ubuntu 22.04 |
| Default K8s | kubeadm (use n-1 minor version) |
| ISO output | `build/palette-edge-installer.iso` |
| Provider image tag | `<K8S_DIST>-<K8S_VERSION>-<CUSTOM_TAG>` |
| Ephemeral registry | ttl.sh (24h expiry) |

## Links

- [EdgeForge Workflow](https://docs.spectrocloud.com/clusters/edge/edgeforge-workflow/)
- [Build Provider Images](https://docs.spectrocloud.com/clusters/edge/edgeforge-workflow/palette-canvos/build-provider-images/)
- [Build Installer ISO](https://docs.spectrocloud.com/clusters/edge/edgeforge-workflow/palette-canvos/build-installer-iso/)
- [Two-Node Architecture](https://docs.spectrocloud.com/clusters/edge/architecture/two-node/)
- [CanvOS GitHub](https://github.com/spectrocloud/CanvOS)
