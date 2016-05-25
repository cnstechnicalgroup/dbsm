dbsm
====

`dbsm` is a cli DB script manager. It allows for easily managing ad-hoc DB scripts (SQL, NoSQL) as parts of projects and associated with managed `environment` configurations. 

Getting started
===============

`dbsm` simplifies the management of ad-hoc DB scripts by allowing you to track projects. The three manageable areas are:

* Projects
    Name of the project, e.g. `webapp1`
  * Environments
    Any enrionment name, used for organizing DB connections, e.g `dev`, `stage`, `test`, `prod`, etc... 
* Scripts
    Name of DB script. These are stored in `~/.dbms/projects/project/scriptname.sql|js|etc.`
    Each script is edited using $EDITOR editor.
* Database Connections
   Specify a Database type for each Project Environment, e.g. `mysql`, `postgresql`, `mongodb`, etc.

```
Usage:
  ./bin/dbsm [--generate=<Any>] [--pw_len=<Any>] init <project_name> <environment> <db_type> 
  ./bin/dbsm project list
  ./bin/dbsm script add <project_name> <script_name> 
  ./bin/dbsm script run <project_name> <environment> <script_name>
  ./bin/dbsm script list <project_name>
```

Examples
========

## Create a new project

Specify the project name, environment, and database type. Environment naming convention is up to user. For example, there is no requirement to use `dev, stage, test` vs `level1, level2, level3`.

```
./bin/dbsm init webproject1 dev mysql
```
## List projects

```
./bin/dbsm project list
```

## Add script to project

Scripts are available to all `environtments` so only require a project name and script name to create:

```
./bin/dbsm script add webproject1 top10cities.sql
```

The user's editor (defined in the user's $EDITOR env var) will open the script for editing. If the script already exists for the specified project then the user will be prompted to edit the script or cancel.

## Run script

Run a script under the context of a project's environment:

```
./bin/dbsm script run webapp1 dev top10projects.sql
```

## List project's scripts

```
./bin/dbsm script list webapp1
```

Installation
============

Clone the repository to your local system:

```
git clone https://github.com/cnstechnicalgroup/dbsm.git
cd dbsm/
panda install .
```

Todo
====

* Add tests
* Add `cp`, `mv` to scripts / projects
* Add additional Database support
* Add git support (`init`, `add remote`, `push`, `pull`)

Requirements
============

* [Perl 6](http://perl6.org/)
* [Password Store](https://www.passwordstore.org/)
* [GnuPG](https://gnupg.org/)
* [Git](https://git-scm.com/)


AUTHORS
=======

  * Sam Morrison

COPYRIGHT AND LICENSE
=====================

Copyright 2016 Sam Morrison

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

