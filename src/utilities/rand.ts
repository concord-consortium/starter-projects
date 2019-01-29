import seedrandom = require("seedrandom");

/*
 * It may be useful, particularly when displaying UI or graphical elements, to
 * introduce a sense of randomness for esthetic or visual purposes; but, with
 * a notion of reproducible values. In other words, a pseudo random sequence
 * from a seedable generator would be very handy. The default Math.random()
 * function does not support a seed value.
 *
 * For this reason, the `seedrandom` npm package has been used. As an example of
 * it's use, the following rand() function returns a pseudo random number within
 * a given range. See https://github.com/davidbau/seedrandom for details.
 *
 * Also, see the companion test file for sample usage of this function.
 */

const rng = seedrandom("12345");  // Create a prng, leaving Math.random() alone.

export function rand(low: number, high: number): number {
  return Math.floor(rng() * (high - low + 1) + low);
}
