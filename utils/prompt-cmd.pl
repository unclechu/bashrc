#!/usr/bin/env perl
use v5.10; use strict; use warnings;
use Term::ANSIColor qw<:constants>;
use File::Basename qw<basename dirname>;
use File::Spec qw<devnull>;

# Wrapper for coloring special symbols
# to prevent bash from calculating
# line length including these symbols.
sub c {'\[' . shift . '\]'}

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

sub get_ps1 {

	chomp(my $USER           = <>);
	chomp(my $UID            = <>);
	chomp(my $HOME           = <>);
	chomp(my $PWD            = <>);
	chomp(my $LOCAL_HOSTNAME = <>);
	chomp(my $VIRTUAL_ENV    = <>);
	chomp(my $COLUMNS        = <>);

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

	my $permission_color = ($UID == 0) ? c(RED) : c(GREEN);

	my $permission_mark =
		$permission_color . (($UID == 0) ? '#' : '$') . c(RESET);

	my $init_ps1 = sub {
		$pyvenv_view . $permission_color . $USER . c(RESET) .
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
		' 'x($till_eol_cols > 0) . '─'x$till_eol_cols . "\\n$permission_mark ";

	$ps1;
}

$|++;
while (<>) {
	chomp;
	if ($_ eq 'get-ps1') {
		say get_ps1;
		say 'end-get-ps1';
	} else {
		die "Unknown request: '$_'";
	}
}

# vim: set noet cc=81 tw=80 :
