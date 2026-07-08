# Clean fixture

A perfectly hygienic customer-facing page. See the [guide](guide.md) and its
[second step](guide.md#step-2-verify).

```bash
export PALETTE_API_KEY=<your-api-key>
curl -s "https://api.spectrocloud.com/v1/projects" -H "ApiKey: $PALETTE_API_KEY" | jq '.'
```
