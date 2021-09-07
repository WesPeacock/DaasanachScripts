# Usage:
#   sfm=mark perl -CSD -pf indexsfm.pl <FileName.SFM
# puts the line number on the end of all  lines with a marker specified on the command line.
# default is \lx
# use single quotes/parentheses/bar construction to specify more than one sfm, E.g:
# sfm='(lx|se|sse)' perl -CSD -pf indexsfm.pl <FileName.SFM
# only runs under bash (WSL or Git bash), not Windows CMD
BEGIN {
	die "Run under git bash or WSL" if $^O !~ /(linux|msys)/;
	$sfm = $ENV{sfm} // "lx" ;
	};
s/(\R)/\:$.$1/ if /^\\$sfm /;