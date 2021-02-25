const VotingAppFactory = artifacts.require("VotingAppFactory");
const VotingApp = artifacts.require("VotingApp");
const TokenLockFactory = artifacts.require("TokenLockFactory");
const TokenLock = artifacts.require("TokenLock");
const Cortex = artifacts.require("Cortex");
const Cortex2 = artifacts.require("Cortex2");
const Synaps = artifacts.require("Synaps");
const Matrix = artifacts.require("Matrix");

module.exports = async function (deployer) {
  await deployer.deploy(VotingAppFactory);
  await deployer.deploy(TokenLockFactory);
  await deployer.deploy(VotingApp);
  await deployer.deploy(TokenLock);
  await deployer.deploy(Cortex);
  await deployer.deploy(Synaps);
  await deployer.deploy(Matrix);
  await deployer.deploy(Cortex2);

  let matrix = await Matrix.deployed();
  let voteF = await VotingAppFactory.deployed();
  let lockF = await  TokenLockFactory.deployed();

  await matrix.initialize(Cortex.address, Synaps.address,["VotingApp", "TokenLock"], [VotingAppFactory.address, TokenLockFactory.address]);
  await voteF.initialize(matrix.address, VotingApp.address)
  await lockF.initialize(matrix.address, TokenLockFactory.address)
};
