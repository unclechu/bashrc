#! /usr/bin/env perl6
use v6;
close $*IN;
my Int \LineLimit := 60;
my Str \TimeIsUp  := 'Time is up!';
my Str \BS        := "\c[BACKSPACE]";
my Str \UP        := "\c[ESCAPE][1A";

class Dzen {
  has Promise     $.promise;
  has Proc::Async $.proc;
}

sub show-message(Str $message --> Dzen) {
  my Str @args = Q:w <dzen2 -p -bg red -fg white -fn -*-Hack-bold-*-*-*-72-*-*-*-*-*-*-*>;
  my Proc::Async $proc := Proc::Async.new(:w, |@args);
  my Promise $promise := $proc.start;
  await $proc.say: $message;
  $proc.close-stdin;

  my Promise $top-promise := start {
    try {
      await $promise;

      CATCH {
        when .message ~~ /'(exit code: 13)'/ {.resume}
        default {.rethrow}
      }
    }
  };

  Dzen.new(:promise($top-promise), :proc($proc));
}

sub view-duration(Duration $dur is copy, Str $pfx --> Str) {
  sub s(Int $x, Str $c --> Str) {
    return '' if $x == 0;
    " $x $c" ~ ($x == 1 ?? '' !! 's');
  }

  my Int $r-days := floor $dur / 60 / 60 / 24;
  $dur -= $r-days * 60 * 60 * 24;
  my Int $r-hours := floor $dur / 60 / 60;
  $dur -= $r-hours * 60 * 60;
  my Int $r-minutes := floor $dur / 60;
  $dur -= $r-minutes * 60;
  my Int $r-seconds := floor $dur;

  my Str $view = "{$pfx}: " ~ ((
    s($r-days, 'day'),
    s($r-hours, 'hour'),
    s($r-minutes, 'minute'),
    s($r-seconds, 'second'),
  ).join.&{$_ || ' '}.substr(1)) ~ '…';

  $view ~ ' ' x LineLimit - $view.chars;
}

sub MAIN(Str :m(:$message) = TimeIsUp, Bool :s(:$silent) = False, *@delays) {
  my Int $delay = 0;

  for @delays {
    when /^ (\d+) (d|h|m|s)? $/ {
      given $1 {
        when 'd' {$delay += $0 * 60 * 60 * 24}
        when 'h' {$delay += $0 * 60 * 60}
        when 'm' {$delay += $0 * 60}
        when $_ ~~ 's' || $_ ~~ Nil {$delay += $0}
        default {die "Unexpected value: $1"}
      }
    }

    default {die "Incorrect argument: $_"}
  }

  my DateTime $start-time := DateTime.now;
  my DateTime $delay-time := DateTime.new: $start-time.posix + $delay + 1;
  my DateTime $now = $start-time;
  print "\n\n" unless $silent;

  sub wait() {
    sleep $delay-time.posix - $now.posix - 1 > 0 ?? 1 !! 0.1;
    $now = DateTime.now;
  }

  while $delay-time > $now {
    {wait; next} if $silent;
    my Duration $spent := $now - $start-time;
    my Duration $remains := $delay-time - $now;
    say UP x 2 ~ view-duration($spent, 'Spent') ~ "\n" ~ view-duration($remains, 'Remains');
    wait;
  }

  say UP ~ TimeIsUp ~ ' ' x LineLimit - TimeIsUp.chars;
  my Dzen $dzen := show-message($message);

  my Promise $overspent-promise := $silent ?? Promise.new !! start {
    my DateTime $time-is-up-time := DateTime.now;

    loop {
      sleep 1;
      $now = DateTime.now;
      say UP ~ view-duration($now - $time-is-up-time, 'Overspent');
    }
  };

  await Promise.anyof($dzen.promise, $overspent-promise);
  $dzen.proc.kill;
}

# vim:cc=101:tw=100:et:ts=2:sw=2:sts=2:
