#!/usr/bin/env python3

import argparse
import json

def main():
    parser = argparse.ArgumentParser(description="Takes finding template JSON export from Serpico and splits into separate files")
    parser.add_argument("--json-file", required=True,
                        help="The JSON file containing the new finding templates")
    parser.add_argument("--template-directory", default='template_findings',
                        help="Template directory (default: template_findings)")
    parsed = parser.parse_args()

    # Open JSON file
    process_json(parsed)

def process_json(args):
    json_object = json.load(open(args.json_file))
    for issue in json_object:
        print("Writing " + issue['title'] + ".json... ", end='')
        with open(args.template_directory + '/' + issue['title'].replace('/','_') + '.json','w') as fp:
            list_issue = [ issue ]
            json.dump(list_issue,fp)
        print("done")

if __name__ == "__main__":
    main()
