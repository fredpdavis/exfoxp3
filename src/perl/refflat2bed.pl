#!/usr/local/bin/perl 
#fpd 151006_1523
#purpose: convert UCSC refFlat table to TSS and genebody BED per-Tx and per-gene

use strict;
use warnings;
use File::Temp qw/tempfile/;
main();


sub main {

   my $out_fn = {
      tx_tss		=> "tx_tss.ucsc_refflat.bed",
      tx_genebody	=> "tx_genebody.ucsc_refflat.bed",
      gene_tss		=> "gene_tss.ucsc_refflat.bed",
      gene_genebody	=> "gene_genebody.ucsc_refflat.bed"
   } ;

   my ($t_fh, $t_fn) = {} ; # un-sorted intermediate BED files
   foreach my $f (keys %{$out_fn}) {
      ($t_fh->{$f}, $t_fn->{$f}) = tempfile() ; }


# Create per-tx and per-gene TSS and genebody BED files (unsorted intermediate)
   while (my $line = <STDIN>) {
      chomp $line;

      my ($geneName, $name, $chrom, $strand, $txStart, $txEnd,
          $cdsStart, $cdsEnd, $exonCount, $exonStarts, $exonEnds) =
      split(/\t/, $line) ;

      print {$t_fh->{tx_genebody}} join("\t", $chrom, $txStart, $txEnd,
                                              $name, 0, $strand)."\n";
      print {$t_fh->{gene_genebody}} join("\t", $chrom, $txStart, $txEnd,
                                                $geneName, 0, $strand)."\n";

      my $realtss = $txStart ;
      if ($strand eq '-') { $realtss = $txEnd;}
      print {$t_fh->{tx_tss}} join("\t", $chrom, $realtss, $realtss + 1,
                                           $name, 0, $strand)."\n";
      print {$t_fh->{gene_tss}} join("\t", $chrom, $realtss, $realtss + 1,
                                             $geneName, 0, $strand)."\n";

   }


# Sort BED file

   foreach my $f (keys %{$out_fn}) {
      close($t_fh->{$f}) ;
      system("sort -k1,1 -k2,2n -k3,3n ".$t_fn->{$f}." | uniq >".$out_fn->{$f});
   }

}

__END__

`geneName` varchar(255) NOT NULL,
`name` varchar(255) NOT NULL,
`chrom` varchar(255) NOT NULL,
`strand` char(1) NOT NULL,
`txStart` int(10) unsigned NOT NULL,
`txEnd` int(10) unsigned NOT NULL,
`cdsStart` int(10) unsigned NOT NULL,
`cdsEnd` int(10) unsigned NOT NULL,
`exonCount` int(10) unsigned NOT NULL,
`exonStarts` longblob NOT NULL,
`exonEnds` longblob NOT NULL,



First 2 lines of refFlat.txt.gz:

Cpne1	NM_170590	chr2	-	156071840	156111965	156073520	156079464	16	156071840,156073798,156074175,156076236,156077398,156077555,156077774,156077928,156078146,156078331,156078573,156078751,156078899,156079062,156079338,156111785,	156073661,156074035,156074309,156076288,156077453,156077689,156077834,156078015,156078233,156078421,156078654,156078823,156078974,156079242,156079464,156111965,
Lhx9	NM_001025565	chr1	-	138825185	138842444	138828653	138841981	5	138825185,138832701,138838342,138839872,138841807,	138828710,138832904,138838698,138840075,138842444,
