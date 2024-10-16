#!/bin/bash


echoIULRed() {
    echo -e "\\033[3;4;31m$*\\033[m"
}

logWarning() {
    echo -e "\\033[33m$*\\033[m"
}

logInfo() {
    echo -e "\\033[32m$*\\033[m"
}

logError() {
    echo -e "\\033[31m$*\\033[m"
}

logProgress() {
    echo -e "\\033[36m$*\\033[m"
}
