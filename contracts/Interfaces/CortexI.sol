pragma solidity ^0.5.3;

/// @title CortexI
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The CortexI contract is an interface contract used by neurons to delegate a call to the
    Cortex Contract
**/

 contract CortexI {
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
    ) public;

    function transferOwnership(address _newOwner) public;

}
