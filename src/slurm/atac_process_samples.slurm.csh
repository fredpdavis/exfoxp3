#!/bin/csh -v
#SBATCH --cpus-per-task=6
#SBATCH --ntasks-per-core=1
#SBATCH --mem=32g
#SBATCH -o slurm_out/process_atac.%A.%a.out
#SBATCH -e slurm_out/process_atac.%A.%a.err
#SBATCH --time=20:00:00
#SBATCH --gres=lscratch:200
#SBATCH --array=1-7


set NUMCPU=4
set scratchdir="/lscratch/$SLURM_JOBID" #should alredy be there.

module load samtools/1.6
module load macs/2.1.1.20160309
module load picard/1.119
module load bowtie/2-2.3.4
module load bedtools/2.19.1
module load ucsc

set origdir=`pwd`
set curhost=`hostname`

mkdir -p $scratchdir
cd $scratchdir


## SET FILE PATHS AND OPTIONS

set BASEDIR="/data/davisfp/projects/exfoxp3"
set PERLDIR="$BASEDIR/src/perl"
set SWDIR="/data/davisfp/software"
set SAMPLEINFO_FN="$BASEDIR/metadata/exfoxp3_atac_samples.txt"
set CHROMSIZE="$BASEDIR/data/misc/mm10_chromsize/mm10_chromsize.tab"

set sampleids=( `perl $PERLDIR/txt2tasklist.pl $SAMPLEINFO_FN sampleID` )
set fastqbases=( `perl $PERLDIR/txt2tasklist.pl $SAMPLEINFO_FN fastqBase` )
set samplenames=( `perl $PERLDIR/txt2tasklist.pl $SAMPLEINFO_FN sampleName` )
set flowcells=( `perl $PERLDIR/txt2tasklist.pl $SAMPLEINFO_FN flowcell` )

set SAMPLEID=$sampleids[$SLURM_ARRAY_TASK_ID]
set FASTQBASE=$fastqbases[$SLURM_ARRAY_TASK_ID]
set SAMPLE_NAME=$samplenames[$SLURM_ARRAY_TASK_ID]
set FLOWCELL=$flowcells[$SLURM_ARRAY_TASK_ID]

set FASTQ1_FN="$BASEDIR/data/fastq/$FLOWCELL/${FASTQBASE}_r1.fq.gz"
set FASTQ2_FN="$BASEDIR/data/fastq/$FLOWCELL/${FASTQBASE}_r2.fq.gz"


## STEP OPTIONS / FILE/PATH specification

### BINARY PATHS
set NGMERGE_BIN="$SWDIR/NGmerge/NGmerge-0.2/NGmerge"
set BOWTIE2_BIN="bowtie2"
set SAMTOOLS_BIN="samtools"
set MACS2_BIN="macs2"
set PICARDDEDUP_BIN="java -Xmx30g -jar $PICARDJARPATH/MarkDuplicates.jar"

### INPUT FILES
set BOWTIE2_INDEX="$BASEDIR/data/bowtie2_files/Bowtie2Index/genome"

### OUTPUT DIRECTORIES
set TRIM_OUTDIR="$BASEDIR/results/ATACseq/trim_reads/$SAMPLEID"
set BOWTIE2_OUTDIR="$BASEDIR/results/ATACseq/bowtie2/$SAMPLEID"
set PICARDDEDUP_OUTDIR="$BASEDIR/results/ATACseq/dedup/$SAMPLEID"
set MACS2_OUTDIR="$BASEDIR/results/ATACseq/macs2_peaks/$SAMPLEID"
set BED_OUTDIR="$BASEDIR/results/ATACseq/bed_files/$SAMPLEID"

### OUTPUT FILES

set TRIMFASTQ_BASE="$TRIM_OUTDIR/${SAMPLE_NAME}_trim"
set TRIMFASTQ1="${TRIMFASTQ_BASE}_1.fastq.gz"
set TRIMFASTQ2="${TRIMFASTQ_BASE}_2.fastq.gz"
set ORIGBAM_FN="${BOWTIE2_OUTDIR}/$SAMPLE_NAME.orig.bam"
set ORIGBAM_NOMITO_FN="${BOWTIE2_OUTDIR}/$SAMPLE_NAME.nomito.bam"
set DEDUPBAM_FN="${PICARDDEDUP_OUTDIR}/$SAMPLE_NAME.dedup.bam"
set PICARDDEDUP_OUT_FN="${PICARDDEDUP_OUTDIR}/${SAMPLE_NAME}.dedup.txt"

set BED_UNSORT_FN="${BED_OUTDIR}/${SAMPLE_NAME}.shifted.unsorted.bed"
set BED_FN="${BED_OUTDIR}/${SAMPLE_NAME}.bed"
set BED_SUB100_FN="${BED_OUTDIR}/${SAMPLE_NAME}.sub100.bed"
set BED_SUP150_FN="${BED_OUTDIR}/${SAMPLE_NAME}.sup150.bed"


set MACS2_SUB100_TREAT_BG="${MACS2_OUTDIR}/${SAMPLE_NAME}.sub100_treat_pileup.bdg"
set SORT_MACS2_SUB100_BG="${MACS2_OUTDIR}/${SAMPLE_NAME}.sub100_treat_pileup.sorted.bdg"
set MACS2_SUB100_BW="${MACS2_OUTDIR}/${SAMPLE_NAME}.sub100_macs.bw"

