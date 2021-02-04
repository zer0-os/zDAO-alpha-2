pragma solidity ^0.6.2;

import "../Interfaces/NeuronFactoryI.sol";
import "../Cortex/Synaps.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title Hippocampus
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The Hippocampus is designed to track and verify Nueron factory contracts
**/

contract Hippocampus is Ownable {
    using SafeMath for uint256;


    ///@notice neuralNetwork is used to track a neuron name to its factories address
    mapping(string => address) public neuralNetwork;
    ///@notice isNeuron is a tracking of whether or not an address is a neuron factory
    mapping(address => bool) public isNeuron;
    ///@notice neuralMapToCortex maps a neuron address to its cortex address
    mapping(address => address) public neuralMapToCortex;
    ///@notice neuralMapFromCortex tracks a cotex address to an array of all neurons it has installed
    mapping(address => address[]) public neuralMapFromCortex;
    /// @notice coreNeurons is an array of all core neuron factory addresses
    address[] public coreNeurons;
    /// @notice peripheralNeurons is an array of a peripheral neuron factory addresses
    address[] public peripheralNeurons;

    /**
    @notice addCoreNueron allows the owner of this contract to add a core neuron to the matrix
    @param _NeuronName is the name of the neuron being added
    @param _neuronFactoryAddress is the factory address for the neuron being added
    **/
    function addCoreNueron(
        string memory _NeuronName,
        address _neuronFactoryAddress
    ) public onlyOwner {
        require(
            neuralNetwork[_NeuronName] ==
                0x0000000000000000000000000000000000000000,
            "Error: neuron name taken"
        );
        neuralNetwork[_NeuronName] = _neuronFactoryAddress;
        isNeuron[_neuronFactoryAddress] = true;
        coreNeurons.push(_neuronFactoryAddress);
    }

    /**
    @notice addPeripheralNueron allows the owner of this contract to add a peripheral neuron to the matrix
    @param _NeuronName is the name of the neuron being added
    @param _neuronFactoryAddress is the factory address for the neuron being added
    **/
    function addPeripheralNueron(
        string memory _NeuronName,
        address _neuronFactoryAddress
    ) public {
        require(
            neuralNetwork[_NeuronName] ==
                0x0000000000000000000000000000000000000000,
            "Error: neuron name taken"
        );
        neuralNetwork[_NeuronName] = _neuronFactoryAddress;
        isNeuron[_neuronFactoryAddress] = true;
        peripheralNeurons.push(_neuronFactoryAddress);
    }

    /**
    @notice _neuroGensis is used by a cortex to generate a new neural instance of a neuron
    @param _Cortex is the address of the cortex who is generating a neuron
    @param _neuronName is the name of the neuron being generated
    **/
    function _neuroGensis(address _Cortex, string memory _neuronName)
        public
        returns (address)
    {
        NeuronFactoryI neuralF = NeuronFactoryI(neuralNetwork[_neuronName]);
        address neuron = neuralF.genesis(_Cortex);
        neuralMapToCortex[neuron] = _Cortex;
        neuralMapFromCortex[_Cortex].push(neuron);
        return neuron;
    }

    /**
    @notice the createSynaps function allows a user to create their own synaps token
    @param _tokenName is the name of the token
    @param _tokenSym is the symbol of the token
    @param _Creator is the address of the person who created the synaps token.
    @param _maxSupply is the maximum supply this synaps will be capped at(uncapped == 0)
    **/
        function createSynaps(
          string memory _tokenName,
          string memory _tokenSym,
          bool _isTransferable,
          bool _isRep,
          address _Creator,
          uint256 _maxSupply
        ) public
        returns(address){
        address syn = address(new Synaps(
              _tokenName,
              _tokenSym,
              _isTransferable,
              _isRep,
              _Creator,
              _maxSupply
          ));
          return syn;
        }
}
