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
	
	$::cmd->command('world','world.goto',undef,sub {
		my ($e,$s,@args)=@_;
		my $p=$::srv->get_player($s);
		if ($::worlds{$args[0]}) {
			goto_world($p,$args[0]);
		}else{
			$p->message('No such world: '.$args[0]);
		}
		return 0;
	});
	
	$::cmd->command('world goto',undef,'Go to a world',sub {
		my ($e,$s,@args)=@_;
		my $p=$::srv->get_player($s);
		if ($::worlds{$args[0]}) {
			goto_world($p,$args[0]);
		}else{
			$p->message('No such world: '.$args[0]);
		}
		return 1;
	});
	
	$::cmd->command('world save',undef,'Save the current world',sub {
		my ($e,$s,@args)=@_;
		my $p=$::srv->get_player($s);
		$p->message('Saving world...');
		$p->{'entity'}->{'world'}->save();
		return 1;
	});
	
	$::cmd->command('world new',undef,'Create a new world',sub {
		my ($e,$s,@args)=@_;
		my $p=$::srv->get_player($s);
		$p->message('Creating world '.$args[0]);
		return 1;
	});

	$::cmd->command('/unstuck','tp.unstuck','Teleport 2 blocks up',sub {
		my ($e,$s,@args)=@_;
		my $p=$::srv->get_player($s);
		$p->{'entity'}->{'y'}+=2;
		$p->{'entity'}->{'y2'}+=2;
		$p->update_position();
		return 1;
	});
	
	$::cmd->command('gamemode',undef,'Changes game mode to creative and back',sub {
		my ($e,$s,@args)=@_;
		my $p=$::srv->get_player($s);
		$args[0]=!$p->{'gamemode'} if not $args[0];
		$p->update_gamemode($args[0]);
		return 1;
	});
	
	$::cmd->command('listnodes',undef,'Lists permission nodes',sub {
		my ($e,$s,@args)=@_;
		my $p=$::srv->get_player($s);
		my $pl;
		$pl=shift @args if $args[0]!~/^[\d]+$/; 
		my @lines;
		my $nodes=$::cmd->nodes($pl);
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
		return 1;
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
	$p->{'chunks_loaded'}={};
	$p->update_chunks();
	$p->{'entity'}->{'y'}+=0.25;
	$p->{'entity'}->{'y2'}+=0.25;
	$p->update_position();
}
1;
