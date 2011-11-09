#!/dev/null
package Platform;

use strict;
use warnings;

use constant BITS => eval { pack('q',1) } ? 64 : 32;

1;
