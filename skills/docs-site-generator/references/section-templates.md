# Section Templates

## getting-started.md

```markdown
---
title: Getting Started
description: Quick start guide
sidebar_position: 1
---

# Getting Started

## Prerequisites

- Requirement 1
- Requirement 2

## Installation

Step-by-step instructions.

## Verification

How to confirm it works.

## Next Steps

- [Architecture overview](architecture/)
- [Configuration reference](reference/configuration.md)
```

## Troubleshooting Page

```markdown
---
title: Common Issues
description: Solutions for frequently encountered problems
---

# Troubleshooting

## Symptom: [Description]

**Cause:** Explanation.

**Solution:**

1. Step one
2. Step two

!!! tip
    Additional context or prevention advice.
```

## Runbook Page

```markdown
---
title: Runbook - [Procedure Name]
description: Step-by-step operational procedure
---

# [Procedure Name]

| Field       | Value              |
|-------------|--------------------|
| Owner       | Team name          |
| Last tested | YYYY-MM-DD         |
| Duration    | ~X minutes         |

## Prerequisites

- [ ] Checklist item

## Procedure

### Step 1: [Action]

```bash
command here
```

Expected output: description.

### Step 2: [Action]

Continue steps...

## Rollback

Steps to reverse if needed.

## Verification

How to confirm success.
```
