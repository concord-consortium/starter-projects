import { test } from "./lib/base-url";
import { expect } from "@playwright/test";

test("renders with text", async ({ page }) => {
  await page.goto("/");
  // Prefer getByRole over CSS selectors or data-testid for Playwright tests.
  // See https://playwright.dev/docs/locators#quick-guide
  await expect(page.getByRole("heading", { name: "Hello World" })).toBeVisible();
});
