pragma solidity ^0.5.3;

/// @title NeuronI
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The CortexI contract is an interface contract used by the cortex do gather Neuron permission data
      when installing a neuron. This Interface can be inherited by a Neuron.
**/

 contract NeuronI {

    /// @notice isDelegator is a function used to help set up a FrontalLobe to a Cortex properly
    bool public isDelegator;

    function connectNeuron(
        address _synaps,
        uint256 _quorum,
        uint256 _proposalTime,
        bool _transferableRep
    ) public;
}
