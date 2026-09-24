# Release Notes · Storefront 4.12

> **Heads-up:** the checkout now runs on the new payment gateway. Old sessions are migrated automatically.

## What's new

- **Faster search** — results appear in under *40 ms*, even on slow networks
- ~~Legacy cart API~~ removed after two deprecation cycles
- Inline `code`, [links](https://example.com) and emoji 🚀 render natively

### Migration checklist

- [x] Rotate API keys
- [x] Update webhook URLs
- [ ] Remove the `LEGACY_CART` flag

| Metric | Before | After | Change |
| :--- | ---: | ---: | :---: |
| Time to first byte | 312 ms | 118 ms | **−62 %** |
| Bundle size | 412 kB | 267 kB | **−35 %** |
| Lighthouse score | 81 | 98 | ✅ |

```swift
struct Order: Codable {
    let id: UUID
    var total: Decimal
    var isPaid = false   // set by the gateway webhook
}
```
