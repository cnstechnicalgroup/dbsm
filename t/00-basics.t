use Test;

use DBSM;

plan 2;

# use
use-ok('DBSM');

# Constants
my $config_dir = $*HOME ~ "/.dbsm";
my $config_file = $config_dir ~ "/config";

# new
my $r1 = DBSM.new(config_file => $config_file);

isa-ok $r1, DBSM, 'new 3/3';
