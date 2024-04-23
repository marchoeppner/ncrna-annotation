# Usage information

[Basic execution](#basic-execution)

[Pipeline version](#specifying-pipeline-version)

[Resources](#resources)

## Basic execution

Please see our [installation guide](installation.md) to learn how to set up this pipeline first. 

A basic execution of the pipeline looks as follows:

a) Without a site-specific config file

```bash
nextflow run marchoeppner/ncrna-annotation -profile singularity --input samples.csv \\
--run_name pipeline-test
```

In this example, the pipeline will assume it runs on a single computer with the singularity container engine available. Available options to provision software are:

`-profile singularity`

`-profile docker` 

`-profile podman` 

`-profile conda` 

Additional software provisioning tools as described [here](https://www.nextflow.io/docs/latest/container.html) may also work, but have not been tested by us. Please note that conda may not work for all packages on all platforms. If this turns out to be the case for you, please consider switching to one of the supported container engines. 

b) with a site-specific config file

```bash
nextflow run marchoeppner/ncrna-annotation -profile lsh --input samples.csv \\
--run_name pipeline-test 
```

In this example, the choice of software provisioning is already set in the local configuration `lsh` and doesn't have to be provided as command line argument. 

## Specifying pipeline version

If you are running this pipeline in a production setting, you will want to lock the pipeline to a specific version. This is natively supported through nextflow with the `-r` argument:

```bash
nextflow run marchoeppner/pipeline -profile lsh -r 1.0 <other options here>
```

The `-r` option specifies a github [release tag](https://github.com/marchoeppner/ncrna-annotation/releases) or branch, so could also point to `main` for the very latest code release. Please note that every major release of this pipeline (1.0, 2.0 etc) comes with a new reference data set, which has the be [installed](installation.md) separately.

## Options

### `--input samples.csv` [ default = null]

The sample file which tells the pipeline the location and the desired IDs for the assembly/assemblies to be annotated. The format should be a comma-delimited CSV file as follows:

```CSV
id,fasta
hg19,/path/to/hg19.fa
```

The file location can either be on a (shared) local file system or one a remote server (S3, FTP). Note that the pipeline cannot be resumed when starting off remote files, so prefer using locally stoed files instead. 

### `--run_name my_pipeline_run` [default = null]

Give this pipeline run a useful name.

## Resources

The following options can be set to control resource usage outside of a site-specific [config](https://github.com/marchoeppner/nf-configs) file.

### `--max_cpus` [ default = 16]

The maximum number of cpus a single job can request. This is typically the maximum number of cores available on a compute node or your local (development) machine. 

### `--max_memory` [ default = 128.GB ]

The maximum amount of memory a single job can request. This is typically the maximum amount og RAM available on a compute node or your local (development) machine. Typically it is advisable to set this a little lower than the maximum amount of RAM to prevent the machine from swapping. 

### `--max_time`[ default = 240.h ]

The maximum allowed run/wall time a single job can request. This is mostly relevant for environments where run time is restricted, such as in a computing cluster with active resource manager or possibly some cloud environments.  