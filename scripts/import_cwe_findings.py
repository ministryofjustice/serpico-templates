#!/usr/bin/env python3

import argparse
import copy
import csv
import html
import json

def main():
    parser = argparse.ArgumentParser(description="Takes finding template CSV export from https://cwe.mitre.org/data/downloads.html splits into separate JSON files")
    parser.add_argument("--csv-file", required=True,
                        help="The CSV file containing the CWE finding templates")
    parser.add_argument("--template-directory", default='template_findings',
                        help="Template directory (default: template_findings)")
    parsed = parser.parse_args()

    # Open CSV file
    process_csv(parsed)

def copy_keys(obj,data_to_keep,init=False):
    new_obj = {}
    for key in obj.keys():
        if key in data_to_keep:
            new_obj[key] = html.escape(obj[key])
    return new_obj

def rename_keys(obj,search,replace):
    new_obj = {}
    for key in obj.keys():
        if type(key) != str:
            continue

        if key in search:
            new_obj[replace[search.index(key)]] = html.escape(obj[key])
            continue

        new_obj[key] = html.escape(obj[key])
    return new_obj

def fix_extended_description(obj):
    new_obj = {}
    for key in obj.keys():
        new_obj[key] = obj[key]
        if key == 'Extended Description' and obj[key] == '':
            new_obj[key] = html.escape(obj['Description'])
    return new_obj

def process_csv(args):
    csvfile = open(args.csv_file, 'r')

    fieldnames = ("ID","Name","Weakness Abstraction","Status","Description","Extended Description","Related Weaknesses","Weakness Ordinalities","Applicable Platforms","Background Details","Alternate Terms","Modes Of Introduction","Exploitation Factors","Likelihood of Exploit","Common Consequences","Detection Methods","Potential Mitigations","Observed Examples","Functional Areas","Affected Resources","Taxonomy Mappings","Related Attack Patterns","Notes")
    reader = csv.DictReader( csvfile, fieldnames)
    for row in reader:
        jsonfile = open(args.template_directory + '/' + row['Name'].replace('/','_') + '.json', 'w')

        data_search = ['ID','Name','Extended Description','Potential Mitigations']
        data_replace = ['id','title','overview','remediation']

        # Fill 'Extended Description' fields if empty (with 'Description' content)
        new_row = fix_extended_description(row)

        # Rename keys
        rename_row = rename_keys(new_row,data_search,data_replace)

        # Only extract renamed keys
        extract_row = copy_keys(rename_row,data_replace)

        # Insert Serpico required(?) fields
        extra_data = {"id":1, "damage": 1, "reproducability": 1, "exploitability": 1, "affected_users": 1, "discoverability": 1, "dread_total": 1, "effort": None, "type": "Imported","poc": None,"approved": True, "risk": 1, "affected_hosts": None, "av": None, "ac": None, "au": None, "c": None, "i": None, "a": None, "e": None, "rl": None, "rc": None, "cdp": None, "td": None, "cr": None, "ir": None, "ar": None, "cvss_base": None, "cvss_impact": None, "cvss_exploitability": None, "cvss_temporal": None, "cvss_environmental": None, "cvss_modified_impact": None, "cvss_total": None, "ease": None}
        extract_row.update(extra_data)

        json.dump(extract_row, jsonfile)
        jsonfile.write('\n')

if __name__ == "__main__":
    main()
