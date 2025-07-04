#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

USERNAME=$1

echo "Deleting consumer: $USERNAME"
curl -X DELETE http://localhost:8001/consumers/$USERNAME

echo "Consumer $USERNAME deleted successfully"
