# PRD — <product name>

## Problem

<Who has the problem, and what it is, in plain words.>

## Users

- <user type> — <what they need>

## Requirements

Each requirement is one testable sentence in one of these forms (EARS):

- Always true: "The <system> shall <response>."
- On an event: "When <trigger>, the <system> shall <response>."
- In a state: "While <state>, the <system> shall <response>."
- On a failure: "If <unwanted condition>, then the <system> shall <response>."
- For an option: "Where <feature is present>, the <system> shall <response>."

### <Area> (<PREFIX>)

| ID | Requirement | Priority |
|---|---|---|
| <PREFIX>-01 | When <trigger>, the <system> shall <response>. | must \| should \| later |

## Non-functional requirements

| ID | Requirement | Priority |
|---|---|---|
| NFR-01 | <performance, reliability, privacy, accessibility, or security, with a number where possible: "The list shall render 1,000 entries in under 1 second on <device>."> | must \| should |

## Non-goals

- <what this product will not do>

## Architecture constraints

- <platform, storage, offline, privacy, and similar rules that every issue must keep>

## Changelog

- <date> — <what changed, which IDs>
