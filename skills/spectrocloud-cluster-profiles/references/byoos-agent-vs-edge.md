# BYOOS Pack Values: Agent vs Edge Mode

The BYOOS (edge-native-byoi) pack is the **ONLY mode-specific pack** in a Palette Edge infrastructure profile. All other packs (K8s, CNI, storage) and all add-on profiles are mode-agnostic.

## Three Differences Between Agent and Edge Mode

| Config Area | Agent Mode | Edge/Appliance Mode |
|-------------|-----------|-------------------|
| `options.system.uri` | `"NA"` | Go template with sub-options (see below) |
| Containerd config | Spectro-specific paths | System defaults (no root/state/grpc/BinaryName) |
| Initramfs commands | `spectro.slice` + `system.slice` | `system.slice` only |

**Why they differ:** Agent mode runs a Spectro-managed containerd alongside the system containerd, so it needs custom paths (`/var/lib/spectro/containerd`, `/run/spectro/containerd`, `/opt/bin/runc`) and a separate `spectro.slice` for CPU isolation. Edge/appliance mode uses the OS-native containerd baked into the provider image.

## Agent Mode options block
```yaml
options:
  system.uri: "NA"
```

## Edge/Appliance Mode options block
```yaml
options:
    system.uri: "{{ .spectro.pack.edge-native-byoi.options.system.registry }}/{{ .spectro.pack.edge-native-byoi.options.system.repo }}:{{ .spectro.pack.edge-native-byoi.options.system.k8sDistribution }}-{{ .spectro.system.kubernetes.version }}-{{ .spectro.pack.edge-native-byoi.options.system.peVersion }}-{{ .spectro.pack.edge-native-byoi.options.system.customTag }}"
    system.registry: my-registry.company.local
    system.repo: ubuntu
    system.k8sDistribution: kubeadm
    system.osName: ubuntu
    system.peVersion: v4.5.11
    system.customTag: my-custom-tag
    system.osVersion: 24.04

# providerCredentials:
#   registry: my-registry.company.local
#   user: "user"
#   password: ""
```

**Note:** Edge options use 4-space indentation (not 2-space). This matches the API's stored format.

## Agent Mode containerd config (REMOVE these for edge)
```toml
root = "/var/lib/spectro/containerd"
state = "/run/spectro/containerd"
[grpc]
  address = "/run/spectro/containerd/containerd.sock"
# ... and in runc.options:
  BinaryName = "/opt/bin/runc"
```

## Edge Mode containerd config (system defaults)
```toml
version = 2
imports = ["/etc/containerd/conf.d/*.toml"]
[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    sandbox_image = "registry.k8s.io/pause:3.10"
    # ... rest of config, NO root/state/grpc/BinaryName
```

## Agent Mode spectro.slice (REMOVE for edge)
```yaml
# Agent mode has BOTH lines:
- systemctl set-property system.slice AllowedCPUs={{ .spectro.var.systemReservedCPU }}
- systemctl set-property spectro.slice AllowedCPUs={{ .spectro.var.systemReservedCPU }}

# Edge mode has ONLY system.slice:
- systemctl set-property system.slice AllowedCPUs={{ .spectro.var.systemReservedCPU }}
```

## What NOT to Conflate

- **Mode differences** (agent vs edge): system.uri, containerd paths, spectro.slice
- **Storage-weight differences** (e.g., Piraeus vs Portworx): memory reservations, NFS config — these vary by storage, NOT by mode

When cloning from RA templates, verify you're cloning the correct mode variant (e.g., `VMO-RA-Infra-Edge-*` not `VMO-RA-Infra-Agent-*`).
