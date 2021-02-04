pragma solidity ^0.6.2;

/// @title NeuronI
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The CortexI contract is an interface contract used by the cortex do gather Neuron permission data
      when installing a neuron. This Interface can be inherited by a Neuron.
**/

abstract contract NeuronI {

    /// @notice isDelegator is a function used to help set up a FrontalLobe to a Cortex properly
    bool public isDelegator;
}
