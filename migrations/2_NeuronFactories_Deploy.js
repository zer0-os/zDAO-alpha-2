const VotingAppFactory = artifacts.require("VotingAppFactory");
const TokenLockFactory = artifacts.require("TokenLockFactory");


module.exports = function (deployer) {
  deployer.deploy(VotingAppFactory);
  deployer.deploy(TokenLockFactory);
};
