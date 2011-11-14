#!/dev/null
package Shutdown;

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
	if (defined $::plugins{'Commands'} && defined $plugins{'Permissions'}) {
		$self->register();
		$self->{'loaded'}=1;
		return 1;
	}
	return 0;
}

sub register {
	$::plugins{'Commands'}->bind('shutdown',sub {
		my ($e,$s,@args) = @_;
		if ($::plugins{'Permissions'}->can($::srv->get_player($s),'shutdown')) {
			exit;
		}
	});
}

1;
