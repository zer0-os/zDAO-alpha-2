pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "../Cortex/Cortex.sol";
import "./Hippocampus.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title Matrix
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The Matrix contract is designed to produce and track individual ZDAO contracts
**/

contract Matrix is Ownable, Hippocampus {
    /// @notice cortexTracker is used to track a DAO's name to its address
    mapping(string => address) public cortexTracker;
    /// @notice nameTaken is used to track whether or not a DAO exists with a certain name
    mapping(string => bool) public nameTaken;

    event CortexCreated(address _cortexAdd, string _cotexName);

    /**
    @notice the constructor is fired only once during contract creation and is used to set up variables in the contract
    @param _NeuronNames is an array of all availible core neuron names availible at deployment time
    @param _initialCoreNeurons is an array of all availible core neuron addresses availible at deployment time
    **/
    constructor(
        string[] memory _NeuronNames,
        address[] memory _initialCoreNeurons
    ) public {
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

        Cortex newCortex;
        ///if we are not using an existing token
        if (_synaps == 0x0000000000000000000000000000000000000000) {
            newCortex = new Cortex(
                _CortexName,
                _tokenName,
                _tokenSym,
                0x0000000000000000000000000000000000000000,
                msg.sender,
                _isTransferable,
                _maxSupply
            );
            cortexTracker[_CortexName] = address(newCortex);
            newCortex.transferOwnership(msg.sender);
        } else {
          ///if we are using and existing token
            newCortex = new Cortex(
                _CortexName,
                _tokenName,
                _tokenSym,
                _synaps,
                msg.sender,
                _isTransferable,
                _maxSupply
            );
            cortexTracker[_CortexName] = address(newCortex);
            newCortex.transferOwnership(msg.sender);
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


}
