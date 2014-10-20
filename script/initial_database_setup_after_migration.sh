#!/bin/bash

usage(){
  echo "Usage: $0 ENVIRONMENT"
  echo
  echo "ENVIRONMENT should be: development|test|production"
  #echo "Available SITES:"
  #ls -1 db/data
} 

ENV=$1
#SITE=$2

if [ -z "$ENV" ] ; then
  usage
  exit
fi

set -x # turns on stacktrace mode which gives useful debug information

if [ ! -x config/database.yml ] ; then
  cp config/database.yml.example config/database.yml
fi

USERNAME=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['${ENV}']['username']"`
PASSWORD=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['${ENV}']['password']"`
DATABASE=`ruby -ryaml -e "puts YAML::load_file('config/database.yml')['${ENV}']['database']"`

mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/schema_opd_additions.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/opd_after_migration_defaults.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/openmrs_metadata_1_7.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/malawi_regions.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/moh_regimens_only.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/user_schema_modifications.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/missing_tables.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/pharmacy.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/update_concepts.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/load_location_tag_and_location_tag_map.sql
mysql --user=$USERNAME --password=$PASSWORD $DATABASE < db/create_dde_server_connection.sql

/*
mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/openmrs_1_7_2_concept_server_full_db.sql
#echo "schema additions"
mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/schema_bart2_additions.sql
mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/bart2_views_schema_additions.sql
#echo "defaults"
mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/defaults.sql
#echo "user schema modifications"
#mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/user_schema_modifications.sql
mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/malawi_regions.sql
mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/mysql_functions.sql
mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/drug_ingredient.sql
mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/pharmacy.sql
mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/national_id.sql
mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/weight_for_heights.sql
mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/data/${SITE}/${SITE}.sql
mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/data/${SITE}/tasks.sql
mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/moh_regimens_only.sql
#mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/regimen_indexes.sql
mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/retrospective_station_entries.sql
mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/create_dde_server_connection.sql

#mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/privilege.sql
#mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/bart2_role_privileges.sql
mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/migrate/create_weight_height_for_ages.sql
mysql --host=$HOST --user=$USERNAME --password=$PASSWORD $DATABASE < db/migrate/insert_weight_for_ages.sql
*/

echo "After completing database setup, you are advised to run the following:"
echo "script/runner -e development|production|test script/update_diagnosis_observations.rb"
echo "done"
