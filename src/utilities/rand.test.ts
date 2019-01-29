import { rand } from "./rand";

describe("rand(low, high) - seeded random number function", () => {

  it("generates pseudo random numbers", () => {
    // Since this is a seeded prng, this test should always pass. By that, we
    // mean, these pseudo random numbers should always come out in this order.
    const results = Array.from({length: 10}, () => rand(0, 100));
    expect(results).toEqual([20, 66, 50, 88, 100, 75, 97, 93, 11, 78]);
  });

  it("generates the span of values in the low-to-high range specified", () => {
    // As it happens, this particular seed covers the range of requested values
    // in the first two calls.
    expect(rand(0, 1)).toEqual(1);
    expect(rand(0, 1)).toEqual(0);
  });

});
