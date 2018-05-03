#!/usr/bin/env python3

import argparse
import json
import os

def main():
    parser = argparse.ArgumentParser(description="Take multiple JSON objects (from different files) and creates one JSON file (quicker to import into Serpico).")
    parser.add_argument("--json-file", required=True,
                        help="This file will contain all JSON objects in the files under template directory")
    parser.add_argument("--template-directory", default='template_findings',
                        help="Template directory to process (default: template_findings)")
    parsed = parser.parse_args()

    # Open JSON file
    process_json(parsed)

def process_json(args):
    json_list = []

    for json_file in os.listdir(args.template_directory):
        if json_file.endswith('.json'):
            json_list.append(json.load(open(args.template_directory + '/' + json_file))[0])

    with open(args.json_file,'w') as fp:
        json.dump(json_list, fp)

if __name__ == "__main__":
    main()
