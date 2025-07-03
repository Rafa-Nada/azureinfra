
#!/bin/bash

# Update and install prerequisites
sudo apt-get update
sudo apt-get install -y openjdk-11-jre mysql-client curl unzip

# Create a directory for JFrog
cd /opt
sudo mkdir jfrog
sudo chmod 777 jfrog
cd jfrog

# Download and extract JFrog Artifactory OSS
wget -O artifactory.tar.gz https://releases.jfrog.io/artifactory/artifactory-oss/org/artifactory/oss/jfrog-artifactory-oss/7.77.9/jfrog-artifactory-oss-7.77.9-linux.tar.gz
tar -xzf artifactory.tar.gz
cd jfrog-artifactory-oss-*

# Start Artifactory
nohup ./app/bin/artifactory.sh start &

# Wait to ensure Artifactory has started
sleep 30

# Test MySQL connection (optional)
mysql -h ${db_host} -u ${db_user} -p${db_password} -e "SHOW DATABASES;" || echo "MySQL connection test failed"

echo "JFrog Artifactory installation complete"
