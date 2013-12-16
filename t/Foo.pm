package t::Foo;

use strict;
use warnings;
use utf8;

use Config::Crontab::DSL;

crontab {
    comment "hoge--";
    env FOO => "bar";

    event {
        minute 0;
        hour   0;
        day_of_week range MON, FRI;
        command 'echo "hello!"';
    };

    event {
        minute 1;
        hour   4;
        day    [11 .. 13];
        command 'echo "world!"';
        deactivate;
    };

    event {
        minute every 10;
        hour range 10, 16;
        day every range(1,10), 3;
        command 'echo foo';
    };
};

1;
