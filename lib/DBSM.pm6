use v6;
unit module DBSM;

use Config::INI;
use Config::INI::Writer;
use JSON::Tiny;

# Config basics
our $config_file;
our $config_dir;
our $project_root;

# Commands
our %commands = git => "/usr/bin/env git",
             pass => "/usr/bin/env pass";

# DB commands using code objects as templates
our %dbs = mysql => -> %params {qq:to/EOF/;
                                /usr/bin/env mysql %params<options> 
                                -h %params<db_host> 
                                -u %params<user_name> 
                                -p%params<pass> %params<db_name> < %params<script_path>
                                EOF
                               },
          sqlcmd => -> %params {qq:to/EOF/;
                                /usr/bin/env sqlcmd %params<options> 
                                -S %params<db_host>
                                -U %params<user_name>
                                -P '%params<pass>'
                                -i %params<script_path>
                                -W -w 1024 -s'￥' -I
                                EOF
                               },
          pgsql => "/usr/bin/env psql",
          mongo => "/usr/bin/env mongo",
          redis => "/usr/bin/env redis-cli";

# Git
our $git_dir;

# Pass
our $pass_generate;
our $pass_insert;
our $pass_edit;
our $pass_show;
our $pass_pw_len;
our $pass_prefix;

# Script Editor
our $editor;
our $scripts_root;

sub escape ($str) {
  # Puts a slash before non-alphanumeric characters
  S:g[<-alpha -digit>] = "\\$/" given $str
}

sub project_exists(Str $project_name) {
  my %conf = load_config($config_file);
  return %conf.keys.grep({ / $project_name / }).elems > 0;
}

sub path_exists(Str $path, Str $type) {
  if $type ~~ 'f' { return $path.IO ~~ :f }
  if $type ~~ 'd' { return $path.IO ~~ :d }
}

sub script_path(Str $project_name, Str $script_name) {
  my $script_folder = $scripts_root ~ "/$project_name";
  if !path_exists($script_folder, 'd') { mkdir $script_folder }
  return $script_folder ~ "/$script_name";
}

sub config_dir(Str $config_file) {
  $config_dir = IO::Path.new("$config_file").parent.Str; 
}

sub load_config(Str $config_file) {
  if !path_exists($config_file, 'f') { return say "No projects exists. See ./dbsm init" }
  return Config::INI::parse_file($config_file);
}

our sub config(Str $config) {
  $config_file = $config;
  $config_dir = IO::Path.new("$config_file").parent.Str; 
  $project_root = $config_dir ~ "/projects";

  # Git
  $git_dir = $config_dir ~ "/.git";

  # Script Editor
  $editor = "/usr/bin/env vim";
  $scripts_root = $config_dir ~ "/scripts";

  # Pass
  $pass_generate = %commands<pass> ~ " generate -c ";
  $pass_insert = %commands<pass> ~ " insert ";
  $pass_edit = %commands<pass> ~ " edit ";
  $pass_show = %commands<pass> ~ " show ";
  $pass_pw_len = 40;
  $pass_prefix = "dbsm";
}

our sub init( Str $config_file, 
          Str $project_name,
          Str $environment,
          Str $db_type where { so $db_type ∈ %dbs.keys },
              :$generate?, :$pw_len?) {

  my %conf;

  # Create config entry
  if (path_exists($config_file, 'f')) {
    say "Reading from config...";
    %conf = load_config($config_file);
  } else {
    say "Creating config...";
    if !path_exists($config_dir, 'd') { mkdir $config_dir }
  }

  my $db_host = prompt("Please enter DB host: ");
  my $db_name = prompt("Please enter DB name: ");
  my $user_name = prompt("Please enter DB user_name: ");

  %conf{"$project_name $environment"}<db_type> = $db_type;
  %conf{"$project_name $environment"}<db_host> = $db_host;
  %conf{"$project_name $environment"}<db_name> = $db_name;
  %conf{"$project_name $environment"}<user_name> = $user_name;
  Config::INI::Writer::dumpfile(%conf, $config_file);

  # Store password in pass
  my $pass_entry = "$pass_prefix/$project_name/$environment/$db_name/$user_name";
  if ($generate) {
    my $len = $pw_len ?? $pw_len !! $pass_pw_len;
    shell("$pass_generate $pass_entry $len");
  } else {
    shell("$pass_insert $pass_entry");
  }
}

