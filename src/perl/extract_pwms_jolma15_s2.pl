#!/usr/local/bin/perl
#fpd 151117_0005
#

use strict;
use warnings;
main() ;

sub main {

# Skip over header info
   while (my $line = <STDIN>) {
      if ($line =~ /^1/) {last;} }

   my $pwm_names = {} ;
   my $cur_pwm = {} ;
   while (my $line = <STDIN>) {
      chomp $line;

      if ($line =~ /^Base/) {

         if (exists $cur_pwm->{name}) {
            print_pwm($cur_pwm) ; }
         map { delete $cur_pwm->{$_} } keys %{$cur_pwm} ;

         my @t = split(/\t/, $line) ;

# Append counter to PWM name if already read in
         my $pwm_name = $t[1] ;
         my $i = 1 ;
         while (exists $pwm_names->{$pwm_name}) {
#            print STDERR "i = $i; $pwm_name exists, so incrementing\n";
            $i++ ;
            $pwm_name = $t[1].".$i" ;
         }
         $cur_pwm->{name} = $pwm_name ;
         $pwm_names->{$pwm_name}++ ;

      } else {

         $line =~ s/\t+$// ;
         my ($nt, @counts) = split(/\t/, $line) ;
         $cur_pwm->{$nt} = \@counts ;

      }
   }


}

sub print_pwm {
   my $in = shift ;
   my $colwidth = 6 ;

   print ">".$in->{name}."\n"; ;
   foreach my $nt (qw/A C G T/) {
      my @out ;
      foreach my $j ( 0 .. $#{$in->{$nt}}) {
         push @out, (" "x($colwidth - length($in->{$nt}->[$j]))).
                        $in->{$nt}->[$j] ;
      }
      print join(" ",@out)."\n";
   }
}
