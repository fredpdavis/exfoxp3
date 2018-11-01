#!/usr/local/bin/perl
#fpd150518_1948
# purpose: convert ENSEMBL chromosome names to UCSC compatible names

use strict;
use warnings;

main() ;

sub main {

   my $usage = __FILE__." [column number of chromosome name; default 1] < old_file" ;
   if ($#ARGV >= 0 && $ARGV[0] =~ /[hH]/) {
      die $usage ;
   }

   my $chrom_field = 0;
   if ($#ARGV >= 0) {$chrom_field = $ARGV[0] - 1;}

   my $ensembl2ucsc = {
"1" => "chr1",
"2" => "chr2",
"3" => "chr3",
"4" => "chr4",
"5" => "chr5",
"6" => "chr6",
"7" => "chr7",
"8" => "chr8",
"9" => "chr9",
"10" => "chr10",
"11" => "chr11",
"12" => "chr12",
"13" => "chr13",
"14" => "chr14",
"15" => "chr15",
"16" => "chr16",
"17" => "chr17",
"18" => "chr18",
"19" => "chr19",
"X" => "chrX",
"Y" => "chrY",
"MT" => "chrM",
   } ;

   while (my $line = <STDIN>) {
      chomp $line;
      my @t = split(/\t/, $line) ;
      if (!exists $ensembl2ucsc->{$t[$chrom_field]}) {next;}

      $t[$chrom_field] = $ensembl2ucsc->{$t[$chrom_field]} ;
      print join("\t", @t)."\n";
   }

}
