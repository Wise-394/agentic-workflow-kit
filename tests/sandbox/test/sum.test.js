import { test } from 'node:test';
import assert from 'node:assert/strict';
import { sum } from '../src/sum.js';

test('MATH-01: sum adds a list of numbers', () => {
  assert.equal(sum([1, 2, 3]), 6);
});

test('MATH-01: sum of an empty list is 0', () => {
  assert.equal(sum([]), 0);
});
