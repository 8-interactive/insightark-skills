# Skill Authoring Guide

This guide explains how to write a new skill for the Super 8 Studio API Skills bundle.

## Folder Structure

```
bundle/super8-studio-<name>/
├── SKILL.md
└── tests/
    ├── eval_cases.yaml
    └── fixtures/
```

Scripts live in `bundle/_super8-studio-api-shared/scripts/` and should be referenced from `SKILL.md` with `../_super8-studio-api-shared/scripts/<name>.sh`.

## Required SKILL.md Frontmatter

```yaml
---
name: super8-studio-<name>
description: <action verb> + <task boundary> + <domain keywords>. Use when <trigger condition>.
when_to_use: <one sentence trigger description>
allowed-mcp: false
license: MIT
metadata:
  owner: platform
  version: "1.0.0"
  category: <agent-foundation | agent-orchestrator | conversation-api | customer-api | broadcast-api | marketing-automation-api>
  domain: super8-studio
---
```

## Required Body Sections

Every `SKILL.md` must include `## When not to use`, `## Inputs`, `## Outputs`, `## Workflow`, `## Failure handling`, and `## Guardrails`. Additional sections are allowed.

## Failure Handling Guidance

For every failure mode, state the condition, correct response, and what not to do. Do not fabricate data, infer missing values, or retry writes silently.

## Validation

Run before every PR:

```bash
bash scripts/validate-skills.sh
```
