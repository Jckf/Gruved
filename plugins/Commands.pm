#!/dev/null
package Commands;

use strict;
use warnings;
use Events;

sub new {
	my ($class) = @_;
	my $self = {};

	$self->{'events'} = Events->new();

	$::pp->bind(0x03,sub {
		my ($e,$s,$m) = @_;
		my $p = $::srv->get_player($s);

		if (substr($m,0,1) eq '/') {
			$e->{'cancelled'} = 1;
			my @d = split(' ',substr($m,1));
			my $c = shift @d;
			$self->{'events'}->trigger($c,$s,@d);
		}
	});

	bless($self,$class);
}

sub bind {
	$_[0]->{'events'}->bind($_[1],$_[2]);
}
