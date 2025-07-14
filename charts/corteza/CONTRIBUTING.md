# Contributing to the Corteza Helm Chart

Thank you for your interest in contributing to the Corteza Helm chart! Your contributions help improve the chart and make it more useful for everyone.

## How to Contribute

### 1. Fork the Repository

Fork this repository and create a new branch for your changes.

### 2. Make Your Changes

- Update the chart files under `charts/corteza/`.
- Follow [Helm best practices](https://helm.sh/docs/chart_best_practices/).
- Update the `README.md`, `NOTES.txt` and `values.yaml` if you add or change configuration options.
- Bump the chart version in `Chart.yaml` according to [semver](https://semver.org/).

### 3. Test Your Changes

- Run `helm lint charts/corteza` to check for linting errors.
- Install the chart locally using `helm install` to verify it works as expected.

### 4. Write or Update KUTTL Tests

We use [KUTTL](https://kuttl.dev/) for integration testing of the Helm chart.

#### Writing KUTTL Tests

- Add new test cases under `tests/`.
- Each test should have its own directory with a `kuttl-test.yaml` manifest and any assertions.
- Example structure:
  ```
  tests/some-test/
    ├── kuttl-test.yaml
    └── my-test/
        ├── 00-install.yaml
        └── 00-assert.yaml
  ```
- Use `kuttl test` to run the tests:
  ```sh
  kuttl test --config tests/some-test/kuttl-test.yaml
  ```

#### Example KUTTL Test
This example creates a Deployment, and asserts the number of available replicas after creation. If the numbers match, the test passes, and fails otherwise.
`kuttl-test.yaml`:
```yaml
apiVersion: kuttl.dev/v1beta1
kind: TestSuite
testDirs:
  - ./charts/corteza/tests/some-test
namespace: test-namespace

```

`00-install.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: alpine:latest
        command: ["sh", "-c", "sleep 3600"]

```

`assert.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: corteza
status:
  availableReplicas: 1
```

For further reference, visit [Kuttl's website](https://kuttl.dev/docs/kuttl-test-harness.html#writing-your-first-test).

### 5. Submit a Pull Request

- Push your branch and open a pull request against the `main` branch.
- Describe your changes and reference any related issues.

When submitting a PR make sure that it:

- Must pass CI jobs for linting and test the changes on top of different k8s platforms. (Automatically done by the Bitnami CI/CD pipeline).
- Must follow [Helm best practices](https://helm.sh/docs/chart_best_practices/).
- Any change to a chart requires a version bump following [semver](https://semver.org/) principles. This is the version that is going to be merged in the GitHub repository, then our CI/CD system is going to publish in the Helm registry a new patch version including your changes and the latest images and dependencies.

#### Sign Your Work

The sign-off is a simple line at the end of the explanation for a commit. All commits needs to be signed. Your signature certifies that you wrote the patch or otherwise have the right to contribute the material. The rules are pretty simple, you only need to certify the guidelines from [developercertificate.org](https://developercertificate.org/).

Then you just add a line to every git commit message:

```text
Signed-off-by: Joe Smith <joe.smith@example.com>
```

Use your real name (sorry, no pseudonyms or anonymous contributions.)

If you set your `user.name` and `user.email` git configs, you can sign your commit automatically with `git commit -s`.

Note: If your git config information is set properly then viewing the `git log` information for your commit will look something like this:

```text
Author: Joe Smith <joe.smith@example.com>
Date:   Thu Feb 2 11:41:15 2018 -0800

    Update README

    Signed-off-by: Joe Smith <joe.smith@example.com>
```

Notice the `Author` and `Signed-off-by` lines match. If they don't your PR will be rejected by the automated DCO check.

### PR Approval and Release Process

1. Changes are manually reviewed by Origoss Labs team members, in addition to a lint-check CI job.
2. When the PR passes all tests, the PR is merged by the reviewer(s) in the GitHub `main` branch.
3. Then our CI/CD system is going to push the chart to the Helm registry including the recently merged changes and also the latest images and dependencies used by the chart. The changes in the images will be also committed by the CI/CD to the GitHub repository, bumping the chart version again.

> ***NOTE***: Please note that, in terms of time, may be a slight difference between the appearance of the code in GitHub and the chart in the registry.

## Code of Conduct

Please be respectful and follow our [Code of Conduct](../CODE_OF_CONDUCT.md).

---

Thank you for helping improve the Corteza Helm chart!
