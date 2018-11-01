#!/bin/csh -v
#SBATCH --cpus-per-task=8
#SBATCH --ntasks-per-core=1
#SBATCH --mem=30g
#SBATCH -o slurm_out/build_kallisto_indices.%A.out
#SBATCH -e slurm_out/build_kallisto_indices.%A.err
#SBATCH --time=1:00:00
#SBATCH --gres=lscratch:200

module load kallisto/0.42.4
kallisto index -i GRCm38.82.FPtags.ERCC.kallisto_index ../GRCm38.ENSEMBL82/Mus_musculus.GRCm38.cdna.all.fa.gz FPtags_20160228.fa ../ercc/ERCC92.fa
kallisto index -i GRCm38.82.FPtags.ERCC.ncrna.kallisto_index ../GRCm38.ENSEMBL82/Mus_musculus.GRCm38.cdna.all.fa.gz FPtags_20160228.fa ../GRCm38.ENSEMBL82/Mus_musculus.GRCm38.ncrna.fa.gz

cat /fdb/cellranger/refdata-cellranger-1.2.0/mm10/genes/genes.gtf | grep '	transcript	' | sed 's/.*ENSMUSG/ENSMUSG/' | sed 's/".*ENSMUST/ ENSMUST/g' | sed 's/".*gene_name "/ /' | sed 's/".*//' | sort | uniq > tx_gene_name_map.txt
