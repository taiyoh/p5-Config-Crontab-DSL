use strict;
use warnings;

use Test::More;
use t::Foo;

my @events = t::Foo->search('2013-12-27 00:00:00');
is scalar(@events), 1;
is $events[0]->command, 'echo "hello!"';

ok !t::Foo->search('2013-12-28 00:00:00');

done_testing;
