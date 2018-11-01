#!/bin/csh -v
#SBATCH --cpus-per-task=8
#SBATCH --ntasks-per-core=1
#SBATCH --mem=30g
#SBATCH -o slurm_out/chip_peaks_step3.%A.%a.out
#SBATCH -e slurm_out/chip_peaks_step3.%A.%a.err
#SBATCH --time=8:00:00
#SBATCH --gres=lscratch:200
#SBATCH --array=1-10

set NUMCPU=8
set SCRATCHDIR="/lscratch/$SLURM_JOBID"
set BASEDIR="/data/davisfp/projects/exfoxp3"

set SAMPLEINFO_FN="$BASEDIR/metadata/exfoxp3_chip_samples.txt"
set SAMPLE_OPTION="dataType ChIP-seq"
#set SAMPLE_OPTION="dataType2 ChIP_K27m3"
#set SAMPLE_OPTION="flowcell wei2011"

# Module load
module load bedtools/2.24.0;            set BEDTOOLS_BIN="bedtools"
module load macs/2.1.0.20150420;        set MACS2_BIN="macs2"
module load java/1.8.0_11;              set JAVA_BIN="java"
module load samtools/1.2
module load R


set SRCDIR="$BASEDIR/src"
set flowcells=( `perl $SRCDIR/perl/txt2tasklist.pl $SAMPLEINFO_FN flowcell $SAMPLE_OPTION` )
set names=( `perl $SRCDIR/perl/txt2tasklist.pl $SAMPLEINFO_FN sampleName $SAMPLE_OPTION` )
set details=( `perl $SRCDIR/perl/txt2tasklist.pl $SAMPLEINFO_FN dataType2 $SAMPLE_OPTION` )
set input_flowcells=( `perl $SRCDIR/perl/txt2tasklist.pl $SAMPLEINFO_FN inputFlowcell $SAMPLE_OPTION` )
set input_names=( `perl $SRCDIR/perl/txt2tasklist.pl $SAMPLEINFO_FN inputSampleName $SAMPLE_OPTION` )

set FLOWCELL=$flowcells[$SLURM_ARRAY_TASK_ID]
set NAME=$names[$SLURM_ARRAY_TASK_ID]
set DETAIL=$details[$SLURM_ARRAY_TASK_ID]
set INPUT_FLOWCELL=$input_flowcells[$SLURM_ARRAY_TASK_ID]
set INPUT_NAME=$input_names[$SLURM_ARRAY_TASK_ID]

set ROSE_SRC_DIR="/data/davisfp/software/ROSE/young_computation-rose-1a9bb86b5464"


#No peak calling if input
if ($DETAIL == "ChIP_input") then
   exit
endif


### SETUP DIRECTORIES
set TRACK_DIR="$BASEDIR/results/ChIPseq.mm10/tracks/$FLOWCELL"
set INPUT_TRACK_DIR="$BASEDIR/results/ChIPseq.mm10/tracks/$INPUT_FLOWCELL"

set MACS2_OUTBASEDIR="$BASEDIR/results/ChIPseq.mm10/macs2/$FLOWCELL/$NAME"
set MACS2_OUTDIR="$MACS2_OUTBASEDIR"

set ROSE_OUTDIR="$BASEDIR/results/ChIPseq.mm10/ROSE/$FLOWCELL/$NAME"

foreach T_OUTDIR ( $MACS2_OUTDIR $ROSE_OUTDIR )
   if (! -e $T_OUTDIR) then
      mkdir -p $T_OUTDIR
   endif
end


## INPUT FILES
set BAM_FN_BASE="${NAME}.bam"
set INPUT_BAM_BASE="${INPUT_NAME}.bam"

set BAM_FN="$TRACK_DIR/$BAM_FN_BASE"
set INPUT_BAM="$INPUT_TRACK_DIR/$INPUT_BAM_BASE"


set GENOMEFASTA_DIR="/fdb/genome/mm10"



## SET MACS2 OPTIONS
set MACS2_OPTIONS="callpeak -t $BAM_FN -f BAM -g mm -n $NAME -B -q 0.01 --outdir $MACS2_OUTDIR"
set MACS2_OUTBED="$MACS2_OUTDIR/${NAME}_peaks.narrowPeak"
set MACS2_OUTGFF="$MACS2_OUTDIR/${NAME}_peaks.gff"


## SET GFP as ctrl track
if ($INPUT_NAME != "NA") then
   set MACS2_OPTIONS="$MACS2_OPTIONS -c $INPUT_BAM"
endif


### START THE RUN
set curdir=`pwd`
set curhost=`hostname`
set curtime=`date`
echo "#SLURM run started on $curhost at $curtime"
echo "#scratchdir = $SCRATCHDIR"

cd $SCRATCHDIR

set curtime=`date`

if (! -e $MACS2_OUTBED) then
   set curtime=`date`
   echo "#$MACS2_BIN $MACS2_OPTIONS ($curtime)"
   $MACS2_BIN $MACS2_OPTIONS

#Convert to GFF for ROSE input
#   chr1    4807798 4807941 IFNgKO.mCD4.ChIP_STAT1.IFNg_60min_peak_1        61      .       4.77679 9.30546 6.13247 105

   cat $MACS2_OUTBED | awk '{OFS="\t"; print $1, $4, "macs_peak", $2,$3,".",".",".",$4}' > $MACS2_OUTGFF

endif


if (! -e "${ROSE_OUTDIR}/gff") then
   cp $BAM_FN $SCRATCHDIR
   cp ${BAM_FN}.bai $SCRATCHDIR
   cd $SCRATCHDIR

   cp -r $ROSE_SRC_DIR/* .

   if ($INPUT_NAME != "NA") then
      cp $INPUT_BAM $SCRATCHDIR
      cp ${INPUT_BAM}.bai $SCRATCHDIR
      python ROSE_main.py -g mm9 -i $MACS2_OUTGFF -r $BAM_FN_BASE -c $INPUT_BAM_BASE -o OUT
   endif

   if ($INPUT_NAME == "NA") then
      python ROSE_main.py -g mm9 -i $MACS2_OUTGFF -r $BAM_FN_BASE -o OUT
   endif

   cp -r OUT/* $ROSE_OUTDIR
   cd $curdir
endif

set curtime=`date`
echo "#SLURM run finished on $curhost at $curtime"
