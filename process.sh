#!/bin/bash
set -e

encryption_key() {
    CMD="com.salesforce.dataloader.security.EncryptionUtil"
    KEY="config/encryption.key"

    if [ ! -f "$KEY" ]; then
        dataloader "$CMD" "-k" "$KEY"
    fi

    dataloader "$CMD" "$1" "$2" "$KEY"
}

dataloader() {
    java -cp "dataloader.jar" -Dsalesforce.config.dir=config "$@"
}

case "$1" in
    "encrypt")
        if [ -z "$2" ]; then
            echo "You must provide a string to encrypt"
            exit 0
        fi

        encryption_key "-e" "$2"
        ;;
    "run") CMD="com.salesforce.dataloader.process.ProcessRunner";;
    *)
        echo "You must specify a command. E.g.: encrypt | run"
        exit 0
esac
