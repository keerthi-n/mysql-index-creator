#!/bin/bash

# Function to display help
show_help() {
    echo "Usage: $0 -h <host> -P <port> -u <user> -p <password> -d <database> -x <prefix>"
    echo ""
    echo "  -h   MySQL host"
    echo "  -P   MySQL port"
    echo "  -u   MySQL user"
    echo "  -p   MySQL password"
    echo "  -d   MySQL database"
    echo "  -x   Prefix for index names"
    echo ""
    echo "This script analyzes the database tables and suggests indexes for columns."
    echo "The suggested indexes will be saved in 'index_creation_commands.sql'."
}

# Parse input arguments
while getopts "h:P:u:p:d:x:" opt; do
    case $opt in
        h) DB_HOST=$OPTARG ;;
        P) DB_PORT=$OPTARG ;;
        u) DB_USER=$OPTARG ;;
        p) DB_PASS=$OPTARG ;;
        d) DB_NAME=$OPTARG ;;
        x) INDEX_PREFIX=$OPTARG ;;
        *) show_help; exit 1 ;;
    esac
done

# Check if all required arguments are provided
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ] || [ -z "$DB_NAME" ] || [ -z "$INDEX_PREFIX" ]; then
    show_help
    exit 1
fi

# Connect to the MySQL database and retrieve tables
TABLES=$(mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS -D $DB_NAME -e "SHOW TABLES;" --silent --skip-column-names)

echo "Index Analysis Report"
echo "====================="

# Temporary file to store index creation commands
INDEX_FILE="index_creation_commands.sql"
> $INDEX_FILE

# Loop through each table
for TABLE in $TABLES; do
    echo "Analyzing table: $TABLE"

    # Get the structure of the table
    COLUMNS=$(mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS -D $DB_NAME -e "SHOW COLUMNS FROM $TABLE;" --silent --skip-column-names)

    # Suggest index on columns with no index that are not part of primary key
    for COLUMN in $COLUMNS; do
        COLUMN_NAME=$(echo $COLUMN | awk '{print $1}')
        COLUMN_KEY=$(echo $COLUMN | awk '{print $4}')

        if [ "$COLUMN_KEY" == "" ]; then
            INDEX_NAME="${INDEX_PREFIX}_${COLUMN_NAME}"
            echo "  - Index suggested: $INDEX_NAME on $TABLE($COLUMN_NAME)"
            echo "CREATE INDEX $INDEX_NAME ON $TABLE($COLUMN_NAME);" >> $INDEX_FILE
        fi
    done
    echo "------------------------------"
done

echo "Analysis complete. Run the second script to create the suggested indexes."
echo "Index creation commands saved to $INDEX_FILE"
