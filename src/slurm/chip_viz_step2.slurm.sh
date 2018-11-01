#!/bin/csh -v
#SBATCH --cpus-per-task=2
#SBATCH --ntasks-per-core=1
#SBATCH --mem=40g
#SBATCH -o slurm_out/chip_viz_step2.%A.%a.out
#SBATCH -e slurm_out/chip_viz_step2.%A.%a.err
#SBATCH --time=8:00:00
#SBATCH --gres=lscratch:200
#SBATCH --array=1-10

set NUMCPU=2
set SCRATCHDIR="/lscratch/$SLURM_JOBID"

set BASEDIR="/data/davisfp/projects/exfoxp3"
set SAMPLEINFO_FN="$BASEDIR/metadata/exfoxp3_chip_samples.txt"
set SAMPLE_OPTION="dataType ChIP-seq"
#set SAMPLE_OPTION="dataType2 ChIP_K27m3"
#set SAMPLE_OPTION="flowcell wei2011"


# Module load
module load bedtools/2.24.0; set BEDTOOLS_BIN="bedtools"
module load samtools/1.2; set SAMTOOLS_BIN="samtools"
module load ucsc/314; set WIGTOBIGWIG_BIN="wigToBigWig"

# Print version number
$BEDTOOLS_BIN --version; echo
$SAMTOOLS_BIN --version; echo


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

## PROGRAM BINARIES
set SCALEBED_BIN="$SRCDIR/perl/scale_bed_rpm.pl"

## INPUT FILES
set CHROMSIZES_FN="$BASEDIR/data/misc/mm10_chromsize/mm10_chromsize.tab"

## OUTPUT FILES
set BAM_FN="$TRACK_DIR/${NAME}.bam"
set BED_UNSORT_FN="$SCRATCHDIR/${NAME}_unsort.bed"
set BED_FN="$SCRATCHDIR/${NAME}.bed"
set BED_3EXTEND_FN="$SCRATCHDIR/${NAME}-3extend.bed"
set SCALED10M_BED_FN="$SCRATCHDIR/${NAME}_scaled10M.bed"
set SCALED10M_BIGWIG_FN="$TRACK_DIR/${NAME}_scaled10M.bw"


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

if (! -e $BED_FN) then
   set curtime=`date`
   echo "#Converting to BED ($curtime)"
   echo "$BEDTOOLS_BIN bamtobed -i $BAM_FN > $BED_UNSORT_FN"
   $BEDTOOLS_BIN bamtobed -i $BAM_FN > $BED_UNSORT_FN
   sort -T $SCRATCHDIR -k1,1 -k2,2n -k3,3n $BED_UNSORT_FN > $BED_FN
   rm $BED_UNSORT_FN
   echo
endif

set curtime=`date`
set NUMALNS=`$SAMTOOLS_BIN flagstat $BAM_FN | grep -m 1 mapped | awk '{print $1}'`
echo "# Number of alignments: $NUMALNS"

# Create 10M-normalized genome-wide coverage track in bigwig format
if (! -e $SCALED10M_BIGWIG_FN) then
   set curtime=`date`
   echo "#Creating BigWig track of counts scaled to 10M alignments(=reads) ($curtime)"

   set READLEN=`${BEDTOOLS_BIN} bamtobed -i $BAM_FN | head -1 | awk -F"	" '{print $3 - $2 + 1}'`

   set curtime=`date`
   if ($READLEN < 200) then
      set EXTENDLEN=`${BEDTOOLS_BIN} bamtobed -i $BAM_FN | head -1 | awk -F"	" '{print (200 - ($3 - $2 + 1))}'`
      echo "#Extending BED to 3-prime direction by $EXTENDLEN nucleotides ($curtime)"
      echo "$BEDTOOLS_BIN slop -i $BED_FN -g $CHROMSIZES_FN -s -l 0 -r $EXTENDLEN > $BED_3EXTEND_FN"
      $BEDTOOLS_BIN slop -i $BED_FN -g $CHROMSIZES_FN -s -l 0 -r $EXTENDLEN > $BED_3EXTEND_FN
   else
      echo "#No need to extend reads, reads already $READLEN nt long ($curtime)"
      cp $BED_FN $BED_3EXTEND_FN
   endif

   set curtime=`date`
   echo "#Calculating read coverage ($curtime)"
   echo "$BEDTOOLS_BIN genomecov -bg -i $BED_3EXTEND_FN -g $CHROMSIZES_FN | perl $SCALEBED_BIN $NUMALNS 10000000 > $SCALED10M_BED_FN"
   $BEDTOOLS_BIN genomecov -bg -i $BED_3EXTEND_FN -g $CHROMSIZES_FN | perl $SCALEBED_BIN $NUMALNS 10000000 > $SCALED10M_BED_FN
   rm $BED_3EXTEND_FN
   echo

   echo "#Creating bw track ($curtime)"
   echo "$WIGTOBIGWIG_BIN -clip $SCALED10M_BED_FN $CHROMSIZES_FN $SCALED10M_BIGWIG_FN"
   $WIGTOBIGWIG_BIN -clip $SCALED10M_BED_FN $CHROMSIZES_FN $SCALED10M_BIGWIG_FN
   rm $SCALED10M_BED_FN
   echo
endif



set curtime=`date`
echo "#SLURM run finished on $curhost at $curtime"
