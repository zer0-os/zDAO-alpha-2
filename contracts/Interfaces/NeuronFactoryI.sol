pragma solidity ^0.6.2;

/// @title NeuronFactoryI
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The NeuronFactoryI contract is an interface contract used by the Hippocampus to select a Neuron by name and genesis a
      new intstance of that neuron from is Neuron Factory
**/

abstract contract NeuronFactoryI {
    /**
  @notice genesis is called to create a new FrontalLobe contract
  @param _DAO is the address of the Cortex DAO that will own the created
          FrontalLobe
  **/
    function genesis(address _DAO) public virtual returns (address);
}
