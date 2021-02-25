pragma solidity ^0.5.3;
pragma experimental ABIEncoderV2;

import "../Interfaces/CortexI.sol";
import "../Interfaces/NeuronFactoryI.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import '@openzeppelin/upgrades/contracts/upgradeability/ProxyFactory.sol';

////////////////////////////////////////////////////////////////////////////////////////////
/// @title Matrix
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The Matrix contract is designed to produce and track individual ZDAO contracts
**/

contract Matrix is Initializable, Ownable, ProxyFactory {

    address public cortexInstance;
    address public synapsInstance;
    /// @notice cortexTracker is used to track a DAO's name to its address
    mapping(string => address) private cortexTracker;
    /// @notice nameTaken is used to track whether or not a DAO exists with a certain name
    mapping(string => bool) private nameTaken;
    ///@notice neuralNetwork is used to track a neuron name to its factories address
    mapping(string => address) private neuralNetwork;
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


    event CortexCreated(address _cortexAdd, string _cotexName);

    /**
    @notice the initialize is fired only once during contract creation and is used to set up variables in the contract
    @param _NeuronNames is an array of all availible core neuron names availible at deployment time
    @param _initialCoreNeurons is an array of all availible core neuron addresses availible at deployment time
    **/
    function initialize(
      address _cortexInstance,
      address _synapsInstance,
      string[] memory _NeuronNames,
      address[] memory _initialCoreNeurons
    ) initializer
      public {
        Ownable.initialize(msg.sender);
        cortexInstance = _cortexInstance;
        synapsInstance = _synapsInstance;
        require(
            _NeuronNames.length == _initialCoreNeurons.length,
            "Error: Array Length Mismatch"
        );
        //loop through and store neuron info
        for (uint256 i = 0; i < _initialCoreNeurons.length; ++i) {
            neuralNetwork[_NeuronNames[i]] = _initialCoreNeurons[i];
            isNeuron[_initialCoreNeurons[i]] = true;
            coreNeurons.push(_initialCoreNeurons[i]);
        }
    }

    /**
     @notice createCortex is a public function that allows a user to create their own zDAO
     @dev this function can create a rep token for the new DAO OR use an existing ERC20 token
     @param _CortexName is the name of the DAO being created
     @param _tokenName is the name of the DAO's rep token(leave blank if using an existing token)
     @param _tokenSym is the symbol of the DAO's rep token(leave blank if using an existing token)
     @param _synaps is the address of an existing ERC20 token that can represent the DAO's rep
                (this would be set to 0x0 if not applicapble)
     @param _isTransferable is a bool representing whether or not the rep token is transferable
    **/
    function createCortex(
        string memory _CortexName,
        string memory _tokenName,
        string memory _tokenSym,
        address _synaps,
        bool _isTransferable,
        uint256 _maxSupply
    ) public {
        require(
            nameTaken[_CortexName] != true,
            "Name Error: This DAO name is already taken"
        );

        CortexI newCortex;
        ///if we are not using an existing token
        if (_synaps == 0x0000000000000000000000000000000000000000) {
          bytes memory payload = abi.encodeWithSignature("initialize(string,string,string,address,address,address,bool,uint256)",
          _CortexName,
          _tokenName,
          _tokenSym,
          0x0000000000000000000000000000000000000000,
          msg.sender,
          neuralNetwork["VotingApp"],
          _isTransferable,
          _maxSupply
        );
            newCortex = CortexI(deployMinimal(cortexInstance, payload));
            cortexTracker[_CortexName] = address(newCortex);

        } else {

          bytes memory payload = abi.encodeWithSignature("initialize(string,string,string,address,address,address,bool,uint256)",
          _CortexName,
          _tokenName,
          _tokenSym,
          _synaps,
          msg.sender,
          neuralNetwork["VotingApp"],
          _isTransferable,
          _maxSupply
        );
          ///if we are using and existing token
            newCortex = CortexI(deployMinimal(cortexInstance, payload));
            cortexTracker[_CortexName] = address(newCortex);
        }

        nameTaken[_CortexName] = true;
        emit CortexCreated(address(newCortex), _CortexName);
    }

    /**
     @notice retrieveCortex is used to retrieve a Cortex's address by its name
     @dev this is a view only function for front end use
     @param _Name is the name of the Cortex who's address is being retrieved
     @return the address of the Cortex
    **/
    function retrieveCortex(string memory _Name) public view returns (address) {
        return cortexTracker[_Name];
    }

    /**
     @notice cortexNameTaken is used to determine if a name for a Cortex is currently in use
     @dev this is a view only function for front end use
     @param _Name is the proposed name of a Cortex
     @return a bool(true/false) for whether or not a Cortex with the input name exists
    **/
    function cortexNameTaken(string memory _Name) public view returns (bool) {
        return nameTaken[_Name];
    }

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
        bytes memory payload = abi.encodeWithSignature("initialize(string,string,bool,bool,address,address,uint256)",
        _tokenName,
        _tokenSym,
        _isTransferable,
        _isRep,
        _Creator,
        msg.sender,
        _maxSupply
      );
        address syn = deployMinimal(synapsInstance, payload);
          return syn;
        }

        function updateCortex(address _newCortexInstance) public onlyOwner {
          cortexInstance = _newCortexInstance;
        }

        function updateSynaps(address _newSynapsInstance) public onlyOwner {
          synapsInstance = _newSynapsInstance;
        }
}
