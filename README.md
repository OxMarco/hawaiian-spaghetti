# Hawaiian Spaghetti
Codebase for the practical part of the workshop *An intro to degen DeFi strategies*.

## How to use it
We assume NodeJS v16 to be installed and properly configured.

Follow the steps to setup your local machine for the workshop.
1. fetch the required dependencies using `npm install` or (preferred) `yarn install`.
2. add your Alchemy (http://alchemy.com) key to the *.env* file (use the *.env.example* file as a reference)
3. load the *.env* file locally (on Unix systems, `source .env`)
4. compile the code with `yarn compile` or `npm run compile`
5. run the tests using `yarn test` or `npm run test`
6. you are ready to start

### Troubleshooting
For any problems with hardhat follow the documentation here https://hardhat.org/tutorial/setting-up-the-environment.html
