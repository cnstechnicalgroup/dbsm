use v6;
#use Config::Simple;
use Config::INI;
use Config::INI::Writer;
use JSON::Tiny;

class X::DBSM is Exception {
    has $.status;
    has $.reason;

    method message() {
        "Error: '$.status $.reason'";
    }
}

class DBSM {

  my $config_dir;
  my $config_file;
  my $project_root;

  # Commands
  my %commands = git => "/usr/bin/env git",
               pass => "/usr/bin/env pass";

  sub escape ($str) {
    # Puts a slash before non-alphanumeric characters
    S:g[<-alpha -digit>] = "\\$/" given $str
  }

  # DB commands using code objects as templates
  my %dbs = mysql => -> %params {qq:to/EOF/;
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
  my $git_dir;

  # Pass
  my $pass_generate = %commands<pass> ~ " generate -c ";
  my $pass_insert = %commands<pass> ~ " insert ";
  my $pass_edit = %commands<pass> ~ " edit ";
  my $pass_show = %commands<pass> ~ " show ";
  my $pass_pw_len = 40;
  my $pass_prefix = "dbsm";

  # Script Editor
  my $editor = "/usr/bin/env vim";
  my $scripts_root;


  method BUILD(Str :$dir, Str :$file) {
    $config_dir = $dir;
    $config_file = $file;
    $project_root = $config_dir ~ "/projects";

    # Git
    $git_dir = $config_dir ~ "/.git";

    # Script Editor
    $editor = "/usr/bin/env vim";
    $scripts_root = $config_dir ~ "/scripts";

  }

  method project_exists(Str $project_name) {
    my %conf = Config::INI::parse_file($config_file);
    return %conf.keys.grep({ / $project_name / }).elems > 0;
  }

  method path_exists(Str $path, Str $type) {
    if $type ~~ 'f' { return $path.IO ~~ :f }
    if $type ~~ 'd' { return $path.IO ~~ :d }
  }

  method script_path(Str $project_name, Str $script_name) {
    my $script_folder = $scripts_root ~ "/$project_name";
    if !self.path_exists($script_folder, 'd') { mkdir $script_folder }
    return $script_folder ~ "/$script_name";
  }

  method init(  Str $project_name,
                Str $environment,
                Str $db_type where { so $db_type ∈ %dbs.keys },
                :$generate?, :$pw_len?) is export {

    my %conf;

    # Create config entry
    if (self.path_exists($config_file, 'f')) {
      say "Reading from config...";
      %conf = Config::INI::parse_file($config_file);
    } else {
      say "Creating config...";
      if !self.path_exists($config_dir, 'd') { mkdir $config_dir }
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

  method project_list {
    if !self.path_exists($config_file, 'f') { return say "No projects exists. See ./dbsm init" }
    my %conf = Config::INI::parse_file($config_file);
    return %conf.keys.sort
    #say "Project\t\tEnvironments";
    #my %projects = [];
    #for $conf.hash.keys.sort -> $project {
    # my @project = $project.split(' ');
    #  %projects{@project[0]} = @project[1];
    #}
    #say %projects;
  }

  method project_vars(Str $project_name, Str $environment, $echopass?) {

    # Confirm project exists
    if ( !self.project_exists("$project_name $environment") ) {
      return say("Project [$project_name $environment] doesn't exist. See ./dbsm init");
    }

    # Read config
    my %conf = Config::INI::parse_file($config_file);
    my $db_host = %conf{"$project_name $environment"}<db_host>;
    my $db_name = %conf{"$project_name $environment"}<db_name>;
    my $user_name = %conf{"$project_name $environment"}<user_name>;

    # Echo password?
    my $pass;
    if ($echopass) {
      $pass = escape shell("$pass_show $pass_prefix/$project_name/$environment/$db_name/$user_name", :out).out.slurp-rest.chomp();
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

  method script_add(Str $project_name, Str $script_name) {

    if ( !self.project_exists($project_name) ) {
      return "Project [$project_name] doesn't exist. See ./dbsm init";
    }

    my $script_path = self.script_path($project_name, $script_name);
    
    if ( self.path_exists($script_path, 'f') ) { 
      my $to_edit = 'y';
      $to_edit = prompt("Script already exists. Edit? (yN)");
      return if $to_edit.match(/n|N/);
    }

    shell($editor ~ " $script_path");
    return "New script, $script_path, added";

  }

  method script_run(Str $project_name, Str $environment, Str $script_name) {

    if ( !self.project_exists("$project_name $environment") ) {
      return say("Project [$project_name $environment] doesn't exist. See ./dbsm init");
    }

    my $script_path = self.script_path($project_name, $script_name);

    if ( !self.path_exists($script_path, 'f') ) {
      return say("Script, $script_name, doesn't exist. See ./dbsm script run");
    }

    my %conf = Config::INI::parse_file($config_file);
    my %params = db_type => %conf{"$project_name $environment"}<db_type>,
                 db_host => %conf{"$project_name $environment"}<db_host>,
                 db_name => %conf{"$project_name $environment"}<db_name>,
                 user_name => %conf{"$project_name $environment"}<user_name>,
                 options => '',
                 script_path => $script_path;

    my $pass_command = "$pass_show $pass_prefix/$project_name/$environment/%params<db_name>/%params<user_name>";
    %params<pass> = shell($pass_command, :out).out.slurp-rest.chomp();
    shell( %dbs{%params<db_type>}( %params ).subst(/\n/, ' ', :g) );

  }

  method script_list(Str $project_name) is export {

    if ( !self.project_exists("$project_name") ) {
      return say("Project [$project_name] doesn't exist. See ./dbsm init");
    }

    my $script_folder = $scripts_root ~ "/$project_name";
    if !self.path_exists($script_folder, 'd') { return "No scripts available for $project_name." }

    my @scripts = dir $script_folder;
    return @scripts.sort;

  }

  method git_init is export {
    if self.path_exists($git_dir, 'd') { return "Git repository already exists [$git_dir]" }
    shell("cd $config_dir; %commands<git> init"); 
  }

  method git_remote_origin(Str $url) is export {
    if !self.path_exists($git_dir, 'd') { return "Git repository not initialized. See ./dbsm git init" }
    my @out = shell("cd $config_dir; %commands<git> remote add origin $url 2>&1", :out).out.slurp-rest.chomp(); 
    # Return error message if returned
    return @out.Str if @out.Str !~~ '';
    return "Remote origin [$url] added.";
  }

  method git_push is export {
    if !self.path_exists($git_dir, 'd') { return "Git repository not initialized. See ./dbsm git init" }
    shell("cd $config_dir; %commands<git> add .; %commands<git> commit -a -m'[dbsm] updates'; %commands<git> push -u origin master").exitcode(); 
  }

  method git_pull is export {
    if !self.path_exists($git_dir, 'd') { return "Git repository not initialized. See ./dbsm git init" }
    shell("cd $config_dir; %commands<git> pull origin master"); 
  }

}
