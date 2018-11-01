#!/usr/local/bin/perl

use strict;
use warnings;

main() ;


sub main {

#chr1    4775367 4775827 peak1;iTreg_K27ac,Th2_K27ac,TrTh2_K27ac
#
   my $usage = __FILE__." output_file_prefix" ;
   my $prefix = $ARGV[0] || die $usage ;

   my $fns = {} ;
   my $fhs = {} ;
   while (my $line = <STDIN>) {
      chomp $line;
      my @t = split(/\t/, $line) ;
      my $peakclass = $t[3]; $peakclass =~ s/.*;// ;
      $peakclass =~ s/,/__/g ;
      if (!exists $fns->{$peakclass}) {
         $fns->{$peakclass} = $prefix.".$peakclass.bed" ;
         open($fhs->{$peakclass}, ">".$fns->{$peakclass}) ;
      }

      print {$fhs->{$peakclass}} $line."\n";
   }

   foreach my $x (keys %{$fhs}) {close($fhs->{$x});}

}
