#!/bin/csh -v
#SBATCH --cpus-per-task=4
#SBATCH --ntasks-per-core=1
#SBATCH --mem=8g
#SBATCH -o slurm_out/chip_align_step1.%A.%a.out
#SBATCH -e slurm_out/chip_align_step1.%A.%a.err
#SBATCH --time=6:00:00
#SBATCH --gres=lscratch:200
#SBATCH --array=1-10


set NUMCPU=4
set SCRATCHDIR="/lscratch/$SLURM_JOBID" #should alredy be there.

# Module load
module load bowtie/1.1.2
module load samtools/1.2

# Set binary names
set BOWTIE_BIN="bowtie"
set SAMTOOLS_BIN="samtools"

# Print version number
$BOWTIE_BIN --version; echo
$SAMTOOLS_BIN --version; echo


set BASEDIR="/data/davisfp/projects/exfoxp3"
set SRCDIR="$BASEDIR/src"

set SAMPLEINFO_FN="$BASEDIR/metadata/exfoxp3_chip_samples.txt"
set SAMPLE_OPTION="dataType ChIP-seq"
#set SAMPLE_OPTION="dataType2 ChIP_K27m3"
#set SAMPLE_OPTION="flowcell wei2011"


set flowcells=( `perl $SRCDIR/perl/txt2tasklist.pl $SAMPLEINFO_FN flowcell $SAMPLE_OPTION` )
set names=( `perl $SRCDIR/perl/txt2tasklist.pl $SAMPLEINFO_FN sampleName $SAMPLE_OPTION` )
set fastqs=( `perl $SRCDIR/perl/txt2tasklist.pl $SAMPLEINFO_FN FASTQ $SAMPLE_OPTION` )

set FLOWCELL=$flowcells[$SLURM_ARRAY_TASK_ID]
set NAME=$names[$SLURM_ARRAY_TASK_ID]
set FASTQ=$fastqs[$SLURM_ARRAY_TASK_ID]

set FASTQF_DIR="$BASEDIR/data/fastq/$FLOWCELL"
set FASTQF="$FASTQF_DIR/$FASTQ"



set COMPRESS_TYPE="gz"
if ("$FASTQF" =~ "*.bz2") then
   set COMPRESS_TYPE="bz"
endif


set SAMF="$SCRATCHDIR/${NAME}.sam"


set BOWTIE_OPTIONS="-S -t -p $NUMCPU -m 1"
set BOWTIE_INDEX="$BASEDIR/data/external/bowtie_index/mm10_genome"

set TRACK_DIR="$BASEDIR/results/ChIPseq.mm10/tracks/$FLOWCELL"
set BAM_UNSORT_FN="$TRACK_DIR/{$NAME}.unsorted.bam"
set BAM_FN_NOSUFFIX="$TRACK_DIR/{$NAME}"
set BAM_FN="$TRACK_DIR/{$NAME}.bam"
set BAI_FN="$TRACK_DIR/{$NAME}.bam.bai"


foreach T_OUTDIR ( $TRACK_DIR )
   if (! -e $T_OUTDIR) then
      mkdir -p $T_OUTDIR
   endif
end


set curdir=`pwd`
set curhost=`hostname`
set curtime=`date`
echo "#SLURM run started on $curhost at $curtime"

if (! -e $SAMF) then
if ($COMPRESS_TYPE == "gz") then
   echo "# command line: gzip -dc $FASTQF | $BOWTIE_BIN $BOWTIE_OPTIONS $BOWTIE_INDEX - $SAMF"
   gzip -dc $FASTQF | $BOWTIE_BIN $BOWTIE_OPTIONS $BOWTIE_INDEX - $SAMF
else
   echo "# command line: bzip2 -dc $FASTQF | $BOWTIE_BIN $BOWTIE_OPTIONS $BOWTIE_INDEX - $SAMF"
   bzip2 -dc $FASTQF | $BOWTIE_BIN $BOWTIE_OPTIONS $BOWTIE_INDEX - $SAMF
endif
endif

if (! -e $BAM_FN) then

   if (! -e $BAM_UNSORT_FN) then
      echo "#Converting SAM to BAM ($curtime)"
      echo "$SAMTOOLS_BIN view -b -@ $NUMCPU -S $SAMF -o $BAM_UNSORT_FN"
      $SAMTOOLS_BIN view -b -@ $NUMCPU -S $SAMF -o $BAM_UNSORT_FN
      echo
   endif

   set curtime=`date`
   echo "#Sorting BAM ($curtime)"
   echo "$SAMTOOLS_BIN sort -@ $NUMCPU $BAM_UNSORT_FN $BAM_FN_NOSUFFIX"
   $SAMTOOLS_BIN sort -@ $NUMCPU $BAM_UNSORT_FN $BAM_FN_NOSUFFIX
   echo
endif
echo "BAM FILE IS $BAM_FN"

if (! -e $BAI_FN) then
   set curtime=`date`
   echo "$SAMTOOLS_BIN index $BAM_FN ($curtime)"
   $SAMTOOLS_BIN index $BAM_FN
endif


set curtime=`date`
echo "#SLURM run finished on $curhost at $curtime"
