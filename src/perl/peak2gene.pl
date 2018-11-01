#!/usr/local/bin/perl

=head1 NAME

peak2gene.pl

=head1 VERSION

fpd151009_0922

=head1 AUTHOR

Fred P. Davis, NIH/NIAMS (fred.davis@nih.gov)

=head1 SYNOPSIS

peak2gene.pl 

=head1 DESCRIPTION

=cut

use strict;
use warnings;
main() ;

sub main {

   my $usage = __FILE__." -peak_fn BED_FN [-mode gene_tss,tx_tss,gene_genebody,tx_genebody]" ;

   my $specs = {
      basedir           => "~/data/projects/iwata_tbet",
      bedtools_bin      => "bedtools",
      out_prefix        => "peak2gene",
      mode              => 'gene_tss,tx_tss,gene_genebody,tx_genebody'
   } ;
   $specs->{gene_bed_dir} = $specs->{basedir}."/data/external/gene_annotation/ucsc" ;


   $specs->{gene_beds} =  {
      gene_tss          => $specs->{gene_bed_dir}."/gene_tss.ucsc_refflat.bed",
      tx_tss            => $specs->{gene_bed_dir}."/tx_tss.ucsc_refflat.bed",
      gene_genebody     => $specs->{gene_bed_dir}."/gene_genebody.ucsc_refflat.bed",
      tx_genebody       => $specs->{gene_bed_dir}."/tx_genebody.ucsc_refflat.bed",
   } ;

   my $j = 0 ;
   while ($j <= $#ARGV) {
      my $key = $ARGV[$j] ; $key =~ s/^-// ;
      $specs->{$key} = $ARGV[($j + 1)] ;
      $j += 2 ;
   }

   if (!exists $specs->{"peak_fn"})     {die $usage;}
   if (!-s $specs->{"peak_fn"})         {die "ERROR: peak_fn not found".
                                             $usage."\n"; }
       

   foreach my $t (keys %{$specs->{gene_beds}}) {

      if ($specs->{mode} !~ $t) {next;}
      print STDERR "mode $t\n";

      my $out_fn = $specs->{out_prefix}.".closest_$t.bed" ;

      my $tcom = $specs->{bedtools_bin}." closest -t all ".
                 "-a ".$specs->{peak_fn}." ".
                 "-b ".$specs->{gene_beds}->{$t}.
                 " -D b ".
                 " > ".$out_fn ;

      system($tcom)
   }

}
