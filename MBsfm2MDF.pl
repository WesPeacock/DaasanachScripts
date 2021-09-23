# perl -pf MBsfm2MDF.pl FileName.SFM > Newfile.sfm
# Change Old Mexico Branchs SFMs to MDF (sort of)
# Note:
# include a space after the SFM -- avoids matching substrings
# you can include an opl line break character
# the search/replace needs \Q...\E so that SFMs don't match special regex groups

BEGIN {
	our %mbsfm2mdf = (
		# Note that SFMs have trailing spaces so that none of them is a substring of another
		'\w ' => '\lx ',
		'\d ' => '\gn ',
		'\dd ' => '\dn ',
		'\dde ' => '\de ',
		'\ew ' => '\de ',
		'\ct ' => '\an ',
		'\p ' => '\ps ',
		'\s ' => '\se ',
		'\sd ' => '\dn_SE ',
		'\sdex ' => '\de_SE ',
		'\sp ' => '\ps ',
		'\t ' => '\xn ',
		'\tex ' => '\xe ',
		'\v ' => '\xv ',
		'\to ' => '\ph ',
		'\edtn ' => '\st ',
		'\et ' => '\es ',
		'\g ' => '\gn ',
		'\ge ' => '\na ',
		'\n ' => '\nt ',
		'\ne ' => '\nte ',
		'\r ' => '\cf ',
		'\sn ' => '\sy ',
		'\te ' => '\xe ',

		#No change included for debugging purposes
		'\hm ' => '\hm ',
		'\dt ' => '\dt ',
		'\va ' => '\va ',
		'\dl ' => '\dl ', # maybe should be \dlx to mark further edits
		);

	our %mbsfm2mdf2 = (
		# hash for pass 2
		'\# ' => '\sn ', # pass 2 won't feed  \sn=>\sy

		# non-SFM changes go in the last pass so that it is assured that they won't feed any SFM changes
		# end of line
		'@' => '#',
		);

	foreach my $mbsfm (keys %mbsfm2mdf) { # check if output feeds input
		my $checksfm = $mbsfm2mdf{$mbsfm};
		next if $checksfm eq $mbsfm;
		say STDERR "ERROR! $checksfm is an input and an output for $mbsfm" if exists  $mbsfm2mdf{ $checksfm};
		}

	use Getopt::Long;
	GetOptions (
		'debug'       => \our $debug,
		)
	}

# main loop pass 2
foreach my $mbsfm (keys %mbsfm2mdf) {
	my $subtext = $mbsfm2mdf{$mbsfm};
	$subtext =~ s/ /% / if $debug;
	# say STDERR "mbsfm:$mbsfm";
	s/\Q$mbsfm\E/$subtext/g;
	}
# pass 2
foreach my $mbsfm (keys %mbsfm2mdf2) {
	my $subtext = $mbsfm2mdf2{$mbsfm};
	$subtext =~ s/ /% / if $debug;
	# say STDERR "mbsfm:$mbsfm";
	s/\Q$mbsfm\E/$subtext/g;
	}
