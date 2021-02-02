pragma solidity ^0.6.2;

import "../Interfaces/CortexI.sol";
import "../Interfaces/NeuronI.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title TokenLock
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The TokenLock contract is designed to be a token vesting contract for synapses that a cortex
      can use through voting in the FrontalLobe
**/

contract TokenLock is Ownable, NeuronI {
    using SafeMath for uint256;

    /// @notice cortex is the address of the cortex that controls a TokenLock contract
    address public cortex;
    /// @notice vault is a mapping that tracks an address to a Vested struct
    mapping(address => Vested) public vault;

    event Connected(address _cortex);
    /**
    @notice Vested is a struct used to store a specific users vesting data
    @param token is the ERC20 contract being vested
    @param beneficiary is the beneficiary of the vesting
    @param totalAmount is the total amount of token alocated to the beneficiary
    @param releaseCycleTime is the time one release cycle takes to complete in seconds
    @param amountReleasedPerCycle is the amount of token released to the beneficiary per cycle
    @param numberOfCycles is the number of cycles for a certain beneficiary
    @param amountClaimed is the amount of token the beneficiary has claimed
    @param creationTimeStamp is the time stamp for when a vesting period begins
    **/
    struct Vested {
        IERC20 token;
        address beneficiary;
        uint256 totalAmount;
        uint256 releaseCycleTime;
        uint256 amountReleasedPerCycle;
        uint256 numberOfCycles;
        uint256 amountClaimed;
        uint256 creationTimeStamp;
    }

    /// @notice onlyCortex is a modifier that prevents anyone but the cortex from calling a function
    modifier onlyCortex() {
        require(msg.sender == cortex, "Caller is not the cortex");
        _;
    }

    /**
@notice the constructor function is fired only once during contract creation and is used to set up
   the TokenLock contract to Its Cortex
**/
    constructor(address _cortex) public {
        cortex = _cortex;
        transferOwnership(_cortex);
    }

    /**
    @notice connectNeuron is used to further set up a neuron
    **/
    function connectNeuron(address _cortex) public onlyOwner {
        emit Connected(_cortex);
    }

    /**
@notice vestTokens allows a Cortex DAO to lock up an ERC20 token with a release cycle period for a beneficiary
@param _token is the ERC20 contract being vested
@param _beneficiary is the beneficiary of the vesting
@param _releaseCycleTime is the time one release cycle takes to complete in seconds
@param _totalAmount is the total amount of token alocated to the beneficiary
@param _amountPerCycle is the amount of token released to the beneficiary per cycle
@param _numberOfCycles is the number of cycles for a certain beneficiary
**/
    function vestTokens(
        IERC20 _token,
        address _beneficiary,
        uint256 _releaseCycleTime,
        uint256 _totalAmount,
        uint256 _amountPerCycle,
        uint256 _numberOfCycles
    ) public onlyCortex {
        require(
            _amountPerCycle.mul(_numberOfCycles) == _totalAmount,
            "Error: input numbers error"
        );
        require(_token.transfer(address(this), _totalAmount));
        Vested storage v = vault[_beneficiary];
        v.beneficiary = _beneficiary;
        v.token = _token;
        v.totalAmount = _totalAmount;
        v.releaseCycleTime = _releaseCycleTime;
        v.amountReleasedPerCycle = _amountPerCycle;
        v.numberOfCycles = _numberOfCycles;
        v.creationTimeStamp = now;
    }

    /**
@notice claimVestedTokens allows a end user to claim the vested tokens owed to the in an axon contract
@dev this function automagically distributes the appropriate amounts, no input params required!
**/
    function claimVestedTokens() public {
        Vested storage v = vault[msg.sender];
        uint256 timeSinceCreation = now.sub(v.creationTimeStamp);
        uint256 cyclesCompleted =
            calculateCyclesCompleted(timeSinceCreation, v.releaseCycleTime);
        uint256 amountEarned = cyclesCompleted.mul(v.amountReleasedPerCycle);
        uint256 amountToPay = amountEarned.sub(v.amountClaimed);
        v.amountClaimed = v.amountClaimed.add(amountToPay);
        v.token.transfer(msg.sender, amountToPay);
    }

    /**
@notice calculateCyclesCompleted
@param _time is the amount of time the tokens have been vested
@param _oneCycle is the amount of time in seconds that one vesting release cycle is scheduled for
**/
    function calculateCyclesCompleted(uint256 _time, uint256 _oneCycle)
        public
        pure
        returns (uint256)
    {
        return _time.div(_oneCycle);
    }
}
