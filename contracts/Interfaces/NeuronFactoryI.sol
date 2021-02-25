pragma solidity ^0.5.3;

/// @title NeuronFactoryI
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The NeuronFactoryI contract is an interface contract used by the Matrix to select a Neuron by name and genesis a
      new intstance of that neuron from is Neuron Factory
**/

 contract NeuronFactoryI {
   bool public isDelegator;
    /**
  @notice genesis is called to create a new FrontalLobe contract
  @param _DAO is the address of the Cortex DAO that will own the created
          FrontalLobe
  **/
    function genesis(address _DAO) public returns (address);
    function connectNeuron(
        address _synaps,
        uint256 _quorum,
        uint256 _proposalTime,
        bool _transferableRep
    ) public ;
}
