# Gateway with SSL Termination

## Dependencies

* nginx
* python
* [certbot](https://certbot.eff.org/about/)
* [py37-certbot](https://certbot.eff.org/lets-encrypt/freebsd-nginx.html)
* [py37-certbot-dns-route53](https://certbot-dns-route53.readthedocs.io/en/stable/)
* [openssl](https://www.openssl.org/)
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
            "Action": [
                "route53:GetChange",
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": [
                "arn:aws:route53:::hostedzone/Z0XXXXXXXXXXXXXXXAI",
                "arn:aws:route53:::change/*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "route53:ListHostedZones",
            "Resource": "*"
        }
    ]
}
```

## Jail Setup

> Note: Replace all the occurrences of 'example.com' with your domain. It applies to everything: names, files and configs.

```bash
# Install dependencies
pkg update
pkg install \
    nginx \
    python \
    py37-certbot \
    py37-certbot-dns-route53 \
    openssl \
    awscli 

# Download dhparam.pem certificate
curl https://ssl-config.mozilla.org/ffdhe2048.txt > /usr/local/etc/ssl/dhparam.pem

# Enable nginx
sysrc nginx_enable=yes
service nginx start

# Configure AWS access
aws configure

# Request a wildcard certificate for our domain
certbot certonly --dns-route53 -d '*.example.com'

# That's how we can renew the certificates:
# > certbot renew --quiet --deploy-hook "/usr/sbin/service nginx reload"

# Set up automatic renewal (or via 'crontab -e')
echo "0 0,12 * * * /usr/local/bin/python -c 'import random; import time; time.sleep(random.random() * 3600)' && /usr/local/bin/certbot renew --quiet --deploy-hook '/usr/sbin/service nginx reload'" | sudo tee -a /etc/crontab > /dev/null
```
