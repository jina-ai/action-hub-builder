# hub-builder

`hub-builder` is a simple interface for building & validating [Jina Hub](https://github.com/jina-ai/jina-hub) executors. It is built on top of [`jina hub` interface](https://github.com/jina-ai/jina). It can be used as a Github action in the CICD workflow, or via CLI.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Github Action Usage](#github-action-usage)
- [CLI Usage](#cli-usage)
- [Contributing](#contributing)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->



## Github Action Usage

One can use it as a part of CI pipeline, to build and test images in the Pull Request. Simply copy-paste the following YAML file into `.github/workflows/hub-builder.yml`. 

```yaml
name: Hub Builder

on: [pull_request]

jobs:
  hub-builder:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Jina Hub Image Builder
        uses: jina-ai/hub-builder@v0.2
```

On every new PR, the builder will find all modified `manifest.yml` recursively (deleting is excluded) and try to build an Hub image from it, one by one. That means, when you update an image, you *must* change `manifest.yml` to trigger the build, e.g. you can simply bump `version` field in `manifest.yml`.


### Input Arguments of the Action

| Name | Description | Default |
| --- | --- | --- |
| `push` | if push to Docker Hub and MongoDB | False |
| `dockerhub_username` | user name of the docker registry | |
| `dockerhub_password` | the plaintext password of the docker hub| |
| `dockerhub_registry` | the URL to the registry | `https://index.docker.io/v1/` |
| `mongodb_hostname` | the host name of Mongodb Atlas | |
| `mongodb_username` | the user name of Mongodb Atlas | |
| `mongodb_password` | the plaintext password of Mongodb Atlas | |
| `mongodb_database` | the database in Mongodb Atlas | |
| `mongodb_collection` | the collection in Mongodb Atlas | |


Example when using MongoDB Atlas for bookkeeping.

```yaml
name: Hub Builder

on: [pull_request]

jobs:
  hub-builder:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Jina Hub Image Builder
        uses: jina-ai/hub-builder@v0.2
        with:
          push: true
          mongodb_hostname: ${{secrets.JINA_DB_HOSTNAME}}
          mongodb_username: ${{secrets.JINA_DB_USERNAME}}
          mongodb_password: ${{secrets.JINA_DB_PASSWORD}}
          mongodb_database: ${{secrets.JINA_DB_NAME}}
          mongodb_collection: ${{secrets.JINA_DB_COLLECTION}}
```

### Output of the Action

There are two outputs you can use in the post-action:

| Name | Description |
| --- | --- |
|`success_targets` | `Successfully built targets with their paths` |
|`failed_targets` | `Failed built targets with their paths` |

To use the output values, you have to refer to the step by `id`, e.g.

```yaml
jobs:
  test_hubbuilder:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Hub builder step
        id: hubbuild  # later we can refer to this step
        uses: ./ # Uses an action in the root directory
        continue-on-error: true
      - name: Get the output
        run: echo "success ${{ steps.hubbuild.outputs.success_targets }} failed ${{ steps.hubbuild.outputs.failed_targets }}"

``` 

## CLI Usage

### Install

```bash
pip install -r requirements.txt
python app.py --help
```

### Recursively Build All Executors in `/abc`

```bash
python app.py /abc
``` 

### Recursively Check All Executors in `/abc` Without Building

```bash
python app.py /abc --dry-run
```

Note that `dry-run` only checks the name conventions, required files. No actual testing and building. 

### View the Build Log of a Run

Simply open the `build-TIMESTAMP.json`, there you have a complete overview of this build round and details of each executors.

## Contributing

We welcome all kinds of contributions from the open-source community, individuals and partners. Without your active involvement, Jina won't be successful.

Please first read [the contributing guidelines](https://github.com/jina-ai/jina/blob/master/CONTRIBUTING.md) before the submission.


### Triggering CI of this Repo

We have a simple test case to ensure the correctness of the PR to this action. As this action monitors the change of `manifest.yml`, to trigger the action, you have to modify `manifest.yml`, e.g. by bumping the version number.

- [`manifest.yml` that expects to fail in CI](.github/workflows/tests/EmptyExecutor/manifest.yml)
- [`manifest.yml` that expects to success in CI](.github/workflows/tests/ImageReader/manifest.yml)

Commit the changes above along with your PR, it will trigger the CI. If both expectations are met, then your PR is good to go.

## License

Copyright (c) 2020 Jina AI Limited. All rights reserved.

Jina is licensed under the Apache License, Version 2.0. [See LICENSE for the full license text.](LICENSE)
