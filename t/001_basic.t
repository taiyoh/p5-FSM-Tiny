#!perl -w
use strict;
use Test::More;

use FSM::Simple;

#++$FSM::Simple::DEBUG;

my $count = 0;
my $str   = '';

my $fsm = FSM::Simple->new({
    on_enter => sub { $str .= "foo" },
    on_transition => sub { $str .= "bar" },
    on_exit => sub { $str .= "baz" },
    rules => {
        init => sub {
            my $state = shift;
            if ($count < 20) {
                $state->next('add');
            }
            else {
                $state->next('end');
            }
        },
        add => sub {
            ++$count;
            shift->next('init');
        },
        end => sub {
            $count *= 5;
        }
    }
});

$fsm->run;

is $count, 100, "state machine ran";

# (init -> add (-> init)) x 20 + end
is $str, "foo".("bar" x 41)."baz", "on_* event correctly fired";

done_testing;
