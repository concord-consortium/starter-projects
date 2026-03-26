import React from "react";
import { Text } from "./text";
import { render, screen } from "@testing-library/react";

describe("Text component", () => {
  it("renders provided text", () => {
    render(<Text text="Hello World"/>);
    expect(screen.getByRole("heading", { name: "Hello World" })).toBeDefined();
  });
});
