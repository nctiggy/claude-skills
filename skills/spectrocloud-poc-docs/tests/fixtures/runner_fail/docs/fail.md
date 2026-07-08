# Runner failure-path flow

<!-- poc-test
id: passes-first
host: node
-->

```bash
echo fine
```

<!-- poc-test
id: fails-assert
host: local
needs: [passes-first]
assert: grep -q "never-there" "$POC_STDOUT"
-->

```bash
echo something-else
```

<!-- poc-test
id: never-reached
host: node
needs: [fails-assert]
-->

```bash
echo unreachable
```
