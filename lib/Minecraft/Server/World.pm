#!/dev/null
package Minecraft::Server::World;

use strict;
use warnings;

sub new {
	my ($class,%options) = @_;
	my $self = {};

	$self->{'chunks'} = {};

	$self->{$_} = $options{$_} for keys %options;

	bless($self,$class);
}
