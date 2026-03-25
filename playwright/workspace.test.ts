import { test } from "./lib/base-url";
import { expect } from "@playwright/test";

test("renders with text", async ({ page }) => {
  await page.goto("/");
  await expect(page.locator(".app")).toHaveText("Hello World");
});
