#!/dev/null
package Shutdown;

use strict;
use warnings;

sub new {
	my ($class) = @_;
	my $self = {};

	bless($self,$class);

	if (!$self->ready()) {
		$::onload->bind('Commands'   ,sub { $self->ready() });
		$::onload->bind('Permissions',sub { $self->ready() });
	}

	return $self;
}

sub ready {
	$_[0]->register() if (defined $::plugins{'Commands'} && defined $::plugins{'Permissions'});
}

sub register {
	$::plugins{'Commands'}->bind('shutdown',sub {
		if ($::plugins{'Permissions'}->can($_[1],'shutdown')) {
			$::sf->{'listener'}->close();
			undef $::sf->{'listener'};
		}
	});
}

1;
