#!/bin/bash

# previous run clean up
if [ -d "./dist/layer" ]
then
    rm -rf ./dist/layer
fi
if [ -f "./dist/libs.zip" ]
then
    rm ./dist/libs.zip
fi
if [ -f "./dist/deploy.zip" ]
then
    rm ./dist/deploy.zip
fi
if [ -f "./requirements.txt" ]
then
    rm ./requirements.txt
fi

# build libs package
poetry export --without-hashes -o requirements.txt
poetry run pip install -r requirements.txt --prefix ./dist/layer/python --ignore-installed
cd ./dist/layer
zip -r ../libs.zip .
cd ../..

# build source code package
cd src
zip -r ../dist/deploy.zip . -x ./__pycache__/**\* -x ./__pycache__/\*
cd ..

# clean up
rm -rf ./dist/layer
rm -rf requirements.txt
