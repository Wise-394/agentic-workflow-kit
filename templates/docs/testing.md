# Testing

Setup fills this file from the repo. Keep it short; agents read it before every test they write.

## Tools

- Test runner: <runner>. Run one file: `<test command> <file>`.
- Test folder and naming: <where tests live, file naming>.

## What a good test here looks like

- Tests behavior through the public interface, not internals.
- Names start with the requirement ID: `'<REQ-ID>: <behavior>'`, or the issue number for work outside the PRD: `'#<N>: <behavior>'`.
- One behavior per test. The name says what breaks if it fails.
- Arrange, act, assert, in that order, with one action.
- Exact expectations (`equals 3`), not loose ones (`is truthy`, `is defined`).
- Pattern file to copy: `<path to a good existing test>`.

## Test data and helpers

- <factories or builders, fixtures, fake clock, sequential IDs, test database, and where they live>
- Build test data with the builders, overriding only the fields the test is about.
- Prefer real collaborators (an in-memory database, a fake clock) over mocks. Mock only what you can't run: the network, the device, paid services.

## Deterministic

- Time, IDs, and randomness come from the fakes above, never from the real clock or a random source.
- Each test sets up its own data. No test depends on another test's leftovers or order.
- No sleeps. Wait on a condition or use the fake clock.

## What to cover

- The happy path of each acceptance test.
- Every failure path and boundary the requirement names (empty, maximum, invalid, storage failure).
- A bug fix adds the test that reproduces the bug.

## Don't

- Test the framework or a library.
- Mock the unit under test.
- Assert on call order, private state, or query text.
- Assert on text that isn't product-required.
- Write a test that can't fail.
