#!/dev/null
package Performance;

# A different way to handle this could be to increment the sleep value as long as there are
# idle loops, the decrement if there are none (or the same with a threshold of other than 0).

use strict;
use warnings;
use Time::HiRes 'sleep';
use SocketFactory;
use Packet::Parser;

use constant DEBUG => 0;

sub new {
	my ($class) = @_;

	my $self = {
		'sf_tick'   => 0,
		'sf_idle'   => 0,
		'pp_filter' => 0,
		'mc_tick'   => 0,

		'utilization' => 1 # Pretend we have a lot to do to begin with so that we don't slow things down.
	};

	$::tick->bind(sub {
		if ($::srv->{'time'} % 20 == 0) {
			$self->{'utilization'} = 1 - ($self->{'sf_idle'} / $self->{'sf_tick'});

			if (DEBUG) {
				$::log->header('Benchmark');
				$::log->cyan('Utilization: ' . $self->{'utilization'});
				$::log->cyan('Total ticks: ' . $self->{'sf_tick'});
				$::log->cyan( 'Idle ticks: ' . $self->{'sf_idle'});
				$::log->cyan( 'Packets in: ' . $self->{'pp_filter'});
				$::log->cyan(   'MC ticks: ' . $self->{'mc_tick'});
				print "\n"; # Ooo, bad dog!
			}

			$self->{'sf_tick'}   = 0;
			$self->{'sf_idle'}   = 0;
			$self->{'pp_filter'} = 0;
			$self->{'mc_tick'}   = 0;
		}
	});

	$::sf->bind(SocketFactory::IDLE,sub {
		sleep 0.01 - $self->{'utilization'} / 100;
	});

	$::sf  ->bind(SocketFactory::TICK   ,sub { $self->{'sf_tick'  }++ });
	$::sf  ->bind(SocketFactory::IDLE   ,sub { $self->{'sf_idle'  }++ });
	$::pp  ->bind(Packet::Parser::FILTER,sub { $self->{'pp_filter'}++ });
	$::tick->bind(                       sub { $self->{'mc_tick'  }++ });

	bless($self,$class);
}

1;
