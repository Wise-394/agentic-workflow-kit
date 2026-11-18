# Testing

Setup fills this file from the repo. Keep it short; agents read it before every test they write.

## Tools

- Test runner: <runner>. Run one file: `<test command> <file>`.
- Test folder and naming: <where tests live, file naming>.

## What a good test here looks like

- Tests behavior through the public interface, not internals.
- Names start with the requirement ID: `'<REQ-ID>: <behavior>'`.
- One behavior per test. The name says what breaks if it fails.
- Pattern file to copy: `<path to a good existing test>`.

## Test data and helpers

- <factories, fixtures, fake clock, test database, and where they live>

## Don't

- Test the framework or a library.
- Mock the unit under test.
- Assert on text that isn't product-required.
- Write a test that can't fail.
