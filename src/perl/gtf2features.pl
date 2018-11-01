#!/usr/local/bin/perl
#fpd 180226_1401

use strict;
use warnings;
use File::Temp qw/tempfile/;

main() ;

sub main {

   my $usage = __FILE__." CHROMSIZE GTF" ;
   if ($#ARGV < 1) { die $usage."\n" ; }

   my $specs = {
      tsswin_half => 2500,
      mm10  => {
         genomesize => $ARGV[0], #"../misc/mm10_chromsize/mm10_chromsize.tab",
         gtf => $ARGV[1], #"../external/GRCm38.ENSEMBL82/Mus_musculus.GRCm38.82.gtf.gz",
      }
   } ;
   my $species = "mm10" ;

   open(CHROMSIZESF, $specs->{$species}->{genomesize});
   my $chrom2len = {};
   while (my $line = <CHROMSIZESF>) {
      chomp $line;
      my ($chrom, $len) = split(/\t/, $line);
      $chrom =~ s/^chr// ;
      if ($chrom eq "M") {$chrom = "MT";}
      $chrom2len->{$chrom} = $len ;
   }
   close(CHROMSIZESF) ;

   my $g ;
   open(GTF, "zcat $specs->{$species}->{gtf} |") ;
   while (my $line = <GTF>) {
      if ($line =~ /^#/) {next;}
      chomp $line;
      my @t = split(/\t/, $line) ;
      if ($t[2] ne 'exon') { next;}
      my ($chrom, $start, $end, $strand) = ($t[0], $t[3], $t[4], $t[6]) ;

      my $desc = $t[8] ;



      my ($tx) = ($desc =~ /transcript_id \"([^"]+)\";/) ;
      my ($gene) = ($desc =~ /gene_id \"([^"]+)\";/) ;


      if (!exists $g->{$tx}) {
         $g->{$tx} = {
            tss => $start,
            tes => $end,
            chrom => $chrom,
            strand => $strand,
            gene => $gene
         } ;
      }

#      if ($line =~ /NR_026820/) {print STDERR "READ IT!";}

      if ($strand eq '+') {

         if ($g->{$tx} eq '' || $start < $g->{$tx}->{tss}) {
            $g->{$tx}->{tss} = $start; }

         if (!exists $g->{$tx} || $end > $g->{$tx}->{tes}) {
            $g->{$tx}->{tes} = $end; }

      } else {

         if (!exists $g->{$tx} || $end > $g->{$tx}->{tss}) {
            $g->{$tx}->{tss} = $end; }

         if (!exists $g->{$tx} || $start < $g->{$tx}->{tes}) {
            $g->{$tx}->{tes} = $start; }
      }
   }
   close(GTF) ;

   my ($t_fh, $t_fn) ;
   ($t_fh->{tss}, $t_fn->{tss}) = tempfile() ;
   ($t_fh->{exact_tss}, $t_fn->{exact_tss}) = tempfile() ;
   ($t_fh->{genebody}, $t_fn->{genebody}) = tempfile() ;

   foreach my $tx (sort keys %{$g}) {

      my $tsswin_start = $g->{$tx}->{tss} - $specs->{tsswin_half} ;
      my $tsswin_end = $g->{$tx}->{tss} + $specs->{tsswin_half} ;

#      if (!exists $chrom2len->{$g->{$tx}->{chrom}}) {
#         die "NO LEN INFO FOR chrom=".$g->{$tx}->{chrom}.". tx=$tx\n"; }
#
      if (!exists $chrom2len->{$g->{$tx}->{chrom}}) {
         print STDERR "skipping: NO LEN INFO FOR chrom=".$g->{$tx}->{chrom}.". tx=$tx\n";
         next;
      }

      if ($tsswin_start < 0) {$tsswin_start = 0 ;}
      if ($tsswin_end >= $chrom2len->{$g->{$tx}->{chrom}}) {
         $tsswin_end = $chrom2len->{$g->{$tx}->{chrom}} - 1 ; }

      print {$t_fh->{tss}} join("\t", $g->{$tx}->{chrom},
                              $tsswin_start, $tsswin_end,
                              $tx, '', $g->{$tx}->{strand})."\n";

      print {$t_fh->{exact_tss}} join("\t", $g->{$tx}->{chrom},
                              $g->{$tx}->{tss}, $g->{$tx}->{tss} + 1,
                              $tx, '', $g->{$tx}->{strand})."\n";


      if ($g->{$tx}->{strand} eq '+') {
         print {$t_fh->{genebody}} join("\t", $g->{$tx}->{chrom},
                                    $g->{$tx}->{tss}, $g->{$tx}->{tes},
                                    $tx, '', $g->{$tx}->{strand})."\n";
      } else {
         print {$t_fh->{genebody}} join("\t", $g->{$tx}->{chrom},
                                    $g->{$tx}->{tes}, $g->{$tx}->{tss},
                                    $tx, '', $g->{$tx}->{strand})."\n";
      }
   }
   close($t_fh->{genebody}) ;
   close($t_fh->{exact_tss}) ;
   close($t_fh->{tss}) ;

   system("sort -k1,1 -k2,2n -k3,3n ".$t_fn->{tss}.">".$species."_tss".($specs->{tsswin_half} * 2)."bpwin.bed") ;
   system("sort -k1,1 -k2,2n -k3,3n ".$t_fn->{exact_tss}.">".$species."_tss_exact.bed") ;
   system("sort -k1,1 -k2,2n -k3,3n ".$t_fn->{genebody}.">".$species."_genebodies.bed") ;

}
