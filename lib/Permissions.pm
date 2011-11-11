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
	$sub=$desc if ref $desc eq 'CODE';
	$sub=$node if ref $node eq 'CODE';
	$desc='' if ref $desc eq 'CODE';
	my @cmdparts=($command);
	if ($command =~ / /) {
		@cmdparts=split / /,$command;
	}
	$node=$self->_getpl().'.'.($node && ref $node ne 'CODE' ? $node : join '.',@cmdparts) ;
	$self->regnode($node,$desc) if not defined $self->{'nodes'}->{$self->_getpl()}->{$node};
	$::plugins{'Commands'}->bind(shift @cmdparts,sub {
		my ($e,$s,@args) = @_;
		if (scalar(@cmdparts)) {
			foreach (0..scalar(@cmdparts)) {
				last if not $cmdparts[$_];
				return if (shift @args || '') ne ($cmdparts[$_]);
			}
		}
		my $p=$::srv->get_player($s);
		if ($self->can($p,$node)) {
			if ($sub->($e,$s,@args)) {
				$e->{'cancelled'}=1;
			}
		}else{
			$p->message("You don't have permission for $command ($desc)");
			$e->{'cancelled'}=1;
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