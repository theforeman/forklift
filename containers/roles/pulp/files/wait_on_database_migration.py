#!/usr/bin/env python

import sys
import subprocess
import time

if __name__ == '__main__':

    database_is_migrated = False
    tries = 0
    print ("Waiting on databsae to be migrated...")
    while not database_is_migrated and tries < 60:
        tries += 1
        try:
            subprocess.check_call(['pulp-manage-db', '--dry-run'])
        except subprocess.CalledProcessError:
            print("Database not migrated yet, sleeping....")
            time.sleep(5)
        else:
            database_is_migrated = True

    if database_is_migrated:
        print ("Database migrated!")
        sys.exit(0)
    else:
        print ("Database not migrated in time, exiting")
        sys.exit(1)
