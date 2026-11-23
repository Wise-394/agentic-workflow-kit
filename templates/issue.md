<!-- Issue body template. Used by agentkit-plan, splits, and fix issues. One issue is one PR; size rules are in the agentkit-plan skill's split reference. -->

## Goal

<One or two sentences: what the user can do after this, in plain words.>

## Requirements

- <REQ-ID>: <requirement text, copied from docs/prd.md>

## Acceptance tests

- [ ] <REQ-ID>: Given <starting state>, when <action>, then <observable result>

## Read

- <docs/prd.md and docs/design.md sections, decisions, or earlier issues the planner should read first>

## Starting points

- <folders or files where the work most likely lands, for the scout: for example `src/data/entries/`>

## Out of scope

- <what this issue deliberately does not do> → #<issue that owns it> | not planned

## Size

- About <n> files and <n> changed lines; <layer or vertical slice>

## Checks only a person can do

- <for example: "on a real phone, the upload finishes after the screen locks"> | none

Blocked by #<N>
