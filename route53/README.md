# Route53 DynDNS

## Dependencies

* bash
* curl
* [dig](https://linux.die.net/man/1/dig)
* [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)

## AWS User

Create a user and add the following permission policy:  
(replace the zone id, with the one you have in Route53)  

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "route53:ChangeResourceRecordSets",
            "Resource": "arn:aws:route53:::hostedzone/Z0XXXXXXXXXXXXXXXAI"
        }
    ]
}
```

## Script configuration

| Variable | Description |
| ------ | ------ |
| AWS_ACCESS_KEY_ID | AWS user access key |
| AWS_SECRET_ACCESS_KEY | AWS user secret access key |
| AWS_ZONE_ID | AWS Route53 hosted zone ID |
| DNS_ROOT_FQDN | Fully qualified root domain name |
| DNS_SUBDOMAINS | List of subdomains under the root domain |
| DNS_TTL | TTL of the DNS record (seconds)  |
| DNS_RECHECK_TIME | DNS record re-check time (seconds) |
