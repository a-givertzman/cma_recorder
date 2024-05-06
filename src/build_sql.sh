#!/bin/bash
#
#
# Database configuration:
#
#   basic database parameters
user="crane_data_server"
pass="00d0-25e4-*&s2-ccds"
db="crane_data_server"
#
#   list of SQL scripts, builts from bash-script files (where database name, user & pass substituted from variables)
read -r -d '' sqlScripts << EOF
	"./src/create_db.sql.sh" "./sql/create_db.sql"
	"./src/create_user.sql.sh" "./sql/create_user.sql"
	"./src/create_grant_user.sql.sh" "./sql/create_grant_user.sql"
EOF
#
############# CONSTANTS DEFINITION ############
RED='\033[0;31m'
BLUE='\033[0;34m'
GRAY='\033[1;30m'
YELLOW='\033[1;93m'
NC='\033[0m' # No Color
#
echo "Building SQL's ..."

############ PREPARING SQL SCRIPTS ############
regex='\"([^\"]*?)\"[ \t]+\"([^\"]+?)\"'
while IFS= read -r row; do
    [[ $row =~ $regex ]]
    srcPath=${BASH_REMATCH[1]:="${RED}not specified${NC}"}
    targetPath=${BASH_REMATCH[2]:="${RED}not specified${NC}"}
    echo ""
    echo -e "\t${GRAY}Building SQL script ${NC}'$targetPath'${GRAY} from file${NC} '$srcPath'"
	if [ -f "$srcPath" ]; then
		source "$srcPath"
		echo -e "\t${GRAY}SQL:${NC}"
		echo -e "\t${GRAY}$sql${NC}"
		echo -e "$sql" > "$targetPath"
		echo -e "\t${GRAY}SQL script '$targetPath' - done ${NC}"
	else
		echo -e "${RED}SQL script not found: '$srcPath' ${NC}"
	fi
done <<< "$sqlScripts"
