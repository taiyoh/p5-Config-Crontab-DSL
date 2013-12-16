use strict;
use warnings;

use Test::More;
use t::Foo;

my @envs = t::Foo->find('env');

is scalar(@envs), 1;
my $env = $envs[0];

is $env->name, 'FOO';
is $env->value, 'bar';

my @jobs = t::Foo->find('job');

is scalar(@jobs), 3;

my @commands = (
    'echo "hello!"',
    'echo "world!"',
    'echo foo'
);

for my $cmd (@commands) {
    my $job = shift @jobs;
    is $job->command, $cmd;
}

done_testing;
