pragma solidity ^0.6.2;

import "../CoreNuerons/Axon.sol";
import "../Matrix/Hippocampus.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title AxonFactory
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The AxonFactory contract is designed to produce individual FrontalLobe contracts
**/

contract AxonFactory {
    /**
    @notice genesis is called to create a new Axon contract
    @param _DAO is the address of the Cortex DAO that will own the created
            Axon
    **/
    function genesis(address _DAO) public returns (address) {
        Axon ax = new Axon(_DAO);
        return address(ax);
    }
}
