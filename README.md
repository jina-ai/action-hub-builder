# hub-builder

`hub-builder` is a simple interface for building & validating [Jina Hub](https://github.com/jina-ai/jina-hub) executors. It is built on top of [`jina hub` interface](https://github.com/jina-ai/jina). It can be used as a Github action in the CICD workflow, or via CLI.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


<!-- END doctoc generated TOC please keep comment here to allow auto update -->



## Github Action Usage

One can use it as a part of CI pipeline, to build and test images in the Pull Request. Simply copy-paste the following YAML file into `.github/workflows/hub-builder.yml`. 

```yaml
name: Hub Builder

on: [pull_request]

jobs:
  hub_builder:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Jina Hub Image Builder
        uses: jina-ai/hub-builder@v0.2
```

On every new PR, the builder will find all modified `manifest.yml` recursively (deleting is excluded) and try to build an Hub image from it, one by one. That means, when you update an image, you *must* change `manifest.yml` to trigger the build, e.g. you can simply bump `version` field in `manifest.yml`.

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

## License

Copyright (c) 2020 Jina AI Limited. All rights reserved.

Jina is licensed under the Apache License, Version 2.0. [See LICENSE for the full license text.](LICENSE)
