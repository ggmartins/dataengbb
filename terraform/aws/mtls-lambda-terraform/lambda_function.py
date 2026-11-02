import json


def handler(event, context):
    request_context = event.get("requestContext") or {}
    authentication = request_context.get("authentication") or {}
    cert = authentication.get("clientCert")

    if not cert:
        return {
            "statusCode": 403,
            "headers": {"content-type": "application/json"},
            "body": json.dumps({"error": "Client certificate required"}),
        }

    return {
        "statusCode": 200,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(
            {
                "message": "Hello from an mTLS-protected Lambda",
                "client_subject": cert["subjectDN"],
                "client_issuer": cert["issuerDN"],
                "client_serial": cert["serialNumber"],
            }
        ),
    }
