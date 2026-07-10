# AMT power control (MS-01 bare-metal nodes)

Intel AMT via wsman for node11–13 (registered in MaaS). **Only ever run these against
nodes in the MaaS inventory** — never probe arbitrary hosts on 16993.

- **Port 16993 only (HTTPS)** — HTTP/16992 is not available.
- Untrusted certs: always `--noverifypeer --noverifyhost`.
- MaaS's power driver (`/usr/lib/python3/dist-packages/provisioningserver/drivers/power/amt.py`)
  is patched for the same SSL flags; wsman is used for AMT version > 8, amttool older.
- AMT admin password: 1Password (see credentials.md) — never inline it in saved scripts.

## Query power state

```bash
wsman --endpoint "https://admin:$AMT_PASSWORD@$HOST:16993" --noverifypeer --noverifyhost \
  --optimize --encoding utf-8 enumerate \
  "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_AssociatedPowerManagementService"
```

## Change power state (2=on, 8=off, 10=restart)

Requires XML input (files live on the MaaS box):

```bash
wsman --endpoint "https://admin:$AMT_PASSWORD@$HOST:16993" --noverifypeer --noverifyhost \
  --input - invoke --method RequestPowerStateChange \
  'http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_PowerManagementService?SystemCreationClassName="CIM_ComputerSystem"&SystemName="Intel(r) AMT"&CreationClassName="CIM_PowerManagementService"&Name="Intel(r) AMT Power Management Service"'
```

XML payloads on the MaaS box:

| File | Purpose |
|---|---|
| `amt.wsman-state.xml` | power state changes |
| `amt.wsman-pxe.xml` | PXE boot order |
| `amt.wsman-boot-config.xml` | boot config |
