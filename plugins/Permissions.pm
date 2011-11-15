package Permissions;
use strict;
use warnings;
use YAML::Syck qw(LoadFile);
use List::Util qw(first);

sub new {
	my ($class,$file)=@_;
	my $self={'nodes' => {}, 'player' => {}, 'group' => {}};
	bless $self,$class;
	$self->load($file);
	return $self;
}

sub load {
	my ($self,$file)=@_;
	$file=$file || 'permissions.yml';
	return if not -e $file;
	my $struct=LoadFile($file);
	$self->{'player'}=$struct->{'player'};
	$self->{'group'}=$struct->{'group'};
	return 1;
}

sub regnode { # TODO: Remove or make compulsory?
	my ($self,$node,$desc)=@_;
	my $pl=$self->_getpl();
	$self->{'nodes'}->{$pl}->{$node}=$desc;
}

sub nodes {
	my ($self,$pl)=@_;
	if ($pl) {
		return $self->{'nodes'}->{$pl};
	}else{
		return $self->{'nodes'};
	}
}

sub can {
	my ($self,$ref,@node)=@_;

	my $player = ref $ref eq 'IO::Socket::INET' ? $::srv->get_player($ref) : $ref; # This way we can pass a Player if we have that, or just the socket like everything else does.

	no warnings 'uninitialized'; #I don't want to duplicate every single test with a defined() test ... :/ #
	my $nodestr;
	if (scalar(@node) == 1 && $node[0] =~ /\./) {
		$nodestr=$node[0];
		@node=split /\./,$node[0];
	}else{
		$nodestr=join '.',@node;
	};
	foreach my $n (-1..scalar(@node)-1) {
		return 1 if $_ > 0 && first {$_ eq join '.',@node[0..$n]}     @{$self->{'player'}->{$player->{'username'}}};
		return 1 if first {$_ eq join '.',@node[0..$n],'*'} @{$self->{'player'}->{$player->{'username'}}};
	}
	return 1 if first {$_ eq $nodestr} @{$self->{'player'}->{$player->{'username'}}};
	foreach my $g (values %{$self->{'group'}}) {
		next unless first {$_ eq $player->{'username'}} @{$g->{'members'}};
		return 1 if first {$_ eq $nodestr} @{$g->{'nodes'}};
		foreach my $n (-1..scalar(@node)-1) {
			return 1 if $_ > 0 && first {$_ eq join '.',@node[0..$n]} @{$g->{'nodes'}};
			return 1 if first {$_ eq join '.',@node[0..$n],'*'} @{$g->{'nodes'}};
		}
	}
	return 0;
}

sub _getpl {
	my ($self)=@_;
	my $n=1;
	my $pkg;
	do {
		($pkg)=caller $n++;
		return if not defined $pkg;
	} while ($pkg eq __PACKAGE__);
	return $pkg;
}

1;