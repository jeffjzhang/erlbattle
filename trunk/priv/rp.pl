#!/usr/bin/perl -w

use warnings;

my $var = $ARGV[0];
opendir DIR, ${var} or die "can not open $var \n";

my @filelist = readdir DIR;
foreach my $file (@filelist) {
	if($file =~ /\.erl$/) {
		my $dest = $var.$file;
		my $bak = $dest."\.bak";
		print("$dest\n");
		`sed -f rp.ss $dest > $bak`;
		`mv $bak $dest`;
	}
}
