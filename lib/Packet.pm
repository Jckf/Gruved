#!/dev/null
package Packet;

use strict;
use warnings;

use constant {
	PING     => 0x00,
	LOGIN    => 0x01,
	HELLO    => 0x02,
	CHAT     => 0x03,
	TIME     => 0x04,
	USE      => 0x07,
	RESPAWN  => 0x09,
	GROUND   => 0x0A,
	POSITION => 0x0B,
	LOOK     => 0x0C,
	POSLOOK  => 0x0D,
	DIG      => 0x0E,
	PLACE    => 0x0F,
	SELECT   => 0x10,
	ANIMATE  => 0x12,
	ACTION   => 0x13,
	SPAWNN   => 0x14,
	REMOVE   => 0x1D,
	TELEPORT => 0x22,
	CHUNK    => 0x32,
	CHUNKD   => 0x33,
	BLOCK    => 0x35,
	CLOSE    => 0x65,
	CLICK    => 0x66,
	SLOT     => 0x67,
	CREATIVE => 0x6B,
	LIST     => 0xC9,
	STATUS   => 0xFE,
	QUIT     => 0xFF,

	RAW      => 0,
	BOOL     => 1,
	BYTE     => 2,
	INT      => 3,
	SHORT    => 4,
	LONG     => 5,
	FLOAT    => 6,
	DOUBLE   => 7,
	STRING16 => 8
};

1;
