# Cypress Code Coverage

Code coverage of the cypress tests has a complex setup.

More information about all of this can be found here: https://github.com/cypress-io/code-coverage

TODO: update the version of `@cypress/code-coverage` and how it is imported so it matches what is described here: https://github.com/cypress-io/code-coverage

## Cypress end to end tests

The cypress E2E tests are run against the application source which is served by webpack-dev-server. This application source is run in a cypress controlled browser. For code coverage we need to track which lines of the source are hit when the cypress test are running, and thens save this info so reports can be produced from it.

The first step in the process is tracking which lines of code are hit. This is done by the `istanbul-instrumenter-loader`. This loader is configured with `enforce: post` so that it is applied at the end of the processing chain. This project only enables this loader when the `CODE_COVERAGE` environement variable is set. You can verify it is working by:
- run `CODE_COVERAGE=true npm start`
- visit the site in a browser
- look in the browser console for `window.__coverage__`
- this variable should contain info about each file that has been covered so far

This coverage information needs to be collected after each test run. This is done by the `@cypress/code-coverage/support` module that is imported in the `cypress/support/index.js` file. It sets up the coverage stats before each test, and then sends the coverage information to the cypress test runner via `cy.task` at the end of each task.

The coverage information needs to be received by the cypress test runner and written out to a file. This is done by the plugin `@cypress/code-coverage/task`. It is added to the `cypress/pulgins/index.js`. It is registered as a task listener. It receives the coverage information, merges it and saves it in the raw file `.nyc_output/out.json`. It also has a task command which then runs the nyc processor to convert this raw file into a set of html files reporting on the coverage information.

When running the cypress tests you should some additional 'task' events logged. These are a record of the support module sending the coverage info, and then telling the task module to save the coverage.

The nyc processor is configured by the `nyc` section in `package.json`. It is configured to save the final coverage info to a different folder so it is separate from the Jest coverage info. It also extends  `@istanbuljs/nyc-config-typescript` which lets nyc work with typescript sourcemaps.

## Cypress unit tests

This setup hasn't been tested to see if it covers the cypress unit tests. These work slightly differently because in this case the application code is included right into the test runner code. So in this case the test runner needs to instrument this application code when it is loaded.

In theory the setup in this project should work in this case. This is because the `@cypress/webpack-preprocessor` is being used. This should pass all cypress test code through the same webpack config that is used by the webpack-dev-server. So the application code should get instrumented during this process.