const Matrix = artifacts.require("Matrix");
const FrontalLobeFactory = artifacts.require("FrontalLobeFactory");
const AxonFactory = artifacts.require("AxonFactory");


module.exports = function (deployer) {
  deployer.deploy(Matrix, ["FrontalLobe", "Axon"], [FrontalLobeFactory.address, AxonFactory.address]);
};
