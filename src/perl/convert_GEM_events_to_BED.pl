#!/usr/local/bin/perl
# fpd150108_1103 -- modified to output strand if in the events file.
# orig: fpd141216_1520
#
#davisf@tangerine 20141216.p300_Debug> head /groups/eddy/home/davisf/work/consults/zliu/results//ChIPseq/GEM/external/chen08_CTCF/gemrun/gemrun_GEM_events.txt
#Position             IP Control    Fold Expectd Q_-lg10 P_-lg10 P_poiss IPvsEMP   Noise KmerGroup       KG_hgp  Strand
#Y:90808863        184.0     2.2    84.9     4.6   45.50   50.26  219.01   -0.81    0.02 CCACTGGGTG 40/5 -8.36   -
#17:56763542       153.0     0.7   211.7     1.6   39.72   44.17  236.96   -0.90    0.00 --------        0       *

use strict;
use warnings;

main() ;

sub main {

   my $halfwidth = $ARGV[0] || 0 ;

   my $header = <STDIN> ;
   my $n = 1 ;
   while (my $line = <STDIN>) {
      chomp $line;
      my @t = split(/\t/, $line) ;
      my ($chr,$pos) = split(':', $t[0]) ;
      my $score = $t[5] ;
      my $strand = $t[$#t] ;

      my $start = $pos - 1;
      my $end = $pos + 1;

      if ($halfwidth > 0) {
         $start -= $halfwidth;
         $end += $halfwidth;
      }

      if ($start < 0) {$start = 0;}

      my $name = "peak$n:".$t[10] ; $name =~ s/ .*// ;

      if ($strand eq '*') {$strand = '+';}

      my @out = ("chr$chr", $start, $end, $name, $score, $strand);
      print join("\t", @out)."\n";
      $n++ ;
   }

}
