pragma solidity ^0.5.3;

/// @title NeuronFactoryI
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The NeuronFactoryI contract is an interface contract used by the Matrix to select a Neuron by name and genesis a
      new intstance of that neuron from is Neuron Factory
**/

 contract MatrixI {
  function _neuroGensis(address _Cortex, string memory _neuronName)
      public
      returns (address);

      function createSynaps(
        string memory _tokenName,
        string memory _tokenSym,
        bool _isTransferable,
        bool _isRep,
        address _Creator,
        uint256 _maxSupply
      ) public
      returns(address);

}
