#!/usr/local/bin/perl
# PURPOSE: scale bigwig input to specified read depth
# FROM fpdgenlib

use strict;
use warnings;

main() ;

sub main {

   my $numreads = $ARGV[0] ;
   my $scaleto = $ARGV[1] ;
   my $scalefactor = $scaleto / $numreads ;

   while (my $line = <STDIN>) {
      chomp $line;
      my @t = split(/\t/, $line) ;
      $t[3] = sprintf("%.3f", $t[3] * $scalefactor) ;
      print join("\t", @t)."\n";
   }

}

