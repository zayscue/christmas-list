# Christ List Service
A christmas list service for testing purposes

## Setup
1. Create a new .env file at the root of the repo by copying the values from the template.env file
2. Make the build.sh and deploy.sh files located at the root of the repo executable by running the following commands.
```
chmod u+x build.sh
chmod u+x deploy.sh
```
3. Run the following two commands at the root of the repo
```
poetry install
terraform init
```

## Build
Run the following command to build the source code deployment packages
```
./build.sh
```

## Deploy
Run the following command to deploy the project using terraform
```
terraform apply --auto-approve
```