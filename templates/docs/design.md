# <Product name>: design

## Principles

<Five to ten non-negotiables every change must respect, one line each. For example: "All user data stays on the device." "Every write runs in one transaction." "Time comes from the injected clock.">

## Stack

| Part | Choice | Why (decision record) |
|---|---|---|
| Language, runtime | <choice> | `docs/decisions/0001-<slug>.md` |

## Architecture

<The layers or modules, what each owns, and the one direction dependencies point. A small diagram if it helps.>

| Layer or module | Folder | Owns | Must not |
|---|---|---|---|
| <layer> | `<folder>` | <responsibility> | <what it never does or imports> |

## Data model

<Entities, fields, relations, and where each is stored.>

## External services

<Every API, service, or account the product depends on, and what happens when it is down.>

## Testing and verification

<Test levels and runner. How a change is proven in the running app (detailed later in docs/verify.md).>
