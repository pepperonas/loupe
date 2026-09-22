# Code Blocks Fixture

### Swift
```swift
import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    var name: String
    var isActive: Bool
}

func greet(user: User) -> String {
    guard user.isActive else { return "Inactive user" }
    return "Hello, \(user.name)!"
}
```

### Rust
```rust
use std::collections::HashMap;

pub struct Cache<K, V> {
    entries: HashMap<K, V>,
}

impl<K: std::hash::Hash + Eq, V> Cache<K, V> {
    pub fn new() -> Self {
        Self { entries: HashMap::new() }
    }
}
```

### Python
```python
def solve(items: list[int]) -> int:
    # Filter and sum
    return sum(x * 2 for x in items if x > 0)
```

### SQL
```sql
SELECT users.id, users.name, COUNT(orders.id) AS total_orders
FROM users
LEFT JOIN orders ON users.id = orders.user_id
WHERE users.is_active = 1
GROUP BY users.id, users.name
ORDER BY total_orders DESC;
```

### JSON
```json
{
  "project": "MarkLook",
  "version": "0.0.1",
  "native": true,
  "ports": [80, 443]
}
```
