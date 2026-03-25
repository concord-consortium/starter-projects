/**
 * Custom Playwright test fixture that automatically discovers the webpack dev
 * server's port via Bonjour/mDNS when running locally. This removes the need
 * to hardcode a port — webpack-dev-server advertises itself as a Bonjour
 * service (configured in webpack.config.js), and this fixture finds it by name.
 *
 * On CI, baseURL is set explicitly in playwright.config.ts, so Bonjour
 * discovery is skipped. Import `test` from this file instead of from
 * `@playwright/test` in all test files.
 */
import { test as base } from "@playwright/test";
import { Bonjour, Service } from "bonjour-service";

async function findDevServerPort(): Promise<string> {
  const bonjour = new Bonjour();
  try {
    const service = await new Promise<Service | null>((resolve) => {
      // eslint-disable-next-line prefer-const
      let timer: NodeJS.Timeout;
      const browser = bonjour.find({type: "http"}, _service => {
        if (_service.name === process.env.BONJOUR_SERVICE_NAME) {
          if (timer !== undefined) clearTimeout(timer);
          browser.stop();
          resolve(_service);
        }
      });
      timer = setTimeout(() => {
        browser.stop();
        resolve(null);
      }, 3000);
    });

    if (!service) {
      const name = process.env.BONJOUR_SERVICE_NAME;
      throw new Error(
        `No Bonjour service found with name '${name}'. Run \`npm start\` to start the dev server.`
      );
    }

    return service.port.toString();
  } finally {
    bonjour.destroy();
  }
}

async function getBaseUrl() {
  let port = process.env.DEV_SERVER_PORT;
  if (!port) {
    port = await findDevServerPort();
    process.env.DEV_SERVER_PORT = port;
  }
  return `http://localhost:${port}`;
}

export const test = base.extend({
  baseURL: async ({ baseURL }, use) => {
    if (!baseURL) {
      if (process.env.CI) {
        throw new Error("baseURL must be set in CI environment");
      }
      baseURL = await getBaseUrl();
    }
    await use(baseURL);
  },
});
