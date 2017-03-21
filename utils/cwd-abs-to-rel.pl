#!/usr/bin/env perl
use v5.10; use strict; use warnings; use autodie qw(:all);

use Env qw(PWD USER HOME);
use File::stat qw(stat);

my @masks = (
	qr[^/run/media/$USER/([0-9A-Za-z_-]+)/home/$USER(/|$)],
	qr[^/media/$USER/([0-9A-Za-z_-]+)/home/$USER(/|$)],
	qr[^/media/([0-9A-Za-z_-]+)/home/$USER/(/|$)],
	qr[^/mnt/([0-9A-Za-z_-]+)/home/$USER(/|$)],
	qr[^/usr/home/$USER(/|$)],
);

sub same_dir { -d $_[0] && stat($PWD)->ino == stat($_[0])->ino };
sub by_mask { $PWD =~ $_[0]; ($1, substr($PWD, length $&)) }

foreach my $mask (@masks) {
	next if $PWD !~ $mask;
	my ($mnt_name, $tail) = by_mask $mask;
	my $new_wd = "$HOME/$mnt_name" . ((length($tail) > 0) ? "/$tail" : '');
	my $short_new_wd = "$HOME" . ((length($tail) > 0) ? "/$tail" : '');
	exit 1 unless same_dir $new_wd;
	print same_dir($short_new_wd) ? $short_new_wd : $new_wd;
	exit 0;
}

exit 1 if length($PWD) < length($HOME) || $PWD !~ /^$HOME/;
my $wd_tail = substr $PWD, length($HOME) + ((length($PWD) > length($HOME)) ? 1 : 0);
exit 1 if length($wd_tail) == 0;
my @wd_tail = split '/', $wd_tail;
undef $wd_tail;
my $wd_sliced = "$HOME/" . join '/', splice @wd_tail, 1;
$wd_sliced = $HOME if $wd_sliced eq "$HOME/";
exit 1 unless same_dir $wd_sliced;
print $wd_sliced;
exit 0;
