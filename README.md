# CF Helm Charts 

This repository contains Helm Charts commonly used and developed at the Cardano Foundation.

Use at your own risk.

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
