const FrontalLobeFactory = artifacts.require("FrontalLobeFactory");
const AxonFactory = artifacts.require("AxonFactory");


module.exports = function (deployer) {
  deployer.deploy(FrontalLobeFactory);
  deployer.deploy(AxonFactory);
};
