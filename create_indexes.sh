#!/bin/bash

# Function to display help
show_help() {
    echo "Usage: $0 -h <host> -P <port> -u <user> -p <password> -d <database>"
    echo ""
    echo "  -h   MySQL host"
    echo "  -P   MySQL port"
    echo "  -u   MySQL user"
    echo "  -p   MySQL password"
    echo "  -d   MySQL database"
    echo ""
    echo "This script reads the 'index_creation_commands.sql' file and creates the indexes in the database."
}

# Parse input arguments
while getopts "h:P:u:p:d:" opt; do
    case $opt in
        h) DB_HOST=$OPTARG ;;
        P) DB_PORT=$OPTARG ;;
        u) DB_USER=$OPTARG ;;
        p) DB_PASS=$OPTARG ;;
        d) DB_NAME=$OPTARG ;;
        *) show_help; exit 1 ;;
    esac
done

# Check if all required arguments are provided
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ] || [ -z "$DB_NAME" ]; then
    show_help
    exit 1
fi

# File containing index creation commands
INDEX_FILE="index_creation_commands.sql"

if [ ! -f $INDEX_FILE ]; then
    echo "Error: $INDEX_FILE not found. Please run the first script to generate the index commands."
    exit 1
fi

echo "Creating indexes..."
echo "==================="

# Execute the index creation commands
while IFS= read -r COMMAND; do
    TABLE=$(echo $COMMAND | awk '{print $5}' | cut -d'(' -f1)
    INDEX=$(echo $COMMAND | awk '{print $3}')
    echo "Creating index $INDEX on table $TABLE..."
    mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS -D $DB_NAME -e "$COMMAND"
    echo "  - Index $INDEX created on $TABLE"
done < "$INDEX_FILE"

echo "==================="
echo "Index creation complete. Summary:"
cat $INDEX_FILE

# Cleanup
rm $INDEX_FILE
