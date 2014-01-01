package
    Config::Crontab::Finder;

use strict;
use warnings;
use utf8;

use Time::Piece;

my $replace = {
    month  => [1 .. 12],
    wday   => [0 .. 6],
    day    => [1 .. 31],
    hour   => [0 .. 23],
    minute => [0 .. 59]
};

my $special_map = {
    yearly   => {month => 1, dom => 1, hour => 0, minute => 0},
    annually => {month => 1, dom => 1, hour => 0, minute => 0},
    monthly  => {dom => 1, hour => 0, minute => 0},
    weekly   => {dow => 0, hour => 0, minute => 0},
    daily    => {hour => 0, minute => 0},
    midnight => {hour => 0, minute => 0},
    hourly   => {minute => 0},
};

sub search_events {
    my ($class, $ct, $date) = @_;
    my $t = Time::Piece->strptime($date, '%Y-%m-%d %H:%M:%S');

    my @events = $ct->select(-type => 'event');
    my @founds;
    for my $event (@events) {
        if (my $special = $event->special) {
            $special =~ s{^@}{};
            my $map = $special_map->{$special} or next;
            for my $key (qw/month dom dow hour minute/) {
                my $val = exists $map->{$key} ? $map->{$key} : '*';
                $event->$key($val);
            }
        }
        next if !grep { $_ == $t->mon } @{ _parse_time(month => $event->month) };
        next if !(grep { $_ == $t->day_of_week } @{ _parse_time(wday => $event->dow) })
             || !(grep { $_ == $t->mday } @{ _parse_time(day => $event->dom) });
        next if !grep { $_ == $t->hour } @{ _parse_time(hour => $event->hour) };
        next if !grep { $_ == $t->minute } @{ _parse_time(minute => $event->minute) };
        push @founds, $event;
    }

    return @founds;
}

sub _parse_time {
    my ($type, $time) = @_;
    $time =~ s{\s}{}g;
    $time =~ s{\*}{join(",", @{ $replace->{$type} || [] })}e;
    my $every;
    ($time, $every) = __parse_every($time);
    my $time_list = __parse_range($time);
    return $time_list unless $every;

    my @results;
    for my $t (@$time_list) {
        push @results, int($t) if $t % $every == 0;
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
    return [map { int } split ',', $time];
}

1;
