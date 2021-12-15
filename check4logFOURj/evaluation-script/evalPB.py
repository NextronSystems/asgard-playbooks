#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
from typing import Optional
import zipfile
import argparse
import tempfile
import os
import tarfile
import re
import datetime
import json
import csv
import shutil

#Main Dictionary that carries all results globally
results = {}

def main():
    parser = argparse.ArgumentParser(description='Evaluate Playbook Results')
    parser.add_argument('inputfile', help='Input Zip file(s) downloaded from ASGARD Playbook', nargs='+')
    parser.add_argument('-v', '--verbose', dest='verbose', help='Also print low level events (not containing a vulnerable log4j2 version string)', action="store_true")
    parser.add_argument('--json', dest='jsonpath', help='Dump results into json with the given path')
    parser.add_argument('--csv', dest='csvpath', help='Dump results into csv with the given path')
    args = parser.parse_args()

    #Match for these: log4j-api-2.12.1.jar - all versions from 2.0.0 to 2.15.9
    log4jre = re.compile(".+log4j-.{0,10}(2\.([0-9]\.|1[0-5])\.[0-9]+).*")

    # Setup Temporary directory
    workdir = tempfile.mkdtemp(dir='.')
    for infile in args.inputfile:
        with zipfile.ZipFile(infile, 'r') as zip_ref:
            zip_ref.extractall(workdir)

    # Walk over the dict in search for the downloaded result files
    for root, dirs, files in os.walk(workdir):
        for file in files:
            # Only unpack the Files from "step-3" which are the downloaded result files
            if '-step-3-' in file:
                with tarfile.open(os.path.join(root,file), 'r:gz') as tfile:
                    tfile.extractall(path=workdir+"")
                # Remove Tar.GZ file
                os.remove(os.path.join(root,file))

    # Walk over every file thats now in the directory
    for root, dirs, files in os.walk(workdir):
        for file in files:
            # If the file ends with one of the set endings, evaluate it
            # Check all processes files
            if ".processes" in file:
                host, datet = parsefilename(file)
                with open(os.path.join(root,file)) as fileReader:
                      for line in fileReader:
                        line = line.strip()
                        if line == "":
                            continue    
                        matches = log4jre.match(line)
                        if matches:
                            add2dict(host, {"type":"processes", "level":"high", "date":datet, "event":"log4j Version: "+matches[1]+" - "+line})
                        else:
                            add2dict(host, {"type":"processes", "level":"low", "date":datet, "event":line})
                        continue


            # Check all fsfiles files
            elif ".fsfiles" in file:
                host, datet = parsefilename(file)
                with open(os.path.join(root,file)) as fileReader:
                    
                    for line in fileReader:
                        line = line.strip()
                        if line == "":
                            continue    
                        matches = log4jre.match(line)
                        if matches:
                            add2dict(host, {"type":"fsfiles", "level":"high", "date":datet, "event":"log4j Version: "+matches[1]+" - "+line})
                        else:
                            add2dict(host, {"type":"fsfiles", "level":"low", "date":datet, "event":line})
                        continue


            # Check all openfiles files
            elif ".openfiles" in file:
                host, datet = parsefilename(file)
                with open(os.path.join(root,file)) as fileReader:
                    for line in fileReader:
                        line = line.strip()
                        if line == "":
                            continue
                        matches = log4jre.match(line)
                        if matches:
                            add2dict(host, {"type":"openfiles", "level":"high", "date":datet, "event":"log4j Version: "+matches[1]+" - "+line})
                        else:
                            add2dict(host, {"type":"openfiles", "level":"low", "date":datet, "event":line})
            
            # Check all jndiclass files
            elif ".jndiclass" in file:
                host, datet = parsefilename(file)
                with open(os.path.join(root,file)) as fileReader:
                    for line in fileReader:
                        line = line.strip()
                        if line == "":
                            continue
                        # Match for the version number
                        matches = log4jre.match(line)
                        
                        if matches:
                            add2dict(host, {"type":"jndiclass", "level":"high", "date":datet, "event":"log4j Version: "+matches[1]+" - "+line})
                        else:
                            add2dict(host, {"type":"jndiclass", "level":"low", "date":datet, "event":line})
    # Dump as json
    if args.jsonpath:
        path =  args.jsonpath
        with open(path, 'w') as fp:
            json.dump(results, fp,indent=2, sort_keys=True)
    
    # Dump as csv
    if args.csvpath:
        path =  args.csvpath
        with open(path, 'w') as csvfile:
            w = csv.DictWriter(csvfile, ["Host", "Level", "Type", "Event"])
            w.writeheader()
            for host in results:
                for event in results[host]["events"]:
                    w.writerow({"Host":host,"Level":event["level"], "Type":event["type"],"Event": event["event"]})

    # Print Out Results in STDOUT
    for host in results:
        for event in results[host]["events"]:
            # Only Print Low level Events when verbose 
            if args.verbose == True:
                printevent(host, event)
            # Always print High level Events
            elif event["level"] == "high":
                printevent(host, event)
    
    # Remove TMP Directory
    shutil.rmtree(workdir)

    return

def printevent(host, event):
    print("HOST: "+host + "; LEVEL: " + event["level"] + "; TYPE: "+event["type"]+"; EVENT: "+ event["event"])

def add2dict(host, event):
    # Add event to the dictionary
    if host in results:
        results[host]["events"].append(event)
    else: 
        # Initialize the host in the dict
        results[host] = {}
        results[host]["events"] = [event]

def parsefilename(file):
    # Parse the filenames for the Host and the date. Example filename:
    # DESKTOP-SV334Q3_check4logFOURj_2021-12-15_1442.win.fsfiles
    regex = re.compile("(.+)_check4logFOURj_(.+)\..+\..+")
    matches = regex.match(file)
    
    hostname = matches[1]
    dtime = str(datetime.datetime.strptime(matches[2], '%Y-%m-%d_%H%M'))
    return hostname, dtime



if __name__ == '__main__':
        sys.exit(main())
      
