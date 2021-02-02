pragma solidity ^0.6.2;

import "../CoreNuerons/VotingApp.sol";
import "../Matrix/Hippocampus.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title VotingAppFactory
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The VotingAppFactory contract is designed to produce individual VotingApp contracts
**/

contract VotingAppFactory {
    /**
    @notice genesis is called to create a new VotingApp contract
    @param _DAO is the address of the Cortex DAO that will own the created
            VotingApp
    **/
    function genesis(address _DAO) public returns (address) {
        VotingApp fl = new VotingApp(_DAO);
        return address(fl);
    }
}
