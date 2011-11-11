#!/dev/null
package Utils;

use lib 'lib';
use Packet;
use strict;
use warnings;
use List::Util 'min';

sub new {
	my ($class) = @_;
	my $self = {};
	no warnings;
	my ($k,$v);
	my %nodes=(
		'utils.world.goto' => '/world goto <world>, /world <world>',
		'utils.world.save' => '/world save <world>',
		'utils.world.new' => '/world new <world>',
		'utils.tp.unstuck' => '//unstuck',
		'utils.gamemode' => '/gamemode',
		'utils.listnodes' => '/listnodes');
	foreach (keys %nodes) {
		$::perm->regnode($_,$nodes{$_});
	}
	
	$::plugins{'Commands'}->bind('world',sub {
		my ($e,$s,@args) = @_;
		my $p=$::srv->get_player($s);
		if ($args[0] eq 'save' and $::perm->can($p,'utils.world.save')) {
			$p->{'entity'}->{'world'}->save();
			$p->message('Saving world...');
		}elsif ($args[0] eq 'new') {
			$::worlds{$args[1]}=World->new(
				name => $args[1]
			);
			$p->message('Created world '.$args[1]);
		}elsif ($args[0] eq 'goto') {
			if ($::worlds{$args[1]}) {
				goto_world($p,$args[1]);
			}else{
				$p->message('No such world: '.$args[1]);
			}
		}else{
			if ($::worlds{$args[0]}) {
				goto_world($p,$args[0]);
			}else{
				$p->message('No such world or command: '.$args[0]);
			}
		}
	});

	$::plugins{'Commands'}->bind('/unstuck',sub {
		my ($e,$s,@args)=@_;
		my $p=$::srv->get_player($s);
		$p->{'entity'}->{'y'}+=2;
		$p->{'entity'}->{'y2'}+=2;
		$p->update_position();
	});
	
	$::plugins{'Commands'}->bind('gamemode',sub {
		my ($e,$s,@args)=@_;
		my $p=$::srv->get_player($s);
		$p->update_gamemode($args[0]);
	});
	
	$::plugins{'Commands'}->bind('listnodes',sub {
		my ($e,$s,@args)=@_;
		my $p=$::srv->get_player($s);
		my $pl;
		$pl=shift @args if $args[0]!~/^[\d]+$/; 
		my @lines;
		my $nodes=$::perm->nodes($pl);
		foreach (sort keys %{$nodes}) {
			if ($pl) {
				push @lines, [$_,$nodes->{$_}]
			}else{
				push @lines, ' --- '.$_.' --- ';
				my $pl=$nodes->{$_};
				foreach (sort keys %{$pl}) {
					push @lines, [$_,$pl->{$_}];
				}
			}
		}
		$p->message($_) foreach tabulate(\@lines,$args[0]);
	});
	
	bless($self,$class);
};

sub tabulate {
	my ($data,$page)=@_;
	$page=0 if not $page;
	my @data=@{$data}[$page*6..min(scalar(@$data),($page*6)+6)];
	my @lines;
	my @cols;
	foreach my $r (@data) {
		next unless ref $r eq 'ARRAY';
		foreach my $c (0..scalar(@$r)) {
			$cols[$c]=length($r->[$c]) if (length($r->[$c]) || 0) > ($cols[$c] || 0);
		}
	}
	foreach my $r (@data) {
		if (ref $r eq 'ARRAY') {
			my $l;
			foreach my $c (0..scalar(@$r)) {
				$l.=sprintf '%-'.(($cols[$c] || 0)+2).'s', ($r->[$c] || '');
			}
			push @lines,$l;
		} elsif (defined $r) {
			push @lines, $r;
		}
	}
	return @lines;
}

sub goto_world {
	my ($p,$world)=@_;
	$p->message('Whoosh!');
	$p->{'entity'}->{'world'}=$::worlds{$world};
	foreach my $o ($::srv->get_players()) {
		next if $o->{'username'} eq $p->{'username'};
		if ($o->{'entity'}->{'world'}->{'name'} eq $::worlds{$world}->{'name'}) {
			$p->load_entity_named($o->{'entity'});
			$o->load_entity_named($p->{'entity'});
		} else {
			$o->send(
				$::pf->build(
					Packet::REMOVE,
					$p->{'entity'}->{'id'}
				)
			);
			$p->send(
				$::pf->build(
					Packet::REMOVE,
					$o->{'entity'}->{'id'}
				)
			);
		}
	}
	$p->update_chunks();
	$p->{'entity'}->{'y'}+=0.25;
	$p->{'entity'}->{'y2'}+=0.25;
	$p->update_position();
}
1;
