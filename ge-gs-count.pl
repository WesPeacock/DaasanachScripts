#!/usr/bin/env perl
my $USAGE = "perl -pf opl.pl < FILE.sfm |perl -nf $0";
# This is a tool for producing a listing of counts of definition/glosses in 2 languages, e.g English and Swahili 
#for each entry it gives a count of the definition/gloss in the main language (i.e. \ge -- English)
# for each definition/gloss in English it gives a count of the number of semicolons in that definition and the number of swahili definitions and semicolons

use 5.020;
use utf8;
use open qw/:std :utf8/;

use strict;
use warnings;
use English;
use Data::Dumper qw(Dumper);

sub buildlxkey {
# simple function that returns the contents of the record marker field
# assumes the homograph marker occurs only under the main record marker
# i.e., doesn't handle homographs on subentries
# $recmark and $hmmark do not have leading backslash
	my ($line, $recmark, $hmmark) =@_;
	my $lxkey = "";
	if ($line =~ /\\$recmark ([^#]*)#.*/) {
		$lxkey = $1;
		if ($line =~ /\\$hmmark ([^#]*)#/) {
			$lxkey .= $1;
			}
		}
	return $lxkey;
	}


my $recmark = "lx";
my $hmmark = "hm";
my $dtmark = "dt";
my $gemark = "ge";
my $gsmark = "gs";
my $oplline = $_;

my $lxkey = buildlxkey($oplline, $recmark, $hmmark);

my $gecount = () = $oplline =~ /\\$gemark /gi;
next if $gecount < 1;
print "$lxkey: gecount $gecount ";
while ($oplline =~ /\\$gemark\ .*?(?=(\\$gemark|\\$dtmark))/g) {
	my $snfield = $MATCH;
	$snfield =~ /(?<=\\$gemark\ )[^#]*/;
	my $gefield = $MATCH;
	my $gesemicount = () = $gefield =~ /\;/gi;
	
	my $gscount = () = $snfield =~ /\\$gsmark /gi;
	if ($gscount < 1) {
		print " (gesemicount $gesemicount No gs)";
		}
	else {
		$snfield =~ /(?<=\\$gsmark\ )[^#]*/;
		my $gsfield = $MATCH;
		my $gssemicount = () = $gsfield =~ /\;/gi;
		print " (gesemicount $gesemicount gscount $gscount gssemicount $gssemicount)";
		}
	}
say "";
