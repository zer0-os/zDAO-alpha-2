pragma solidity ^0.6.2;

import "./Synaps.sol";
import "../Interfaces/NeuronFactoryI.sol";
import "../Interfaces/NeuronI.sol";
import "../Matrix/Hippocampus.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title Cortex
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The Cortex contract is designed to be a bare bones, minimalistic approach to a versitile DAO structure. The Cortex is designed as
    the control center that Allows a DAO to work with neuron contracts and contracts outside of the zer0 ecosystem.
**/

contract Cortex is Ownable {
    using SafeMath for uint256;

    /// @notice the Cortex's name
    string public daoName;
    /// @notice the hippocampus is the contract responsible for tracking neuron factories for installation
    Hippocampus public hippocampus;
    /// @notice synapsCount is used to track the number of synaps contracts this cortex controls
    uint256 public synapsCount;
    /// @notice the synaps stored to the contract is the synaps used for
    mapping(uint256 => Synaps) public synapses;
    /// @notice approvedMintContracts is a mapping of which addresses have the ability to call the proxyMint function
    mapping(address => bool) public approvedMintContracts;
    /// @notice approvedBurnContracts is a mapping of which addresses have the ability to call the proxyBurn function
    mapping(address => bool) public approvedBurnContracts;
    /// @notice approvedDelegateCallContracts is a mapping of which addresses have the ability to call the delegateFunctionCall function
    mapping(address => bool) public approvedDelegateCallContracts;
    /// @notice installedNeurons is an address array containing the addresses of all installed Neurons
    address[] public installedNeurons;

    /// @notice onlyApprovedMinter is a modifier that prevents an unapproved address from calling the proxyMint function
    modifier onlyApprovedMinter() {
        require(
            approvedMintContracts[msg.sender] == true,
            "Caller is not an approved Minter address"
        );
        _;
    }
    /// @notice onlyApprovedBurner is a modifier that prevents an unapproved address from calling the proxyBurn function
    modifier onlyApprovedBurner() {
        require(
            approvedBurnContracts[msg.sender] == true,
            "Caller is not an approved Burner address"
        );
        _;
    }

    /// @notice onlyApprovedDelegator is a modifier that prevents an unapproved address from calling the delegateFunctionCall function
    modifier onlyApprovedDelegator() {
        require(
            approvedDelegateCallContracts[msg.sender] == true,
            "Caller is not an approved Delegate address"
        );
        _;
    }

    /**
     @notice the constructor function is fired only once during contract creation and is used to set up
        the Cortex contract and its first synaps if applicable
     @dev this function automatically deploys a synaps for the DAO if the _synaps param is set to the 0x0 address
     @param _daoName is the name of the zDAO
     @param _hippocampus is the address of the Hippocampus contract
     @param _tokenName is the name of the DAO's rep token(if applicable)
     @param _tokenSym is the symbol of the DAO's rep token(if applicable)
     @param _synaps is the address of an existing Synaps (or ERC20)
     @param _CortexCreator is the address of the account that created the Cortex
     @param _isTransferable is a bool representing whether or not a DAO's rep token can be transfered from one account to another
    **/
    constructor(
        string memory _daoName,
        address _hippocampus,
        string memory _tokenName,
        string memory _tokenSym,
        address _synaps,
        address _CortexCreator,
        bool _isTransferable,
        uint256 _maxSupply
    ) public {
        daoName = _daoName;
        hippocampus = Hippocampus(_hippocampus);
        if (_synaps == 0x0000000000000000000000000000000000000000) {
            synapses[0] = new Synaps(
                _tokenName,
                _tokenSym,
                _isTransferable,
                true,
                _CortexCreator,
                _maxSupply
            );
        } else {
            synapses[0] = Synaps(_synaps);
        }
        synapsCount++;
    }

    ///fallback function so this contract can receive ETH
    receive() external payable {}

    ///////////////// Generation Function Calls////////////////////////////////////////////
    /**
      @notice The following are Generation function calls used to create/add new neurons abd synapses
      to the cortex
    **/
    /////////////////////////////////////////////////////////////////////////////////

    /**
    @notice neuroGenesis is used by the cortex to communicate with the Hippocampus inorder to create a new neuron instance for itself
    @param _neuronName is the name of the neuron that is being installed on the Cortex
    @param _amount is an amount in ETH to be transfered along with the connectNeuron function on the neuron(this acts like a constructor function for the neuron)
    @param call_data is the bytes data for calling the connectNeuron function on a neuron
    **/
    function neuroGenesis(
        string memory _neuronName,
        uint256 _amount,
        bytes memory call_data
    ) public onlyOwner {
        NeuronI neuron =
            NeuronI(hippocampus._neuroGensis(address(this), _neuronName));
        address neu = address(neuron);
        (bool success, bytes memory data) =
            payable(neu).call{value: _amount}(call_data);
        require(success, "failed calling connectNeuron");
        approvedMintContracts[address(neuron)] = neuron.isMinter();
        approvedBurnContracts[address(neuron)] = neuron.isBurner();
        approvedDelegateCallContracts[address(neuron)] = neuron.isDelegator();
        installedNeurons.push(address(neuron));
    }

    /**
    @notice the createSynaps function allows a Cortex to create a new Synaps contract
    @param _tokenName is the name of the DAO's rep token(if applicable)
    @param _tokenSym is the symbol of the DAO's rep token(if applicable)
    @param _CortexCreator is the address of the CortexCreator OR the address to receive the first synaps token
    @param _isTransferable is a bool representing whether of not a synaps is transferable
    @param _isRep is a bool representing whether or not a synaps is used as reputation
    **/
    function createSynaps(
        string memory _tokenName,
        string memory _tokenSym,
        address _CortexCreator,
        bool _isTransferable,
        bool _isRep,
        uint256 _maxSupply
    ) public onlyOwner returns (address) {
        synapses[synapsCount] = new Synaps(
            _tokenName,
            _tokenSym,
            _isTransferable,
            _isRep,
            _CortexCreator,
            _maxSupply
        );
        address syn = address(synapses[synapsCount]);
        synapsCount++;
        return syn;
    }

    ///////////////// Proxy Function Calls////////////////////////////////////////////
    /**
  @notice The following are proxy function calls whic can be called by a neuron contract with the proper
          permissions. These functions allow the cotex to perform any action that a normal ethereum account
          could perform along with functionality to proxy mint and burn synaps tokens contracts it controls.
**/
    /////////////////////////////////////////////////////////////////////////////////
    /**
    @notice delegateFunctionCall allows a neuron contract to make an arbitrary call from the Cortex
    @param _target is the target address where the function will be called
    @param _amount is an eth amount to be passed from the Cortex in the function call(put zero if not applicable)
    @param call_data is a bytes representation of the function the Cortex is calling and its input paramters
    **/
    function delegateFunctionCall(
        address payable _target,
        uint256 _amount,
        bytes memory call_data
    ) public onlyApprovedDelegator {
        (bool success, bytes memory data) =
            _target.call{value: _amount}(call_data);
        require(success, "delegateFunctionCall Failed");
    }

    /**
    @notice transferETH is used to easily transfer ETH from the cortex contract
    @param _to is the address tokens are being minted to
    @param _amount is the amount of tokens being minted
    @dev this function is intended to be used with the proposal system
    **/
    function transferETH(address payable _to, uint256 _amount)
        public
        onlyOwner
    {
        _to.transfer(_amount);
    }

    /**
    @notice proxyMint allows an approved minter address to mint tokens from the synaps contract
    @param _to is the address tokens are being minted to
    @param _amount is the amount of tokens being minted
    **/
    function proxyMint(
        address _to,
        uint256 _amount,
        uint256 _synapsID
    ) public onlyApprovedMinter {
        Synaps syn = synapses[_synapsID];
        syn._Mint(_to, _amount);
    }

    /**
    @notice proxyBurn allows an approved burner address to burn the synaps tokens from an account
    @param _from is the address the tokens are being burnt from
    @param _amount is the amount of tokens being burnt
    **/
    function proxyBurn(
        address _from,
        uint256 _amount,
        uint256 _synapsID
    ) public onlyApprovedBurner {
        Synaps syn = synapses[_synapsID];
        syn._Burn(_from, _amount);
    }

    ///////////////// Permission Function Calls////////////////////////////////////////////
    /**
      @notice The following are permission control functions for the Cortex contract. These functions are onlyOwner
              which means that only the DAO itself can call these functions with the delegateFunctionCall
              functionality OR the neuroGenesis functionality
    **/
    /////////////////////////////////////////////////////////////////////////////////

    /**
    @notice addMinter allows the owner of this contract to add a address to the approved minter list
    @param _minter is the address of the contract being added to the list
    **/
    function addMinter(address _minter) public onlyOwner {
        approvedMintContracts[_minter] = true;
    }

    /**
    @notice addBurner allows the owner of this contract to add a contract to the approved burner list
    @param _burner is the address of the contract being added to the list
    **/
    function addBurner(address _burner) public onlyOwner {
        approvedBurnContracts[_burner] = true;
    }

    /**
    @notice addDelegate allows the owner of this contract to add a contract to the approved delegate list
    @param _delegate is the address of the contract being added to the list
    **/
    function addDelegate(address _delegate) public onlyOwner {
        approvedBurnContracts[_delegate] = true;
    }

    /**
        @notice addMinter allows the owner of this contract to add a address to the approved minter list
        @param _minter is the address of the contract being added to the list
        **/
    function removeMinter(address _minter) public onlyOwner {
        approvedMintContracts[_minter] = false;
    }

    /**
        @notice addBurner allows the owner of this contract to add a contract to the approved burner list
        @param _burner is the address of the contract being added to the list
        **/
    function removeBurner(address _burner) public onlyOwner {
        approvedBurnContracts[_burner] = false;
    }

    /**
        @notice removeDelegate allows the owner of this contract to add a contract to the approved delegate list
        @param _delegate is the address of the contract being added to the list
        **/
    function removeDelegate(address _delegate) public onlyOwner {
        approvedBurnContracts[_delegate] = false;
    }
}
