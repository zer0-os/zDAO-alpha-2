const Matrix = artifacts.require("Matrix");
const VotingAppFactory = artifacts.require("VotingAppFactory");
const TokenLockFactory = artifacts.require("TokenLockFactory");


module.exports = function (deployer) {
  deployer.deploy(Matrix, ["FrontalLobe", "Axon"], [VotingAppFactory.address, TokenLockFactory.address]);
};
