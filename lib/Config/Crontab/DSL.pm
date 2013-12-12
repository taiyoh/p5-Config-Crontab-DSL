package Config::Crontab::DSL;
use 5.008005;
use strict;
use warnings;

use parent 'Exporter';

use Config::Crontab;

our $VERSION = "0.0.1";
our @EXPORT = qw/
    crontab comment env
    job minute hour day day_of_week month command dump deactivate
    every range
    MON TUE WED THU FRI SAT SUN/;

my $pool = {};

sub import {
    my $class = shift;
    my $caller = scalar caller;

    $pool->{$caller} = {
        ct => Config::Crontab->new,
        block => undef,
        event => undef
    };

    $class->export_to_level(1);
}

sub dump {
    my $class = shift;
    $pool->{$class}{ct}->dump;
}

sub crontab(&) {
    my $caller = scalar caller;
    my $in_block_code = shift;
    $pool->{$caller}{block} = Config::Crontab::Block->new;
    $in_block_code->();
    $pool->{$caller}{ct}->last($pool->{$caller}{block});
    return;
}

sub comment($) {
    my $caller = scalar caller;
    my $comment = shift;

    return unless $pool->{$caller}{block};
    $pool->{$caller}{block}->last(Config::Crontab::Comment->new(
        -data => "## $comment"
    ));
}

sub env(@) {
    my $caller = scalar caller;
    my @args = @_;

    return unless $pool->{$caller}{block};
    while (my ($name, $value) = splice @args, 0, 2) {
        $pool->{$caller}{block}->last(Config::Crontab::Env->new(
            -name  => $name,
            -value => $value
        ));
    }
}

sub job(&) {
    my $caller = scalar caller;
    my $in_event_code = shift;
    return unless $pool->{$caller}{block};

    $pool->{$caller}{event} = Config::Crontab::Event->new;
    $in_event_code->();
    $pool->{$caller}{block}->last(delete $pool->{$caller}{event});
}

sub minute($) {
    my $caller = scalar caller;
    my $minute = shift;
    $minute = [$minute] unless ref $minute;
    return unless $pool->{$caller}{event};
    $pool->{$caller}{event}->minute(join ",", @$minute);
}

sub hour($) {
    my $caller = scalar caller;
    my $hour = shift;
    $hour = [$hour] unless ref $hour;
    return unless $pool->{$caller}{event};
    $pool->{$caller}{event}->hour(join ",", @$hour);
}

sub month($) {
    my $caller = scalar caller;
    my $month = shift;
    $month = [$month] unless ref $month;
    return unless $pool->{$caller}{event};
    $pool->{$caller}{event}->month(join ",", @$month);
}

sub day($) {
    my $caller = scalar caller;
    my $dom = shift;
    $dom = [$dom] unless ref $dom;
    return unless $pool->{$caller}{event};
    $pool->{$caller}{event}->dom(join ",", @$dom);
}

sub day_of_week($) {
    my $caller = scalar caller;
    my $dow = shift;
    $dow = [$dow] unless ref $dow;
    return unless $pool->{$caller}{event};
    $pool->{$caller}{event}->dow(join ",", @$dow);
}

sub command($) {
    my $caller = scalar caller;
    my $command = shift;
    return unless $pool->{$caller}{event};
    $pool->{$caller}{event}->command($command);
}

sub deactivate() {
    my $caller = scalar caller;
    return unless $pool->{$caller}{event};
    $pool->{$caller}{event}->active(0);
}

sub every($;$$) {
    if (@_ == 1) {
        return sprintf '*/%d', @_;
    }
    else {
        my ($p1, $p2) = @_;
        $p1 = join(",", @$p1) if ref $p1;
        return sprintf '%s/%d', $p1, $p2;
    }
}

sub range($$) {
    return sprintf '%d-%d', @_;
}

sub SUN() { 0 }
sub MON() { 1 }
sub TUE() { 2 }
sub WED() { 3 }
sub THU() { 4 }
sub FRI() { 5 }
sub SAT() { 6 }

1;
__END__

=encoding utf-8

=head1 NAME

Config::Crontab::DSL - It's new $module

=head1 SYNOPSIS

    use Config::Crontab::DSL;

=head1 DESCRIPTION

Config::Crontab::DSL is ...

=head1 LICENSE

Copyright (C) taiyoh.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

taiyoh E<lt>sun.basix@gmail.comE<gt>

=cut

