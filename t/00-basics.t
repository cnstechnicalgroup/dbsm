use Test;
use DBSM;

plan 2;

# use
use-ok 'DBSM', 'use 1/2';

# Constants
my $config_dir = $*HOME ~ "/.dbsm";
my $config_file = $config_dir ~ "/config";

# Set config

# use config
my $r1 = DBSM::config($config_file);

isa-ok $r1, (Str), 'config 2/2';
