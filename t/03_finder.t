use strict;
use warnings;

use Test::More;
use t::Foo;

BEGIN { use_ok "Config::Crontab::Finder" };

subtest __parse_every => sub {
	my $method = Config::Crontab::Finder->can('__parse_every');

	my ($time, $every);
	($time, $every) = $method->('*');
	is $time, '*';
	ok !$every;

	($time, $every) = $method->('*/10');
	is $time, '*';
	is $every, 10;
};

subtest __parse_range => sub {
	my $method = Config::Crontab::Finder->can('__parse_range');

	my $range;
	$range = $method->(10);
	is scalar(@$range), 1;
	is $range->[0], 10;

	$range = $method->("10,23,36,49");
	is scalar(@$range), 4;
	is $range->[0], 10;
	is $range->[1], 23;
	is $range->[2], 36;
	is $range->[3], 49;

	$range = $method->("13-26");
	my $ref_range = [13 .. 26];
	is scalar(@$range), scalar(@$ref_range);
	my $cnt = 0;
	for my $i (@$ref_range) {
		is $range->[$cnt++], $i;
	}
};

subtest _parse_time => sub {
	my $method = Config::Crontab::Finder->can('_parse_time');

	my $result;

	$result = $method->(minute => "10,23,36,49");
	is scalar(@$result), 4;
	is $result->[0], 10;
	is $result->[1], 23;
	is $result->[2], 36;
	is $result->[3], 49;

	$result = $method->(day => '10-20/3');
	is scalar(@$result), 3;
	is $result->[0], 12;
	is $result->[1], 15;
	is $result->[2], 18;
};

subtest search_events => sub {
	my @events = t::Foo->search('2013-12-27 00:00:00');
	is scalar(@events), 2;
	is $events[0]->command, 'echo "hello!"';
	is $events[1]->command, 'echo "bar"';

	is scalar(t::Foo->search('2013-12-28 00:00:00')), 1;
	ok !t::Foo->search('2013-12-28 00:01:00');

	is scalar(t::Foo->search('2013-12-03 10:10:00')), 1;
	ok !t::Foo->search('2013-12-04 10:10:00');
	ok !t::Foo->search('2013-12-03 10:11:00');
	ok !t::Foo->search('2013-12-03 17:10:00');
	ok !t::Foo->search('2013-12-03 09:10:00');
};

done_testing;
