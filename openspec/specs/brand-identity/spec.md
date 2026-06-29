# brand-identity Specification

## Purpose

Defines the product's brand identity: the canonical company name and casing (`SUPER 8 Studio`), the product name that surfaces the `InsightArk` trademark (`SUPER 8 Studio InsightArk Skills`), and the trademark/attribution declaration (NOTICE + LICENSE copyright) — plus which user-facing surfaces each must appear in and which internal identifiers are exempt.

## Requirements
### Requirement: Canonical company name casing

All human-readable text SHALL refer to the company by the canonical form `SUPER 8 Studio` (with `SUPER 8` in all caps). The forms `Super 8 Studio` and `Super8` SHALL NOT appear in user-facing text. Stable internal identifiers (skill folder names like `super8-studio-*`, env vars `S8_*`, config filenames `.super8-studio.*`) are exempt and retain their existing names.

#### Scenario: Display and prose use the canonical form

- **WHEN** any README, setup guide, manifest display field, description, or CLI message names the company
- **THEN** it reads `SUPER 8 Studio` and not `Super 8 Studio` or `Super8`

#### Scenario: Internal identifiers are exempt

- **WHEN** code references a skill folder, env var, or config filename containing `super8-studio`
- **THEN** that identifier is unchanged by this naming rule

### Requirement: Product name surfaces the InsightArk trademark

The product SHALL be named `SUPER 8 Studio InsightArk Skills` in all user-facing display names, descriptions, the README titles, and the setup guide. The prior name `SUPER 8 Studio API Skills` SHALL NOT appear.

#### Scenario: Plugin manifests display the product name

- **WHEN** a plugin manifest's `displayName` (or `interface.displayName`) is read
- **THEN** it is `SUPER 8 Studio InsightArk Skills`

#### Scenario: README and setup guide titles

- **WHEN** the README (EN or 中文) or `Introduction.html` titles the product
- **THEN** it reads `SUPER 8 Studio InsightArk Skills`

### Requirement: Trademark and attribution declaration

The repository SHALL carry a `NOTICE` file declaring `InsightArk`, `SUPER 8`, and `SUPER 8 Studio` as trademarks of SUPER 8 Studio, and the `LICENSE` copyright line SHALL name the copyright owner (`Copyright 2026 SUPER 8 Studio`) rather than a placeholder.

#### Scenario: NOTICE declares the marks

- **WHEN** the `NOTICE` file is read
- **THEN** it names `InsightArk`, `SUPER 8`, and `SUPER 8 Studio` as trademarks and references Apache-2.0 §6

#### Scenario: LICENSE copyright is filled

- **WHEN** the `LICENSE` copyright line is read
- **THEN** it reads `Copyright 2026 SUPER 8 Studio` with no `[yyyy]` / `[name of copyright owner]` placeholder

