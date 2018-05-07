#!/usr/bin/env perl
use v5.10; use strict; use warnings;
use feature 'unicode_strings';
use utf8;
use Encode qw<decode_utf8 encode_utf8>;
use File::stat qw(stat);
use File::Spec qw<devnull>;
use File::Basename qw<basename dirname>;
use Term::ANSIColor qw<:constants>;

$SIG{INT} = 'IGNORE';
$|++;

# Wrapper for coloring special symbols
# to prevent bash from calculating
# line length including these symbols.
sub c {'\['.shift.'\]'}

# Removes coloring from string.
# Useful to count string length.
sub text {
	local $_ = $_[0] if defined $_[0];
	# s/\x1b\[[0-9;]*m//g;
	s/\\\[\x1b\[[0-9;]*m\\\]//g; # for symbols wrapped by `c` subroutine
	$_;
}

{
	no warnings qw<once>;
	open OLDOUT, '>&', STDOUT;
	open OLDERR, '>&', STDERR;
}

sub nullout {
	open STDOUT, '>', File::Spec->devnull;
	$_ = shift->();
	open STDOUT, '>&', OLDOUT;
	$_;
}

sub nullerr {
	open STDERR, '>', File::Spec->devnull;
	$_ = shift->();
	open STDERR, '>&', OLDERR;
	$_;
}

# Left-2-right call.
# Piped, second argument subroutine wraps first argument subroutine.
# Arguments are subroutines that take subroutine as an argument.
# Returns subroutine that takes another subroutine that any of single subroutine
# from arguments supposed to get as its argument (yeah, your brain just fucked).
sub compose {
	my @args = @_;
	my $chain = shift @args;

	while (my $sub = shift @args) {
		my $c_chain = $chain; # closure
		$chain = sub {my $cb = shift; $sub->(sub {$c_chain->($cb)})};
	}

	sub {$chain->(shift)}
}

sub end_marker {'~~ end of '.shift.' ~~'}
sub reply_for {say encode_utf8 $_[1]->(); say encode_utf8 end_marker $_[0]}

sub get_permission_mark {
	my $is_root = shift == 0;
	my $p_color = c($is_root ? RED : GREEN);
	(color => $p_color, mark => $p_color . ($is_root ? 'α' : 'λ') . c(RESET));
}

sub get_ps1 {

	chomp(my $USER           = decode_utf8 <>);
	chomp(my $UID            = (decode_utf8 <>) + 0);
	chomp(my $HOME           = decode_utf8 <>);
	chomp(my $PWD            = decode_utf8 <>);
	chomp(my $LOCAL_HOSTNAME = decode_utf8 <>);
	chomp(my $VIRTUAL_ENV    = decode_utf8 <>);
	chomp(my $COLUMNS        = (decode_utf8 <>) + 0);
	chomp(my $RETVAL         = (decode_utf8 <>) + 0);

	# Replacing $HOME in path with tilda
	my $pwd_view =
		($PWD eq $HOME) ? '~' :
		($PWD =~ /^$HOME/) ? '~' . substr($PWD, length $HOME) :
		$PWD;

	# Detecting remote mount point
	my $remote_view = (compose \&nullout, \&nullerr)->(sub {
		my $remote_view = " (@{[c RED]}remote@{[c RESET]})";
		$_ = `df -l -T -- $PWD`;
		return $remote_view if $? == 1; # works on gnu/linux
		@_ = split "\n", $_;
		@_ = split / +/, $_[1];
		return $remote_view if $_[1] =~ /^fusefs(\.|$)/; # works on freebsd
		'';
	});

	my $pyvenv_view = (! $VIRTUAL_ENV) ? '' : sprintf '(pyvenv: %s) ',
		c(MAGENTA) . basename($VIRTUAL_ENV, dirname $VIRTUAL_ENV) . c(RESET);

	my %perm = get_permission_mark $UID;

	my $init_ps1 = sub {

		my $okay = $RETVAL == 0;

		my $exitCode =
			c(BOLD) . c($okay ? GREEN : RED) .
			($okay ? '✓' : '✗') . ($okay ? '' : $RETVAL) .' '. c(RESET);

		$pyvenv_view . $exitCode .  $perm{color} . $USER . c(RESET) .
			'@' . c(YELLOW) . $LOCAL_HOSTNAME . c(RESET) .
			':' . c(BLUE) . $pwd_view . c(RESET) . $remote_view;
	};

	my $ps1 = $init_ps1->();
	my $ps1_len = length text $ps1;

	if ($ps1_len > $COLUMNS) {
		my $min = 16;
		my $pwd_chars_count = $ps1_len - $COLUMNS + 1;
		my $diff = length(text $pwd_view) - $pwd_chars_count;
		$pwd_chars_count += $diff - $min if $diff < $min;

		$pwd_view =
			'…'x(length(text $pwd_view) > $min) .
			substr $pwd_view, $pwd_chars_count;

		$ps1 = $init_ps1->();
		$ps1_len = length text $ps1;
	}

	my $till_eol_cols = $COLUMNS - $ps1_len - 1;
	$till_eol_cols = 0 if $till_eol_cols < 0;

	$ps1 .=
		' 'x($till_eol_cols > 0) . '─'x$till_eol_cols . "\\n$perm{mark} ";

	$ps1;
}

sub get_static_ps1 {

	chomp(my $UID      = (decode_utf8 <>) + 0);
	chomp(my $HOSTNAME = decode_utf8 <>);
	my %perm = get_permission_mark $UID;

	$perm{color} .'\u'. c(RESET) .'@'. c(YELLOW) . $HOSTNAME . c(RESET) .
		':'. c(BLUE) .'\w'. c(RESET) .'\n'. $perm{mark} .' ';
}

sub get_relative_path {

	chomp(my $PWD  = decode_utf8 <>);
	chomp(my $USER = decode_utf8 <>);
	chomp(my $HOME = decode_utf8 <>);

	my $docker_dev_mask = qr[^/mnt/([0-9A-Za-z_-]+)/docker/$USER-dev(/|$)];

	my @masks = (
		qr[^/run/media/$USER/([0-9A-Za-z_-]+)/(home/)?$USER(/|$)],
		qr[^/media/$USER/([0-9A-Za-z_-]+)/(home/)?$USER(/|$)],
		qr[^/media/([0-9A-Za-z_-]+)/(home/)?$USER/(/|$)],
		qr[^/mnt/([0-9A-Za-z_-]+)/(home/)?$USER(/|$)],
		$docker_dev_mask,
		qr[^/usr/home/$USER(/|$)],
	);

	use autodie qw(:all);

	my $rel_path = eval {
		my $same_dir = sub { -d $_[0] && stat($PWD)->ino == stat($_[0])->ino };
		my $by_mask = sub { $PWD =~ $_[0]; ($1, substr($PWD, length $&)) };

		foreach my $mask (@masks) {
			next if $PWD !~ $mask;
			my ($mnt_name, $tail) = $by_mask->($mask);
			$tail = (length($tail) > 0) ? "/$tail" : '';

			my $new_wd =
				($PWD =~ $docker_dev_mask) ?
					"$HOME/docker-dev${tail}" :
					"$HOME/${mnt_name}${tail}";

			my $short_new_wd = "${HOME}${tail}";
			return '' unless $same_dir->($new_wd);
			return $same_dir->($short_new_wd) ? $short_new_wd : $new_wd;
		}

		return '' if length($PWD) < length($HOME) || $PWD !~ /^$HOME/;

		my $wd_tail = substr $PWD, length($HOME) +
			((length($PWD) > length($HOME)) ? 1 : 0);

		return '' if length($wd_tail) == 0;
		my @wd_tail = split '/', $wd_tail;
		undef $wd_tail;
		my $wd_sliced = "$HOME/" . join '/', splice @wd_tail, 1;
		$wd_sliced = $HOME if $wd_sliced eq "$HOME/";
		return '' unless $same_dir->($wd_sliced);
		return $wd_sliced;
	};

	no autodie;
	warn $@ if $@;
	$@ ? '' : $rel_path;
}

while (<>) {
	chomp;

	if ($_ eq 'get-ps1') {
		reply_for 'get-ps1', \&get_ps1;
	} elsif ($_ eq 'get-static-ps1') {
		reply_for 'get-static-ps1', \&get_static_ps1;
	} elsif ($_ eq 'get-relative-path') {
		reply_for 'get-relative-path', \&get_relative_path;
	} else {
		die "Unknown request: '$_'";
	}
}

# vim: set noet cc=81 tw=80 :
