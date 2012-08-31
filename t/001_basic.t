#!perl -w
use strict;
use Test::More;

use FSM::Simple;

my $count = 0;

my $fsm = FSM::Simple->new({
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

done_testing;
