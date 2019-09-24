#!/usr/bin/env perl
my $USAGE = "Usage: $0 [--inifile inifile.ini] [--section section] [--recmark lx] [--hmmark hm] [--debug] [file.sfm]";
=pod
FLEx v 8.3 import crashes when it tries to import a record with the following characteristics:
	- a record has a duplicated Complex Form field.
	- the Complex Form doesn't have a pre-existing entry
This script creates dummy entries those Complex Forms.

For Example 

This script reads an ini file for:
	* a list of Complex Form Markers

It opl's the SFM file.
It grinds over the opl'ed file building a hash of entry/homograph#
It grinds again finding duplicate complex forms. If the duplicated form is in the hash, ignore it.
create a dummy entry with a pointer

The ini file should have sections with syntax like this:
[MakeCompForm]
CompFormSFMs=Form1,Form2...
e.g.
CompFormSFMs=CN,CNs,CNp,Cp,coCp,CpP,P1,coP1,P1s,P1p,P2,coP2,P2s,P2p,PN,vaPN,PN1,PN2,PNs,PNp,I1,coI1,vaI1,phI1,I1s,I1p,I2,va12,I2s,I2p,IN,coIN,INs,INp,IN1,vaIN1,IN2,vaIN2,J1,coJ1,JN,vaJN,vaJN1,J2,vaJN2,D1,vaD1,coD1,D2,vaD2,NV,coNV,S1,S2,SN,coSN,coS1,coS2,PI1,PI2,coPI,DR1,DR2,H1,H2,ST,uf,couf,uf1,uf2,couf2,ind,dt

=cut
use 5.020;
use utf8;
use open qw/:std :utf8/;

use strict;
use warnings;
use English;
use Data::Dumper qw(Dumper);


use File::Basename;
my $scriptname = fileparse($0, qr/\.[^.]*/); # script name without the .pl

use Getopt::Long;
GetOptions (
	'inifile:s'   => \(my $inifilename = "$scriptname.ini"), # ini filename
	'section:s'   => \(my $inisection = "MakeCompForm"), # section of ini file to use
# additional options go here.
# 'sampleoption:s' => \(my $sampleoption = "optiondefault"),
	'recmark:s' => \(my $recmark = "lx"), # record marker, default lx
	'hmmark:s' => \(my $hmmark = "hm"), # homograh number marker, default hm
	'debug'       => \my $debug,
	) or die $USAGE;

# check your options and assign their information to variables here
$recmark =~ s/[\\ ]//g; # no backslashes or spaces in record marker

# if you need  a config file uncomment the following and modify it for the initialization you need.
# if you have set the $inifilename & $inisection in the options, you only need to set the parameter variables according to the parameter names
#=pod
use Config::Tiny;
my $config = Config::Tiny->read($inifilename, 'crlf');
die "Quitting: couldn't find the INI file $inifilename\n$USAGE\n" if !$config;
my $CompFormSFMs = $config->{"$inisection"}->{CompFormSFMs};
$CompFormSFMs  =~ s/\,*$//; # no trailing commas
$CompFormSFMs  =~ s/ //g;  # no spaces
$CompFormSFMs  =~ s/\,/\|/g;  # use bars for or'ing
my $srchSFMs = qr/$CompFormSFMs/;
say STDERR "Search CompFormSFMs:$CompFormSFMs" if $debug;
#=cut
my $dt = (substr localtime(), 8,2) . "/" . (substr localtime(), 4,3) . "/" . (substr localtime(), 20,4);
$dt =~ s/ //g;
say STDERR "date:$dt" if $debug;

# generate array of the input file with one SFM record per line (opl)
my @opledfile_in;

my $line = ""; # accumulated SFM record
my $linecount = 0 ;
while (<>) {
	s/\R//g; # chomp that doesn't care about Linux & Windows
	#perhaps s/\R*$//; if we want to leave in \r characters in the middle of a line 
	s/#/\_\_hash\_\_/g;
	$_ .= "#";
	if (/^\\$recmark /) {
		$line =~ s/#$/\n/;
		push @opledfile_in, $line;
		$line = $_;
		}
	else { $line .= $_ }
	}
push @opledfile_in, $line;

my %oplhash; # hash of opl'd file keyed by \lx(\hm)
for my $oplline (@opledfile_in) {
# build hash
	if ($oplline =~ /\\$recmark ([^#]*)#/) {
		my $lxkey = $1;
		$oplhash{$lxkey} = "" if ! exists $oplhash{$lxkey};
		
		if ($oplline =~ /\\$hmmark ([^#]*)#/) {
			$lxkey .= $1;
			}
	$oplhash{$lxkey} = $oplline;
		}
	}
for my $oplline (@opledfile_in) {
	my $extralines ="";
	while ($oplline =~ /\\$srchSFMs\ ([^#]+)#(?=(.*?\\$srchSFMs\ \g{1}))/g ) {
		# trailing # is not captured but is tested so substrings don't match the full field
		# for explanation of this non-obvious regex: 
		# See Stack Overflow question 58069662
		my $cflx = $1;
		if (! exists $oplhash{$cflx}) {
			my $newmainref ="\\lx $cflx#\\mn $lxkey#\\cm created by MakeCompForm#\\ind $dt#\\dt $dt##";
			$oplhash{$cflx} = $newmainref;
			$extralines .= $newmainref;
			}
		}

say STDERR "oplline:", Dumper($oplline) if $debug;
#de_opl this line
	for ($oplline, $extraline) {
		s/#/\n/g;
		s/\_\_hash\_\_/#/g;
		print;
		}
	}

