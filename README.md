# CF Helm Charts 

This repository contains Helm Charts commonly used and developed at the Cardano Foundation.

Use at your own risk.

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

`helm repo add cf-helm https://cardano-foundation.github.io/cf-helm-charts`

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
cf-helm` to see the charts.

To install the <chart-name> chart:

    helm install my-<chart-name> cf-helm/<chart-name>

To uninstall the chart:

    helm delete my-<chart-name>

## Helm Chart Build

This repo is configured following the Helm Chart docs available [here](https://helm.sh/docs/topics/chart_repository/)

### Building a chart

Assuming the folder containing all the charts is called `charts`, you can build and index new charts or updates as follows.

Packaging a chart:

```bash
helm package path/to/my_chart/
```

Deploying and indexing a chart:

```bash
mv my_chart-x.y.z.tgz charts/
helm repo index charts --url https://cardano-foundation.github.io/cf-helm-charts/
```

Add new or modified files to git, push changes. 

Congrats, you've deployed a new or updated chart to our repository

### Automated Release

This repo has been configured to automatically release new and updated charts following [this gha](https://helm.sh/docs/howto/chart_releaser_action/)
