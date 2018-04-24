#!/usr/bin/env python

import sys
import socket
import time

if __name__ == '__main__':

    mongodb_is_alive = False
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    tries = 0
    print ("Waiting on mongodb to start...")
    while not mongodb_is_alive and tries < 100:
        tries += 1
        try:
            s.connect(('mongodb', 27017))
        except socket.error:
            time.sleep(3)
        else:
             mongodb_is_alive = True

    if mongodb_is_alive:
        print ("Mongodb started!")
        sys.exit(0)
    else:
        print ("Unable to reach mongodb on port 27017")
        sys.exit(1)
