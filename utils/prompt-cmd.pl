use v5.10; use strict; use warnings;
use Term::ANSIColor qw<:constants>;
use File::Basename qw<basename dirname>;
use File::Spec qw<devnull>;

my $USER, my $UID, my $HOME, my $PWD;
my $LOCAL_HOSTNAME, my $VIRTUAL_ENV, my $COLUMNS;

BEGIN {
	($USER, $UID, $HOME, $PWD, $LOCAL_HOSTNAME, $VIRTUAL_ENV, $COLUMNS) = @ARGV;
	@ARGV = ();
}

# Removes coloring from string.
# Useful to count string length.
sub text {
	local $_ = $_[0] if defined $_[0];
	s/\x1b\[[0-9;]*m//g;
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

# Replacing $HOME in path with tilda
my $pwd_view =
	($PWD eq $HOME) ? '~' :
	($PWD =~ /^$HOME/) ? '~' . substr($PWD, length $HOME) :
	$PWD;

# Detecting remote mount point
my $remote_view = (compose \&nullout, \&nullerr)->(sub {
	my $remote_view = " (@{[RED]}remote@{[RESET]})";
	$_ = `df -l -T -- $PWD`;
	return $remote_view if $? == 1; # works on gnu/linux
	@_ = split "\n", $_;
	@_ = split / +/, $_[1];
	return $remote_view if $_[1] =~ /^fusefs(\.|$)/; # works on freebsd
	'';
});

my $pyvenv_view = (! $VIRTUAL_ENV) ? '' : sprintf '(pyvenv: %s) ',
	MAGENTA . basename($VIRTUAL_ENV, dirname $VIRTUAL_ENV) . RESET;

my $permission_color = ($UID == 0) ? RED : GREEN;
my $permission_mark = $permission_color . (($UID == 0) ? '#' : '$') . RESET;

sub get_ps1 {
	$pyvenv_view . $permission_color . $USER . RESET .
		'@' . YELLOW . $LOCAL_HOSTNAME . RESET .
		':' . BLUE . $pwd_view . RESET .  $remote_view;
}

my $ps1 = get_ps1;
my $ps1_len = length text $ps1;

if ($ps1_len > $COLUMNS) {
	my $min = 16;
	my $pwd_chars_count = $ps1_len - $COLUMNS + 1;
	my $diff = length(text $pwd_view) - $pwd_chars_count;
	$pwd_chars_count += $diff - $min if $diff < $min;

	$pwd_view =
		'…'x(length(text $pwd_view) > $min) .
		substr $pwd_view, $pwd_chars_count;

	$ps1 = get_ps1;
	$ps1_len = length text $ps1;
}

# TODO FIXME colors adds buggy cursor shift when listing history
$permission_mark = text $permission_mark;

my $till_eol_cols = $COLUMNS - $ps1_len - 1;
$till_eol_cols = 0 if $till_eol_cols < 0;
$ps1 .= ' 'x($till_eol_cols > 0) . '─'x$till_eol_cols . "\n$permission_mark ";

print $ps1;

# vim: set noet cc=81 tw=80 :
