package Permissions;
use strict;
use warnings;
use YAML::Syck 'LoadFile';
use List::Util 'first';

sub new {
	my ($class,$file) = @_;

	my $self = {
		'nodes' => {},
		'player' => {},
		'group' => {}
	};

	bless($self,$class);

	$self->load($file);

	*Player::has_permission = \&_check;

	return $self;
}

sub load {
	my ($self,$file) = @_;
	$file = 'permissions.yml' if !defined $file;

	return if !-e $file;

	my $struct = LoadFile($file);

	$self->{'player'} = $struct->{'player'};
	$self->{'group'} = $struct->{'group'};

	return 1;
}

sub regnode { # TODO: Remove or make compulsory?
	$_[0]->{'nodes'}->{$_[0]->_getpl()}->{$_[1]} = $_[2];
}

sub nodes {
	my ($self,$pl) = @_;

	return $self->{'nodes'}->{$pl} if defined $pl;
	return $self->{'nodes'};
}

sub _check {
	my ($player,$ref,@node) = @_;
	my $self = $::plugins{'Permissions'}; # Quick fix for monkey-patching _check() to Player::has_permission().
	
	no warnings 'uninitialized'; #I don't want to duplicate every single test with a defined() test ... :/ #

	my $nodestr;
	if (scalar(@node) == 1 && $node[0] =~ /\./) {
		$nodestr = $node[0];
		@node = split(/\./,$node[0]);
	} else {
		$nodestr = join('.',@node);
	}

	foreach my $n (-1 .. @node - 1) {
		return 1 if $_ > 0 && first { $_ eq join('.',@node[0 .. $n]) } @{$self->{'player'}->{$player->{'username'}}};
		return 1 if first { $_ eq join('.',@node[0 .. $n],'*') } @{$self->{'player'}->{$player->{'username'}}};
	}

	return 1 if first { $_ eq $nodestr } @{$self->{'player'}->{$player->{'username'}}};
	
	foreach my $g (values %{$self->{'group'}}) {
		next unless first { $_ eq $player->{'username'} || $_ eq '*' } @{$g->{'members'}};
		return 1 if first { $_ eq $nodestr } @{$g->{'nodes'}};

		foreach my $n (-1 .. @node - 1) {
			return 1 if $_ > 0 && first { $_ eq join('.',@node[0 .. $n]) } @{$g->{'nodes'}};
			return 1 if first { $_ eq join('.',@node[0..$n],'*') } @{$g->{'nodes'}};
		}
	}

	return 0;
}

sub _getpl {
	my ($self) = @_;

	my $n = 1;
	my $pkg;
	do {
		($pkg) = caller $n++;
		return if !defined $pkg;
	} while ($pkg eq __PACKAGE__);

	return $pkg;
}

1;
