
set -e
cd functions/addTables
npm i
npm ci

cd ../createOrder
npm i
npm ci

cd ../getOrder
npm i
npm ci

cd ../processOrder
npm i
npm ci

cd ../updateStock
npm i
npm ci

cd ../..

terraform apply -var-file=variables.tfvars