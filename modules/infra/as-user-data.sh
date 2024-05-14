#!/bin/bash
apt update
apt install -y nginx
cat <<EOF > /var/www/html/index.html
<html><body>
<h1>Armaggedon is here</h1>
<br/>
<img src="https://storage.googleapis.com/${google_storage_bucket.bucket.name}/arma2.jpg"/><br/>
Hostname: $(curl "http://metadata.google.internal/computeMetadata/v1/instance/hostname" -H "Metadata-Flavor: Google")
<br/>
Instance ID: $(curl "http://metadata.google.internal/computeMetadata/v1/instance/id" -H "Metadata-Flavor: Google")
<br/>
Project ID: $(curl "http://metadata.google.internal/computeMetadata/v1/project/project-id" -H "Metadata-Flavor: Google")
<br/>
Zone ID: $(curl "http://metadata.google.internal/computeMetadata/v1/instance/zone" -H "Metadata-Flavor: Google")
</body></html>
EOF
