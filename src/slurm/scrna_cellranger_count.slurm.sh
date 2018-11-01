#!/bin/csh -v
#SBATCH --cpus-per-task=16
#SBATCH --ntasks-per-core=1
#SBATCH --mem=64g
#SBATCH -o slurm_out/cellranger_count_parallel_try2.%A.%a.out
#SBATCH -e slurm_out/cellranger_count_parallel_try2.%A.%a.err
#SBATCH --time=9-00:00:00
#SBATCH --gres=lscratch:200


set NUMJOBS_PER_CELLRANGER_TASK=100
set BASEDIR="/data/davisfp/projects/exfoxp3"
set SAMPLEINFO_FN="$BASEDIR/data/exfoxp3_rna_samples.txt"
set SAMPLE_OPTION="libraryType chromium"

echo "perl $BASEDIR/src/perl/txt2tasklist.pl $SAMPLEINFO_FN sampleName $SAMPLE_OPTION"
set names=( `perl $BASEDIR/src/perl/txt2tasklist.pl $SAMPLEINFO_FN sampleName $SAMPLE_OPTION` )
set barcodes=( `perl $BASEDIR/src/perl/txt2tasklist.pl $SAMPLEINFO_FN chromiumBarcode $SAMPLE_OPTION` )
set samplenums=`perl $BASEDIR/src/perl/txt2tasklist.pl $SAMPLEINFO_FN chromiumSampleNum $SAMPLE_OPTION`
set chromiumRefs=`perl $BASEDIR/src/perl/txt2tasklist.pl $SAMPLEINFO_FN chromiumRef $SAMPLE_OPTION`
set runids=`perl $BASEDIR/src/perl/txt2tasklist.pl $SAMPLEINFO_FN runID $SAMPLE_OPTION`
set runbatches=`perl $BASEDIR/src/perl/txt2tasklist.pl $SAMPLEINFO_FN runID $SAMPLE_OPTION`
set numsamples=`perl $BASEDIR/src/perl/txt2tasklist.pl $SAMPLEINFO_FN samplecount $SAMPLE_OPTION`


if ( ! ( $?SLURM_ARRAY_TASK_ID)  ) then
   echo "# NOTE: controller node for job $SLURM_JOBID sample_option $SAMPLE_OPTION"

   foreach subtask_id ( `seq 1 $numsamples` )
      set curtime=`date`
      echo "Submitting: sbatch --array $subtask_id $SLURM_JOB_NAME ($curtime)"
      sbatch --array $subtask_id $SLURM_JOB_NAME
   end

   exit
endif


module load cellranger/2.0.0

set BARCODE=$barcodes[$SLURM_ARRAY_TASK_ID]
set SAMPLENAME=$names[$SLURM_ARRAY_TASK_ID]
set SAMPLENUM=$samplenums[$SLURM_ARRAY_TASK_ID]
set RUNID=$runids[$SLURM_ARRAY_TASK_ID]

set CHROMIUMREF=$chromiumRefs[$SLURM_ARRAY_TASK_ID]
set REFDIR="${BASEDIR}/data/cellranger_files.v2.0.0/reference/${CHROMIUMREF}/${CHROMIUMREF}"

set OUTDIR="${BASEDIR}/results/RNAseq/crcount.2.0.0_parallel/${SAMPLENAME}"

set curdir=`pwd`
set curhost=`hostname`
set curtime=`date`
echo "#sgejob run started on $curhost at $curtime"
echo "# Processing: $SAMPLENAME" ;

foreach T_OUTDIR ( $OUTDIR )
   if (! -e $T_OUTDIR) then
      echo "mkdir -p $T_OUTDIR"
      mkdir -p $T_OUTDIR
   endif
end

set FQDIR="${BASEDIR}/data/fastq/${RUNID}"

cd $OUTDIR
cellranger count --id $SAMPLENAME \
   --fastqs $FQDIR \
   --sample $SAMPLENUM \
   --transcriptome $REFDIR \
   --localmem 62 \
   --jobmode=slurm \
   --maxjobs=$NUMJOBS_PER_CELLRANGER_TASK


set curtime=`date`
echo "#slurm run finished on $curhost at $curtime"

exit
