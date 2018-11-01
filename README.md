# exfoxp3

This package contains code to analyze genomic measurements (RNA, ATAC, and ChIP)
and generate the figures and tables presented in:

Treg cells maintain regulatory signature in Th2 inflammation despite
destabilized Foxp3.  
Bonelli M*, Davis FP*, Mikami Y*, et al., 2018.  

Contact fred.davis@nih.gov with any questions.

## Package contents

- src - code, organized by language, to turn RNA-seq read files into figures.
- metadata - text tables describing genomic samples
- data - data files used by code

## Requirements

### Data

The data used by this package comes from several sources. We include nearly all
data files expected by the R and slurm shell programs, along with README files
describing the contents. The only exceptions are large files (eg, genome
sequence, gene annotations, transcript sequences, RNA-seq alignment indices),
which we do not provide but describe in README files how to obtain or build.

| Data                                  | Source                                                                                                                 |
|---------------------------------------|------------------------------------------------------------------------------------------------------------------------|
| FASTQ (this study)                    | [GEO GSE121731](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE121731)                                          |
| FASTQ (Shih 2016)                     | [GEO GSM2056312](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM2056312)                                        |
| FASTQ (Shih 2016)                     | [GEO GSM2056326](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM2056326)                                        |
| genome sequence, gene structure       | [ENSEMBL release 82; based on GRCm38 (mm10)](http://sep2015.archive.ensembl.org/Mus_musculus/Info/Index)               |
| genome sequence                       | [UCSC mm10 genome sequence](http://hgdownload.soe.ucsc.edu/goldenPath/mm10/bigZips/chromFa.tar.gz)                     |
| bowtie2 alignment index               | [iGenomes mm10](https://support.illumina.com/sequencing/sequencing_software/igenome.html)                              |
| genome sequence, gene structure       | [refdata-cellranger-1.2.0](http://cf.10xgenomics.com/supp/cell-exp/refdata-cellranger-mm10-1.2.0.tar.gz)               |
| Treg gene signature                   | [Dispiro et al., 2018. Supplementary Table 1](http://dx.doi.org/10.1126/sciimmunol.aat5861)                            |


### Software

We used the following software on the [NIH Biowulf](https://hpc.nih.gov)
slurm-based linux cluster.

| ATAC | ChIP | RNA* |  Software              |  Source                                                                                                         |
|------|------|------|------------------------|-----------------------------------------------------------------------------------------------------------------|
|  x   |      |      | samtools 1.6           | http://broadinstitute.github.io/picard/                                                                         |
|  x   |      |      | NGmerge v0.2           | https://github.com/jsh58/NGmerge                                                                                |
|  x   |      |      | MACS 2.1.1.20160309    | https://github.com/taoliu/MACS                                                                                  |
|  x   |      |      | picard 1.119           | http://broadinstitute.github.io/picard/                                                                         |
|  x   |      |      | bowtie 2.3.4           | http://bowtie-bio.sourceforge.net/bowtie2/index.shtml                                                           |
|  x   |      |      | samtools 1.6           | http://www.htslib.org/                                                                                          |
|  x   |      |  n   | bedtools 2.19.1        | https://bedtools.readthedocs.io/en/latest/                                                                      |
|  x   |  x   |  n   | ucsc                   | http://genomewiki.ucsc.edu/index.php/Kent_source_utilities                                                      |
|      |  x   |      | MACS 2.1.0.20150420    | https://github.com/taoliu/MACS                                                                                  |
|      |  x   |      | bowtie 1.1.2           | http://bowtie-bio.sourceforge.net/index.shtml                                                                   |
|      |  x   |      | bedtools 2.24.0        | https://bedtools.readthedocs.io/en/latest/                                                                      |
|      |  x   |      | samtools 1.2           | http://www.htslib.org/                                                                                          |
|      |  x   |  n   | deeptools 2.5.0.1      | https://deeptools.readthedocs.io/                                                                               |
|      |      |  n   | trimmomatic 0.36       | http://www.usadellab.org/cms/?page=trimmomatic                                                                  |
|      |      | b,n  | kallisto 0.42.4        | https://pachterlab.github.io/kallisto/                                                                          |
|      |      |  n   | STAR 2.5.4a            | https://github.com/alexdobin/STAR                                                                               |
|      |      |  n   | samtools 0.1.19        | http://www.htslib.org/                                                                                          |
|      |      |  b   | kallisto 0.43.0        | https://pachterlab.github.io/kallisto/                                                                          |
|      |      |  s   | cellranger 2.0.2       | https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/what-is-cell-ranger       |
|      |  x   | b,n,s| R v3.5.0               | https://www.r-project.org/                                                                                      |

* RNA: b=bulk, n=nascent, s = single cell

## Raw data processing

The analysis includes processing the RNA-seq (bulk, nascent, and single cell),
ATAC-seq, ChIP-seq reads and then generating figures and tables.

The data processing steps are implemented in shell scripts submitted to a slurm
linux cluster using the sbatch command.

### 1. bulk RNA-seq

This step pseudo-aligns bulk RNA-seq reads to the transcriptome.

```sh
sbatch bulkrnaseq_quantify_kallisto.slurm.sh
```

### 2. nascent RNA-seq

This step trims the first three nucleotides off of nascent RNA-seq reads, aligns
trimmed reads to the transcriptome for abundance estimation and to the genome
for visualization.

```sh
sbatch nascent_rnaseq_trim_quantify_kallisto.slurm.sh
sbatch nascent_rnaseq_align_STAR.slurm.sh
```

### 3. single cell RNA-seq

This step begins with demultiplexed 10x chromium FASTQ reads (generated with
`cellranger mkfastq`), and aligns these to a custom transcriptome that includes
the eGFP reporter sequence.

```sh
sbatch scrna_cellranger_count.slurm.sh
sbatch scrna_cellranger_aggr.slurm.sh
```

### 4. ATAC-seq

This step trims adapters from ATAC-seq FASTQ reads, aligns them to the genome,
calls peaks using sub-nucleosomal reads, and creates tracks for visualization.

```sh
sbatch atac_process_samples.slurm.csh
```

### 5. ChIP-seq

This step aligns ChIP-seq reads to the genome, creates tracks for visualization,
calls peaks, and summarizes coverage across 1kb-genomics windows.

```sh
sbatch chip_align_step1.sbatch.sh
sbatch chip_viz_step2.slurm.sh
sbatch chip_peaks_step3.slurm.sh
sbatch chip_summarize_step4.slurm.sh
```

## Generating figures and tables

An R script generates all the tables and figures in the manuscript.

```R
source("../../src/R/src/R/analyzeExFoxp3Seq.R")
dat <- paperRun(returnData=TRUE)
tx <- makePaperFigures(dat)
```
