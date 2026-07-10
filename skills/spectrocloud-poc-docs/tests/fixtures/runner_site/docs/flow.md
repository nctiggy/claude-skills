# Runner happy-path flow

## Step 1 — Emit a value on the node

<!-- poc-test
id: emit-value
host: node
capture:
  GREETING: "tail -n1"
-->

```bash
echo preparing
echo hello-$SUITE_TAG
```

## Step 2 — Write a config file from a yaml block

<!-- poc-test
id: write-config
host: node
needs: [emit-value]
file: $POC_ARTIFACTS/config.yaml
subst:
  "<greeting>": "$GREETING"
-->

```yaml
greeting: <greeting>
```

## Step 3 — Verify locally with assert + until

<!-- poc-test
id: check-config
host: local
needs: [write-config]
timeout: 60
assert: grep -q "hello-mock" "$POC_ARTIFACTS/config.yaml"
until: test -f "$POC_ARTIFACTS/config.yaml"
retry:
  attempts: 3
  delay: 1
-->

```bash
cat "$POC_ARTIFACTS/config.yaml"
```

## Step 4 — Echo the secret (masking check)

<!-- poc-test
id: echo-secret
host: local
needs: [check-config]
-->

```bash
echo "key is $PALETTE_API_KEY"
```

## Step 5 — Block-level retry (no until)

<!-- poc-test
id: retry-block
host: local
needs: [check-config]
retry:
  attempts: 3
  delay: 1
-->

```bash
if [ ! -f "$POC_ARTIFACTS/retry.flag" ]; then
  touch "$POC_ARTIFACTS/retry.flag"
  echo "first attempt fails on purpose"
  exit 1
fi
echo "second attempt passes"
```

## Step 6 — Conditionally skipped block

<!-- poc-test
id: gpu-only
host: node
when: GPU_PRESENT
-->

```bash
echo "this only runs when GPU_PRESENT is set"
```
