package Permissions;
use strict;
use warnings;
use YAML::Syck qw(LoadFile);
use List::Util qw(first);

sub new {
	my ($class)=@_;
	my $self={'nodes' => {}, 'player' => {}, 'group' => {}};
	bless $self,$class;
	$self->load();
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

sub regnode {
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
	my ($self,$player,@node)=@_;
	no warnings 'uninitialized';
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

sub command { #Convenience function - registers command as node as well, and checks permissions
	my ($self,$command,$node,$desc,$sub)=@_;
	$self->regnode($node,$desc);
	my @cmdparts=($command);
	if ($command =~ / /) {
		@cmdparts=split / /,$command;
	}
	$::plugins{'Commands'}->bind(shift @cmdparts,sub {
		my ($e,$s,@args) = @_;
		foreach (0..scalar(@cmdparts)) {
			return if $args[$_] != $cmdparts[$_];
		}
		$e->{'cancelled'}=1;
		my $p=$::srv->get_player($s);
		if ($self->can($p,$node)) {
			$sub->(@_);
		}else{
			$p->message("You don't have permission for $command ($desc)");
		}
	});
}

sub _getpl {
	my ($self)=@_;
	my $n=0;
	my $pkg;
	do {
		($pkg)=caller $n++;
		return if not defined $pkg;
	} while ($pkg eq __PACKAGE__);
	return $pkg;
}

1;