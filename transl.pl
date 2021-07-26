#!/usr/bin/perl
use 5.020;
use utf8;
use open qw/:std :utf8/;

use strict;
use warnings;
use English;
use Data::Dumper qw(Dumper);
my %neworth;
open my $fh, '<', 'Lika_index_new_orthography.csv' or die "Cannot open: $!";
while (my $line = <$fh>) {
  my @array = split /,/, $line;
  my $key = shift @array;
  my $val = shift @array;
  $neworth{$key} = $val;
}
close $fh;
# say STDERR "neworth:", Dumper(\%neworth);
open my $fh1, '<', 'Likaindex2titles_SD_pics_NewOrth.csv' or die "Cannot open: $!";
while (my $line = <$fh1>) {
	my @array = split /,/, $line;
	my $key1 = shift @array;
	#say STDERR "key:", $key1;
	if ($key1) {
		 my $val="";
		 $val=$neworth{$key1} if exists $neworth{$key1} ;
		$line =~ s/\,\,/\,$val\,/;
		}
	print $line;
}