set MACS2_FULL_TREAT_BG="${MACS2_OUTDIR}/${SAMPLE_NAME}.full_treat_pileup.bdg"
set SORT_MACS2_FULL_BG="${MACS2_OUTDIR}/${SAMPLE_NAME}.full_treat_pileup.sorted.bdg"
set MACS2_FULL_BW="${MACS2_OUTDIR}/${SAMPLE_NAME}.full_macs.bw"

## STEP 0. MAKE SURE FASTQ FILES EXISTS

if (! -e $FASTQ1_FN ) then
   echo "FATAL ERROR: FASTQ file not found: $FASTQ1_FN"
   exit;
endif

if (! -e $FASTQ2_FN ) then
   echo "FATAL ERROR: FASTQ file not found: $FASTQ2_FN"
   exit;
endif


### STEP 1. TRIM
set NGMERGE_OPTIONS="-a -u 41 -1 $FASTQ1_FN -2 $FASTQ2_FN -z -o $TRIMFASTQ_BASE"

### STEP 2. READ ALIGNMENT
set BOWTIE2_OPTIONS="--very-sensitive -p $NUMCPU -x $BOWTIE2_INDEX -1 $TRIMFASTQ1 -2 $TRIMFASTQ2"

### STEP 3. DE-DUPLICATE
set PICARDDEDUP_OPTIONS="I=$ORIGBAM_NOMITO_FN O=$DEDUPBAM_FN M=$PICARDDEDUP_OUT_FN REMOVE_DUPLICATES=TRUE"

### STEP 4. CALL PEAKS
set MACS2_OPTIONS_FULL="callpeak -B --SPMR -t $BED_FN -f BEDPE -g mm --keep-dup all --outdir $MACS2_OUTDIR -n ${SAMPLE_NAME}.full"
set MACS2_OPTIONS_SUB100="callpeak -B --SPMR -t $BED_SUB100_FN -f BEDPE -g mm --keep-dup all --outdir $MACS2_OUTDIR -n ${SAMPLE_NAME}.sub100"

## SETUP NECESSARY DIRECTORIES

foreach T_OUTDIR ( $TRIM_OUTDIR $BOWTIE2_OUTDIR $PICARDDEDUP_OUTDIR $MACS2_OUTDIR $BED_OUTDIR )
   if (! -e $T_OUTDIR) then
      mkdir -p $T_OUTDIR
   endif
end



set curtime=`date`
echo "# cluster run started on $curhost at $curtime"
echo "# Processing: $SAMPLEID ($SAMPLE_NAME)" ;

set echo

set curtime=`date`
echo "# STEP 1. ADAPTOR TRIMMING ($curtime)"
$NGMERGE_BIN $NGMERGE_OPTIONS

set curtime=`date`
echo "# STEP 2. READ ALIGNMENT ($curtime)"
$BOWTIE2_BIN $BOWTIE2_OPTIONS | $SAMTOOLS_BIN view -u - | $SAMTOOLS_BIN sort - > $ORIGBAM_FN

echo "# STEP 2B. REMOVE chrM ALIGNMENTS ($curtime)"
$SAMTOOLS_BIN index $ORIGBAM_FN
$SAMTOOLS_BIN idxstats $ORIGBAM_FN | cut -f 1 | grep -v chrM | xargs $SAMTOOLS_BIN view -b $ORIGBAM_FN > $ORIGBAM_NOMITO_FN

set curtime=`date`
echo "# STEP 3. DE-DUPLICATE ($curtime)"
$PICARDDEDUP_BIN $PICARDDEDUP_OPTIONS

set curtime=`date`
echo "# STEP 4. CALL PEAKS ($curtime)"
$SAMTOOLS_BIN view -bf 0x2 $DEDUPBAM_FN | $SAMTOOLS_BIN sort -@$NUMCPU -n - | bedtools bamtobed -bedpe -i stdin | cut -f 1,2,6 | awk 'BEGIN{OFS="\t"} {print $1, ($2 + 4), ($3 - 4)}' > $BED_UNSORT_FN
sort -T $scratchdir -k1,1 -k2,2n -k3,3n $BED_UNSORT_FN > $BED_FN
awk '{if (($3 - $2) < 100) print}' $BED_FN > $BED_SUB100_FN
awk '{if (($3 - $2) >= 150) print}' $BED_FN > $BED_SUP150_FN
$MACS2_BIN $MACS2_OPTIONS_FULL
$MACS2_BIN $MACS2_OPTIONS_SUB100

sort -k1,1 -k2,2n $MACS2_SUB100_TREAT_BG > $SORT_MACS2_SUB100_BG
bedGraphToBigWig $SORT_MACS2_SUB100_BG $CHROMSIZE $MACS2_SUB100_BW

sort -k1,1 -k2,2n $MACS2_FULL_TREAT_BG > $SORT_MACS2_FULL_BG
bedGraphToBigWig $SORT_MACS2_FULL_BG $CHROMSIZE $MACS2_FULL_BW
             
## STEP 5. CLEANUP

set curtime=`date`
echo "# STEP 5. Cleaning up ($curtime)"

cd $origdir
rm $TRIMFASTQ1
rm $TRIMFASTQ2
rm $ORIGBAM_FN
rm $ORIGBAM_NOMITO_FN
rm $SORT_MACS2_SUB100_BG
rm $SORT_MACS2_FULL_BG
rm -rf $scratchdir

set curtime=`date`
echo "#cluster run finished on $curhost at $curtime"
