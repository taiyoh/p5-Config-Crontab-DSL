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

Config::Crontab::DSL - 

=head1 SYNOPSIS

    package Foo;

    use Config::Crontab::DSL;

    crontab {
        comment "hoge--";
        env FOO => "bar";
        job {
            minute 0;
            hour   0;
            day_of_week range MON, FRI;
            command 'echo "hello!"';
        };
        job {
            minute 1;
            hour   4;
            day    [11 .. 13];
            command 'echo "world!"';
            deactivate;
        };
        job {
            minute every 10;
            hour range 10, 16;
            day every range(1,10), 3;
            command 'echo foo';
        };
    };

    package main;

    print Foo->dump;

    __END__

    ## hoge--
    FOO=bar
    0 0 * * 1-5 echo "hello!"
    #1 4 11,12,13 * * echo "world!"
    */10 10-16 1-10/3 * * echo foo

=head1 DESCRIPTION

Config::Crontab::DSLはConfig::Crontabのラッパーモジュールで、書式を気にせず、構造を守って記述すれば、
正しいcrontabの内容が出力されるようになっています。


=head1 関数定義

=head4 class method

=over 4

=item dump

クラスメソッドとして使用します。
クラス内で生成されたcrontabの内容をテキストで出力します。

=back

=head4 DSL method

=over 4

=item crontab

crontabブロックの中で、実行するタスクを定義していきます。
上から定義された順番に出力されます


    crontab {
        ...
    };


=item env

環境変数はこの関数の引数を使って定義します。

    env FOO => 'bar', HOGE => 'fuga';
    # FOO=bar
    # HOGE=fuga

=item comment

コメントを挿入します

    comment "あいうえお"; # => ## あいうえお

=item job

メインとなる、実行時刻と実行コマンドの定義を行います

    job {
        ...
    };

=back

=head4 utility method

=over 4

=item every

何（分、時）おきに実行する、といった記法をサポートします。

    every 3; # => */3
    every "10-30", 5; # => 10-30/5
    every [10,14], 5; # => 10,11,12,13,14/5

=item range

何（分、時）から何（分、時）の間実行する、といった記法をサポートします。

    range 1,5; # => 1-5

=back

=head4 job attributes

以下の関数は、jobブロック内でのみ使用可能です。
また、Arrayリファレンスを渡すことで、カンマ区切りの数値の列が登録されます

    [1 .. 3] # => 1,2,3


=over 4

=item minute

何分に実行するかを定義します

=item hour

何時に実行するかを定義します

=item day

何日に実行するかを定義します

=item month

何月に実行するかを定義します

=item day_of_week

何曜日に実行するかを定義します。数字だけでなく、
MON,TUE,WED,THU,FRI,SAT,SUNという定数を渡すことも可能です。

=item command

実行するコマンドを定義します。

=item deactivate

jobの定義はしたが一時的に実行しないようにしたい、といった場合、
定義全体をコメントアウトして出力させないこともできますが、
deactivateと入れておくことで行頭に#を入れてコメントアウトさせることもできます。

=back

=head1 LICENSE

Copyright (C) tanaka-hirotaka.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tanaka-hirotaka E<lt>sun.basix@gmail.comE<gt>

=cut

