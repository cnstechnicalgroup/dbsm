dbsm
====

`dbsm` is a cli DB script manager. It allows for easily managing ad-hoc DB scripts (SQL, NoSQL) as parts of projects and associated with managed `account` configurations. 

Getting started
===============

`dbsm` simplifies the management of ad-hoc DB scripts by allowing you to track projects and manages three areas:

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
  ./bin/dbsm script add <project_name> <script_name> 
  ./bin/dbsm script run <project_name> <environment> <script_name>

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

* Add `cp`, `mv` to scripts / projects
* Add additional Database support
* Add tests

Requirements
============

* [Perl 6](http://perl6.org/)
* [Password Store](https://www.passwordstore.org/)
* [GnuGPG](https://gnupg.org/)
* [Git](https://git-scm.com/)


AUTHORS
=======

  * Sam Morrison

COPYRIGHT AND LICENSE
=====================

Copyright 20166 Sam Morrison

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

