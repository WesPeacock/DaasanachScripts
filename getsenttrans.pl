#!/usr/bin/env perl
my $USAGE = "Usage: $0 [--inifile inifile.ini] [--section section] [--recmark w] [--hmmark hm] [--debug] [file.sfm]";
=pod

For Example

This script reads an ini file for:
	* a log file name
	* a key file name

It opl's the key file.
It grinds over the opl'ed key file
	building a hash of lines keyed by the matching field.

It grinds again over the opl'ed file checking the input match field
    if the cross-reference hits on the main hash --good
=cut
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
	if ($line =~ /\\$recmark ([^\@]*)\@.*/) {
		$lxkey = $1;
		if ($line =~ /\\$hmmark ([^\@]*)\@/) {
			$lxkey .= $1;
			}
		}
	return $lxkey;
	}

use File::Basename;
my $scriptname = fileparse($0, qr/\.[^.]*/); # script name without the .pl
$USAGE =~ s/inifile\.ini/$scriptname.ini/;
use Getopt::Long;
GetOptions (
	'inifile:s'   => \(my $inifilename = "$scriptname.ini"), # ini filename
	'section:s'   => \(my $inisection = "getsenttrans"), # section of ini file to use
# additional options go here.
# 'sampleoption:s' => \(my $sampleoption = "optiondefault"),
	'recmark:s' => \(my $recmark = "w"), # record marker, default w
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
my $ErrorLogfilename = $config->{"$inisection"}->{ErrorLog};
open(LOGFILE, ">$ErrorLogfilename");
my $KeyFilefilename = $config->{"$inisection"}->{KeyFile};
open(KEYFILE, "<$KeyFilefilename");


$config->{"$inisection"}->{KeyMatchMarker} =~ s/ //g; # no spaces in the list
$config->{"$inisection"}->{KeyMatchMarker} =~ s/,+/,/g; # no empty markers
$config->{"$inisection"}->{KeyMatchMarker} =~ s/,$//; # no empty markers (cont.)
$config->{"$inisection"}->{KeyMatchMarker} =~ s/,/\|/g; # alternatives  are '|' in Regexes
my $KeyMatchMarker =$config->{"$inisection"}->{KeyMatchMarker};

$config->{"$inisection"}->{KeyTransMarker} =~ s/ //g; # no spaces in the end marker list
$config->{"$inisection"}->{KeyTransMarker} =~ s/,+/,/g; # no empty markers
$config->{"$inisection"}->{KeyTransMarker} =~ s/,$//; # no empty markers (cont.)
$config->{"$inisection"}->{KeyTransMarker} =~ s/,/\|/g; # alternatives  are '|' in Regexes
my $KeyTransMarker =$config->{"$inisection"}->{KeyTransMarker};

$config->{"$inisection"}->{InputMatchMarker} =~ s/ //g; # no spaces in the list
$config->{"$inisection"}->{InputMatchMarker} =~ s/,+/,/g; # no empty markers
$config->{"$inisection"}->{InputMatchMarker} =~ s/,$//; # no empty markers (cont.)
$config->{"$inisection"}->{InputMatchMarker} =~ s/,/\|/g; # alternatives  are '|' in Regexes
my $InputMatchMarker =$config->{"$inisection"}->{InputMatchMarker};

$config->{"$inisection"}->{OutputMarker} =~ s/ //g; # no spaces in the end marker list
$config->{"$inisection"}->{OutputMarker} =~ s/,+/,/g; # no empty markers
$config->{"$inisection"}->{OutputMarker} =~ s/,$//; # no empty markers (cont.)
$config->{"$inisection"}->{OutputMarker} =~ s/,/\|/g; # alternatives  are '|' in Regexes
my $OutputMarker =$config->{"$inisection"}->{OutputMarker};


#say STDERR ":" if $debug;
say STDERR "inisection:$inisection" if $debug;
say STDERR "inifile:$inifilename" if $debug;
say STDERR "ErrorLogfilename:$ErrorLogfilename" if $debug;
say STDERR "KeyFilefilename:$KeyFilefilename" if $debug;
say STDERR "Key Match Marker:$KeyMatchMarker" if $debug;
say STDERR "Key Trans Marker:$KeyTransMarker" if $debug;
say STDERR "Input Trans Marker:$InputMatchMarker" if $debug;
say STDERR "Output Marker:$OutputMarker" if $debug;
if ($debug) { say STDERR "config:", Dumper($config) }; 

#=cut

# generate array of the key file with one SFM record per line (opl)
my @opledkeyfile;

my $line = ""; # accumulated SFM record
my $linecount = 0 ;
while (<KEYFILE>) {
	s/\R//g; # chomp that doesn't care about Linux & Windows
	#perhaps s/\R*$//; if we want to leave in \r characters in the middle of a line
	s/\ +$//;
	s/\@/\_\_at\_\_/g;
	$_ .= "\@";
	if (/^\\$recmark /) {
		$line =~ s/\@$/\n/;
		push @opledkeyfile, $line;
		$line = $_;
		}
	else { $line .= $_ }
	}
push @opledkeyfile, $line;
my %keyfilehash; # hash of KeyMatchMarker keys
for my $keyline (@opledkeyfile) {
# build hash
	next if !($keyline =~  /\\($KeyMatchMarker) [^\@]+\@\\($KeyTransMarker) [^\@]+\@/);
	while ($keyline =~ /\\($KeyMatchMarker) [^\@]+\@\\($KeyTransMarker) [^\@]+\@/g) {
		my $MatchPair = $MATCH;
		$keyline =~ m/\\($KeyMatchMarker) [^\@]+\@/;
		my $MatchField = $MATCH;
		$keyline =~ m/\\($KeyTransMarker) [^\@]+\@/;
		my $TransField = $MATCH;
		$TransField =~ s/\\($KeyTransMarker) /\\$OutputMarker /;
		$TransField =~ s/\@$//;
		next if ! $MatchField;
		$MatchField =~ s/\@$//;
		
		if (exists $keyfilehash{$MatchField}) {
			my $already = $keyfilehash{$MatchField};
			if ($already ne  $TransField) {
				say LOGFILE qq[Sentence:"$MatchField"];
				say LOGFILE qq[Already has Translation:"$already"];
				say LOGFILE qq[Will Ignore Translation:"$TransField"];
				say LOGFILE "";
				}
			}
		else {
			$keyfilehash{$MatchField} = $TransField;
			}
		
		say STDERR "key:$MatchField\nTrans:$TransField" if $debug;
		}
	}
# erase the keyfile array after it's hashed
@opledkeyfile=();
undef @opledkeyfile;
say STDERR "keyfilehash:", Dumper(\%keyfilehash) if $debug;

while (<>) {
	s/\R//g; # chomp that doesn't care about Linux & Windows
	#perhaps s/\R*$//; if we want to leave in \r characters in the middle of a line
	s/\ +$//;
	say $_;
	if (m/\\$InputMatchMarker (.*)/) {
		my $MatchText = $1;
		my $KeyField = "\\$KeyMatchMarker $MatchText";
		if (exists $keyfilehash{$KeyField}) {
			say $keyfilehash{$KeyField};
			}
		}
	}
