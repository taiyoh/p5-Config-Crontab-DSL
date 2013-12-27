package
    Config::Crontab::Finder;

use strict;
use warnings;
use utf8;

use Time::Piece;

sub search_events {
    my ($self, $ct, $date) = @_;
    my $t = Time::Piece->strptime($date, '%Y-%m-%d %H:%M:%S');

    my @events = $ct->select(-type => 'event');
    my @founds;
    for my $event (@events) {
        next if $event->month ne '*' && !grep { $_ == $t->month } @{ _parse_time($event->month) };
        my $wday = _parse_time($event->dow eq '*' ? join(",", 0 .. 6) : $event->dow);
        my $day  = _parse_time($event->dom eq '*' ? join(",", 1 .. 31) : $event->dom);
        next if !grep { $_ == $t->day_of_week } @$wday || !grep { $_ == $t->day } @$day;
        next if $event->hour ne '*' && !grep { $_ == $t->hour } @{ _parse_time($event->hour) };
        next if $event->minute ne '*' && !grep { $_ == $t->minute } @{ _parse_time($event->minute) };
        push @founds, $event;
    }

    return @founds;
}

sub _parse_time {
    my $time = shift;
    $time =~ s{\s}{}g;
    my $every;
    ($time, $every) = __parse_every($time);
    my $time_list = __parse_range($time);
    return $time_list unless $every;

    my @results;
    for my $t (@$time_list) {
        push @results, $t if $t % $every == 0;
    }
    return \@results;
}

sub __parse_every {
    my $time = shift;
    split '/', $time;
}

sub __parse_range {
    my $time = shift;
    if ($time =~ /-/) {
        my ($t1, $t2) = split '-', $time;
        return [$t1 .. $t2];
    }
    return [split ',', $time];
}

1;
