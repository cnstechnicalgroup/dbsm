dbsm
====

`dbsm` is a cli DB script manager. It allows for easily managing ad-hoc DB scripts (SQL, NoSQL) as parts of projects and associated with managed `account` configurations. 

# Getting started

```
Usage:
  ./bin/dbsm [--generate=<Any>] [--pw_len=<Any>] init <project_name> <environment> <db_type> 
  ./bin/dbsm script add <project_name> <script_name> 
  ./bin/dbsm script run <project_name> <environment> <script_name>


# Below is for cleanup...

#
# Initial setup
#

# Establish `dbsm` folders and initial GPG config
dbsm init

#
# Manage projects
#

# Create a new MySQL project
dbsm init mysql PROJECT_NAME

# Create a new PostgreSQL project
dbsm init pgsql PROJECT_NAME

# Create a new MongoDB project
dbsm init mongo PROJECT_NAME

# Rename project
dbsm mv Projects/PROJECT_NAME Projects/NEW_PROJECT_NAME

# Delete project
dbsm rm Projects/PROJECT_NAME # Deletes project and all scripts associated

#
# Manage scripts
#

# Add / edit script
dbsm edit PROJECT_NAME/script-name.sql # Opens $EDITOR for editing. If new, creates a new script under the `PROJECT_NAME` namespace

# Run script (use tab-completion for project / script / account names)
dbsm run PROJECT_NAME/script-name.sql ACCOUNT_NAME # Launch the script
																									 # using the project's cli
                                                   # DB client with the 
                                                   # ACCOUNT_NAME DB connection

# Rename script
dbsm mv Projects/PROJECT_NAME/script-name.sql PROJECT_NAME/new-script-name.sql

# Move script
dbsm mv Projects/PROJECT_NAME/script-name.sql OTHER_PROJECT_NAME/script-name.sql

# Copy script
dbsm cp Projects/PROJECT_NAME/script-name.sql OTHER_PROJECT_NAME/script-name.sql

# Delete script
dbsm rm Projects/PROJECT_NAME/script-name.sql

#
# Manage DB connections
#

# Add / edit MySQL connection
dbsm con mysql ACCOUNT_NAME # Prompts for server name, login, and password

# Add / edit PostgreSQL connection
dbsm con postgresql ACCOUNT_NAME # Prompts for server name, login, and password

# Add / edit Mongo connection
dbsm con mongo ACCOUNT_NAME # Prompts for server name, login, and password

# Delete connection
dbsm rm Connection/ACCOUNT_NAME

#
# Git commands
#

# Setup git repo / remote
git init git://full/repo/uri.git

# Commit / push all modifications to repo
dbsm git push

# Pull latest modifications from master
dbsm git pull

```
