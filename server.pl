#!/usr/bin/perl
use strict;
use warnings;
use lib './lib';
use Minecraft::Server;

my $server = Minecraft::Server->new();

$server->run();
