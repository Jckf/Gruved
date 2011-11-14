#!/dev/null
package Time;

use strict;
use warnings;

sub new {
	my ($class) = @_;
	my $self = {};

	bless($self,$class);

	$self->{'loaded'}=0;
	
	if (!$self->checkload()) {
		$::onload->bind('Commands',sub {$self->checkload()});
		$::onload->bind('Permissions',sub {$self->checkload()});
	}

	return $self;
}

sub checkload {
	my ($self)=@_;
	if (defined $::plugins{'Commands'} && defined $::plugins{'Permissions'}) {
		$self->register();
		$self->{'loaded'}=1;
		return 1;
	}
	return 0;
}

sub register {
	$::plugins{'Commands'}->bind('time',sub {
		my ($e,$s,@args) = @_;
		my $p=$::srv->get_player($s);
		if (defined $args[0] && $::plugins{'Permissions'}->can($p,'time.set')) {
			if ($args[0] eq 'day') {
				$::srv->{'time'} = 6000;
			} elsif ($args[0] eq 'night') {
				$::srv->{'time'} = 18000;
			} else {
				$::srv->{'time'} = $args[0];
			}
		}
	});
}

1;
