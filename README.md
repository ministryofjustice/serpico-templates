# serpico-templates
Report and finding templates used by the Serpico reporting tool

## Install
Run scripts/run.sh to pull the Serpico docker image and apply the templates in this repository

## Add report templates
1. Create new report template .DOCX file
2. Copy new report template to template_reports directory
3. Commit changes

## Add finding templates
1. Create new finding templates in Serpico
2. Export all finding templates as JSON file
3. Use scripts/new_findings.py script to split JSON objects out into files
4. Commit changes
