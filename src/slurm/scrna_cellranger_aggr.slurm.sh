#!/bin/csh -v
#SBATCH --cpus-per-task=16
#SBATCH --ntasks-per-core=1
#SBATCH --mem=64g
#SBATCH -o slurm_out/cellranger_aggr.%A.%a.out
#SBATCH -e slurm_out/cellranger_aggr.%A.%a.err
#SBATCH --time=5-00:00:00
#SBATCH --gres=lscratch:200

module load cellranger/2.0.2

set curhost=`hostname`
set curtime=`date`
echo "#slurm run started on $curhost at $curtime"

echo "library_id,molecule_h5\
S015_WT_lung_Treg_ova_set2,/gpfs/gsfs7/users/davisfp/projects/exfoxp3/results/RNAseq/crcount.2.0.0_parallel/S015_WT_lung_Treg_ova_set2/S015_WT_lung_Treg_ova_set2/outs/molecule_info.h5\
S018_WT_lung_Treg_pbs_set2,/gpfs/gsfs7/users/davisfp/projects/exfoxp3/results/RNAseq/crcount.2.0.0_parallel/S018_WT_lung_Treg_pbs_set2/S018_WT_lung_Treg_pbs_set2/outs/molecule_info.h5\
WT_lung_Th_ova,/gpfs/gsfs7/users/davisfp/projects/exfoxp3/results/RNAseq/crcount.2.0.0_parallel/WT_lung_Th_ova/WT_lung_Th_ova/outs/molecule_info.h5\
WT_lung_Th_PBS,/gpfs/gsfs7/users/davisfp/projects/exfoxp3/results/RNAseq/crcount.2.0.0_parallel/WT_lung_Th_PBS/WT_lung_Th_PBS/outs/molecule_info.h5\
WT_mLN_Th_PBS,/gpfs/gsfs7/users/davisfp/projects/exfoxp3/results/RNAseq/crcount.2.0.0_parallel/WT_mLN_Th_PBS/WT_mLN_Th_PBS/outs/molecule_info.h5" > exfoxp3_sclibs_201807.csv
 

cellranger aggr --id=exfoxp3_sclibs_201807 \
                --csv=exfoxp3_sclibs_201807.csv \
                --normalize=mapped

set curtime=`date`
echo "#slurm run finished on $curhost at $curtime"
