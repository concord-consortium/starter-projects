import React from "react";
import { render, screen } from "@testing-library/react";
import { App } from "./app";

describe("App component", () => {
  it("renders text", () => {
    render(<App/>);
    expect(screen.getByText("Hello World")).toBeDefined();
    expect(screen.getByRole("img")).toHaveAttribute("src", "test-file-stub");
  });
});