our sub project_list {
  my %conf = load_config($config_file);
  return %conf.keys.sort
}

our sub project_vars(Str $project_name, 
                     Str $environment,
                     $echopass?) {

  # Confirm project exists
  if ( !project_exists("$project_name $environment") ) {
    return say("Project [$project_name $environment] doesn't exist. See ./dbsm init");
  }

  # Read config
  my %conf = load_config($config_file);
  my $db_host = %conf{"$project_name $environment"}<db_host>;
  my $db_name = %conf{"$project_name $environment"}<db_name>;
  my $user_name = %conf{"$project_name $environment"}<user_name>;

  # Echo password?
  my $pass;
  if ($echopass) {
    my $command = "$pass_show $pass_prefix/$project_name/$environment/$db_name/$user_name";
    $pass = escape shell($command, :out).out.slurp-rest.chomp();
  }

  # Create env variables
  my %project_vars = db_host => $db_host,
                     db_name => $db_name,
                     db_username => $user_name;
  if $echopass { 
    %project_vars<db_password> = $pass;
  }

  return %project_vars;

}

our sub script_add(Str $project_name, Str $script_name) {

  if ( !project_exists($project_name) ) {
    return "Project [$project_name] doesn't exist. See ./dbsm init";
  }

  my $script_path = script_path($project_name, $script_name);
  
  if ( path_exists($script_path, 'f') ) { 
    my $to_edit = 'y';
    $to_edit = prompt("Script already exists. Edit? (yN)");
    return if $to_edit.match(/n|N/);
  }

  shell($editor ~ " $script_path");
  return "New script, $script_path, added";

}

our sub script_run(Str $project_name,
                   Str $environment,
                   Str $script_name) {

  if ( !project_exists("$project_name $environment") ) {
    return say("Project [$project_name $environment] doesn't exist. See ./dbsm init");
  }

  my $script_path = script_path($project_name, $script_name);

  if ( !path_exists($script_path, 'f') ) {
    return say("Script, $script_name, doesn't exist. See ./dbsm script run");
  }

  my %conf = load_config($config_file);
  my %params = db_type => %conf{"$project_name $environment"}<db_type>,
               db_host => %conf{"$project_name $environment"}<db_host>,
               db_name => %conf{"$project_name $environment"}<db_name>,
               user_name => %conf{"$project_name $environment"}<user_name>,
               options => '',
               script_path => $script_path;

  my $command = "$pass_show $pass_prefix/$project_name/$environment/%params<db_name>/%params<user_name>";
  %params<pass> = shell($command, :out).out.slurp-rest.chomp();
  shell( %dbs{%params<db_type>}( %params ).subst(/\n/, ' ', :g) );

}

our sub script_list(Str $project_name) {

  if ( !project_exists("$project_name") ) {
    return say("Project [$project_name] doesn't exist. See ./dbsm init");
  }

  my $script_folder = $scripts_root ~ "/$project_name";
  if !path_exists($script_folder, 'd') { return "No scripts available for $project_name." }

  my @scripts = dir $script_folder;
  return @scripts.sort;

}

our sub git_init {
  if path_exists($git_dir, 'd') { return "Git repository already exists [$git_dir]" }
  shell("cd $config_dir; %commands<git> init"); 
}

our sub git_remote_origin(Str $url) {
  if !path_exists($git_dir, 'd') { return "Git repository not initialized. See ./dbsm git init" }
  my @out = shell("cd $config_dir; %commands<git> remote add origin $url 2>&1", :out).out.slurp-rest.chomp(); 
  # Return error message if returned
  return @out.Str if @out.Str !~~ '';
  return "Remote origin [$url] added.";
}

our sub git_push {
  if !path_exists($git_dir, 'd') { return "Git repository not initialized. See ./dbsm git init" }
  my $command = "cd $config_dir; %commands<git> add .; %commands<git> commit -a -m'[dbsm] updates'; %commands<git> push -u origin master";
  shell($command).exitcode(); 
}

our sub git_pull {
  if !path_exists($git_dir, 'd') { return "Git repository not initialized. See ./dbsm git init" }
  shell("cd $config_dir; %commands<git> pull origin master"); 
}

