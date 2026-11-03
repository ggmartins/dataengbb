aws cur put-report-definition --region us-east-1 --report-definition file://report-definition.json
aws cur describe-report-definitions   --region us-east-1   --query 'ReportDefinitions[].ReportName'   --output table
