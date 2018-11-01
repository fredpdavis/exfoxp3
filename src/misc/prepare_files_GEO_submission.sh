# Prepare datasets for GEO submission


## ChIP: fastq
sed 1d ../metadata/bonelli_ms_chip_samples.txt | awk -F"\t" '{print "ln -s ../data/fastq/"$1"/"$2" "$9".fastq.gz"}'

## ChIP: bw
sed 1d ../metadata/bonelli_ms_chip_samples.txt | awk -F"\t" '{print "ln -s ../results/ChIPseq.mm10/tracks/"$1"/"$4"_scaled10M.bw "$9"_scaled10M.bw"}'

## ChIP: peaks (only foxp3)
sed 1d ../metadata/bonelli_ms_chip_samples.txt | grep Foxp3 | awk -F"\t" '{print "ln -s ../results/ChIPseq.mm10/macs2/"$1"/"$4"/"$4"_peaks.narrowPeak "$9"_narrowPeaks.bed"}'


## bulk, nascent RNA: FASTQ
sed 1d ../metadata/bonelli_ms_rna_samples.txt | grep -v chromium | awk -F"\t" '{print "ln -s ../data/fastq/"$1"/"$2" "$16".fastq.gz"}' 


## Nascent RNA: BW
sed 1d ../metadata/bonelli_ms_rna_samples.txt | grep nascent | awk -F"\t" '{print "ln -s ../results/RNAseq/STAR/"$1"/"$4"/"$4".star_fwd.bw "$16".star_fwd.bw"}'
sed 1d ../metadata/bonelli_ms_rna_samples.txt | grep nascent | awk -F"\t" '{print "ln -s ../results/RNAseq/STAR/"$1"/"$4"/"$4".star_rev.bw "$16".star_rev.bw"}'


## scRNA: BAM
sed 1d ../metadata/bonelli_ms_rna_samples.txt | grep chromium | awk -F"\t" '{print "ln -s ../results/RNAseq/crcount.2.0.0_parallel/"$4"/"$4"/outs/possorted_genome_bam.bam "$16".possorted_genome_bam.bam"}'

## scRNA: FASTQ
#sed 1d ../metadata/bonelli_ms_rna_samples.txt | grep chromium |  awk -F"\t" '{n=split($2, fastqs, ","); for (x in fastqs) {print "ln -s ../data/fastq/"$1"/"fastqs[x]"_I1_001.fastq.gz "$16"."fastqs[x]"_I1_001.fastq.gz"}}' | bash
#sed 1d ../metadata/bonelli_ms_rna_samples.txt | grep chromium |  awk -F"\t" '{n=split($2, fastqs, ","); for (x in fastqs) {print "ln -s ../data/fastq/"$1"/"fastqs[x]"_R1_001.fastq.gz "$16"."fastqs[x]"_R1_001.fastq.gz"}}' | bash
#sed 1d ../metadata/bonelli_ms_rna_samples.txt | grep chromium |  awk -F"\t" '{n=split($2, fastqs, ","); for (x in fastqs) {print "ln -s ../data/fastq/"$1"/"fastqs[x]"_R2_001.fastq.gz "$16"."fastqs[x]"_R2_001.fastq.gz"}}' | bash
#

gtip < ../run/20180708.reaggr_bulk_treg/trth2_sc201807/outs/filtered_gene_bc_matrices_mex/mm10_egfp/barcodes.tsv > scrna_barcodes.tsv.gz
gzip < ../run/20180708.reaggr_bulk_treg/trth2_sc201807/outs/filtered_gene_bc_matrices_mex/mm10_egfp/genes.tsv > scrna_genes.tsv.gz
gzip < ../run/20180708.reaggr_bulk_treg/trth2_sc201807/outs/filtered_gene_bc_matrices_mex/mm10_egfp/matrix.mtx > scrna_matrix.mtx.gz


awk -F"\t" '{print "ln -s ../results/RNAseq/crcount.2.0.0_parallel/"$4"/"$4"/outs/possorted_genome_bam.bam "$16".possorted_genome_bam.bam"}'

## ATAC: FASTQ
sed 1d ../metadata/bonelli_ms_atac_samples.txt | grep -v GSM| awk '{print "ln -s ../data/fastq/"$2"/"$3"_r1.fq.gz "$6"_read1.fastq.gz"}'
sed 1d ../metadata/bonelli_ms_atac_samples.txt | grep -v GSM| awk '{print "ln -s ../data/fastq/"$2"/"$3"_r2.fq.gz "$6"_read2.fastq.gz"}'

## ATAC: BW
sed 1d ../metadata/bonelli_ms_atac_samples.txt | grep -v GSM| awk '{print "ln -s ../results/ATACseq/macs2_peaks/"$1"/"$4".sub100_macs.bw "$6".sub100_macs.bw"}'


