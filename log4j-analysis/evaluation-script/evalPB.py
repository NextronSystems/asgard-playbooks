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
    parser.add_argument('-v', '--vulnerable', dest='vulnerable', help='Only print findings of vulnarable versions', action="store_true")
    parser.add_argument('--json', dest='jsonpath', help='Dump results into json with the given path')
    parser.add_argument('--csv', dest='csvpath', help='Dump results into csv with the given path')
    try:
        args = parser.parse_args()
    except argparse.ArgumentError as exc:
        print (exc.message, '\n', exc.argument)
        return 1

    #Match for these: log4j-api-2.12.1.jar - all versions from 2.0.0 to 2.15.*
    log4jre = re.compile(".+log4j-.{0,10}(2\.([0-9]\.|1[0-5])\.[0-9]+).*")

    # Setup Temporary directory
    try: 
        workdir = tempfile.mkdtemp(dir='.')
    except Exception as err:
        print("Something went wrong while creating tmp workdir: "+err)

    try:
        for infile in args.inputfile:
                with zipfile.ZipFile(infile, 'r') as zip_ref:
                    zip_ref.extractall(workdir)
    except Exception as err:
        print("Error with open zip file:"+  str(err)) 
        return 1

    # Walk over the dict in search for the downloaded result files
    try:
        for root, dirs, files in os.walk(workdir):
            for file in files:
                # Only unpack the Files from "step-3" which are the downloaded result files
                if '-step-3-' in file:
                    with tarfile.open(os.path.join(root,file), 'r:gz') as tfile:
                        tfile.extractall(path=workdir+"")
                    # Remove Tar.GZ file
                    os.remove(os.path.join(root,file))
    except Exception as err:
        print("Something went wrong while extracting the tarfiles: "+ str(err))

    validfileendings = ["processes","fsfiles", "openfiles", "jndiclass"]
    # Walk over every file thats now in the directory
    for root, dirs, files in os.walk(workdir):
        for file in files:
            # Check for the filetype, only analyze known filetypes            
            ending = file.split(".")
            if not ending[-1] in validfileendings:
                continue
            type = ending[-1]

            host, datet = parsefilename(file)
            
            # Open file and do the checks
            try:
                with open(os.path.join(root,file)) as fileReader:

                        for line in fileReader:
                            line = line.strip()
                            # Skip empty lines
                            if line == "":
                                continue

                            event = {}
                        
                            event["host"] = host
                            event["date"] = datet
                            event["type"] = type
                            
                            # By default, the event just logs the line
                            event["event"] = line
                            
                            # Default event level is low
                            event["level"]  = "low"
                            
                            # Events of type jndiclass are always high
                            if event["type"] == "jndiclass":
                                event["level"] = "high"

                            # Do the Regex Version check
                            matches = log4jre.match(line)
                            if matches:
                                # If the detected log4j version is vulnarable, set event level to high
                                event["level"] = "high"
                                # Prefix the logline with the detected log4j version
                                event["event"] = "log4j Version: "+matches[1]+" - "+ event["event"]

                            add2dict(host, event)
          
            except Exception as err:
                print("Something went wrong with reading the result files: " +str(err))
    try:
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
                        w.writerow({"Host":event["host"],"Level":event["level"], "Type":event["type"],"Event": event["event"]})
    except Exception as err:
        print("Something went wrong while dumping files: " + str(err))

    # Print Out Results in STDOUT
    for host in results:
        for event in results[host]["events"]:
            # Print all events when vulnerable is false
            if args.vulnerable == False:
                printevent( event)
            # Otherwise just print only high events
            elif event["level"] == "high":
                printevent( event)
    
    try:
        # Remove TMP Directory
        shutil.rmtree(workdir)
    except Exception as err:
        print("Something went wrong while cleaning up: "+str(err))
    return

def printevent( event):
    print("HOST: "+event["host"] + "; LEVEL: " + event["level"] + "; TYPE: "+event["type"]+"; EVENT: "+ event["event"])

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
      
