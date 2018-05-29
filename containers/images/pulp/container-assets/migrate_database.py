#!/usr/bin/env python

import sys
import subprocess
import time

if __name__ == '__main__':

    print ("Check if database is migrated...")
    try:
        subprocess.check_call(['pulp-manage-db', '--dry-run'])
    except subprocess.CalledProcessError:
        try:
            subprocess.check_call(['pulp-manage-db'])
            sys.exit(0)
        except subprocess.CalledProcessError:
            print("Error migrating")
            sys.exit(1)
