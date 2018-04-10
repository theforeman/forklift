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
        status = subprocess.check_output(['foreman-rake', 'db:migrate:status'])

        if status.find('pending migration') == -1:
            database_is_migrated = True
        else:
            print("Database not migrated yet, sleeping....")
            time.sleep(5)

    if database_is_migrated:
        print ("Database migrated!")
        sys.exit(0)
    else:
        print ("Database not migrated in time, exiting")
        sys.exit(1)
