#!/bin/csh -v
#SBATCH --cpus-per-task=16
#SBATCH --ntasks-per-core=1
#SBATCH --mem=50g
#SBATCH -o slurm_out/build_kallisto_indices.%A.out
#SBATCH -e slurm_out/build_kallisto_indices.%A.err
#SBATCH --time=1:00:00
#SBATCH --gres=lscratch:200

module load STAR/2.4.2a
mkdir GRCm38.82.ERCC.star_index
STAR --runMode genomeGenerate --genomeDir GRCm38.82.ERCC.star_index --genomeFastaFiles GRCm38.82.ERCC.fa --runThreadN 16 --sjdbGTFfile GRCm38.82.ERCC.gtf
