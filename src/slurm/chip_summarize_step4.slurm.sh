#!/bin/csh -v
#SBATCH --cpus-per-task=4
#SBATCH --ntasks-per-core=1
#SBATCH --mem=40g
#SBATCH -o slurm_out/chip_summarize_step4.%A.%a.out
#SBATCH -e slurm_out/chip_summarize_step4.%A.%a.err
#SBATCH --time=8:00:00
#SBATCH --gres=lscratch:200
#SBATCH --array=1-10

set NUMCPU=4
set SCRATCHDIR="/lscratch/$SLURM_JOBID"

set BASEDIR="/data/davisfp/projects/exfoxp3"
set SAMPLEINFO_FN="$BASEDIR/metadata/exfoxp3_chip_samples.txt"
set SAMPLE_OPTION="dataType ChIP-seq"

# Module load
module load deeptools

set SRCDIR="$BASEDIR/src"
set flowcells=( `perl $SRCDIR/perl/txt2tasklist.pl $SAMPLEINFO_FN flowcell $SAMPLE_OPTION` )
set names=( `perl $SRCDIR/perl/txt2tasklist.pl $SAMPLEINFO_FN sampleName $SAMPLE_OPTION` )
set details=( `perl $SRCDIR/perl/txt2tasklist.pl $SAMPLEINFO_FN dataType2 $SAMPLE_OPTION` )

set FLOWCELL=$flowcells[$SLURM_ARRAY_TASK_ID]
set NAME=$names[$SLURM_ARRAY_TASK_ID]
set DETAILS=$details[$SLURM_ARRAY_TASK_ID]


### SETUP DIRECTORIES
set TRACK_DIR="$BASEDIR/results/ChIPseq.mm10/tracks/$FLOWCELL"

foreach T_OUTDIR ( $TRACK_DIR )
   if (! -e $T_OUTDIR) then
      mkdir -p $T_OUTDIR
   endif
end


### SETUP FILES

## INPUT FILES
set SCALED10M_BIGWIG_FN="$TRACK_DIR/${NAME}_scaled10M.bw"

## OUTPUT FILES
set NPZ_OUT_FN="$TRACK_DIR/${NAME}_scaled10M.multibigwigsum_1kb.npz"
set RAWCT_OUT_FN="$TRACK_DIR/${NAME}_scaled10M.multibigwigsum_1kb.txt"
set RAWCT_SORT_OUT_FN="$TRACK_DIR/${NAME}_scaled10M.multibigwigsum_1kb.sorted.txt"


### START THE RUN
set curdir=`pwd`
set curhost=`hostname`
set curtime=`date`
echo "#SLURM run started on $curhost at $curtime"

echo "#SCRATCHDIR = $SCRATCHDIR"
cd $SCRATCHDIR

##---------- Step 1.
# 1a. BAM -> 3' extend to frag size -> calculate coverage histo -> unnormalized-bigWig

set curtime=`date`

# Create 10M-normalized genome-wide coverage track in bigwig format
if (-e $SCALED10M_BIGWIG_FN) then

   set curtime=`date`
   echo "# Creating multiBigwSummary ($curtime)"

   multiBigwigSummary bins --numberOfProcessors $NUMCPU --binSize 1000 -b $SCALED10M_BIGWIG_FN --outFileName $NPZ_OUT_FN --outRawCounts $RAWCT_OUT_FN -l $NAME
   sed 1d $RAWCT_OUT_FN | sort -k1,1 -k2,2n -k3,3n > $RAWCT_SORT_OUT_FN
   echo
endif



set curtime=`date`
echo "#SLURM run finished on $curhost at $curtime"
