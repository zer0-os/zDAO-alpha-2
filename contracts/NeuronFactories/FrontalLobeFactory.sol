pragma solidity ^0.6.2;

import "../CoreNuerons/FrontalLobe.sol";
import "../Matrix/Hippocampus.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title FrontalLobeFactory
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The FrontalLobeFactory contract is designed to produce individual FrontalLobe contracts
**/

contract FrontalLobeFactory {
    /**
    @notice genesis is called to create a new FrontalLobe contract
    @param _DAO is the address of the Cortex DAO that will own the created
            FrontalLobe
    **/
    function genesis(address _DAO) public returns (address) {
        FrontalLobe fl = new FrontalLobe(_DAO);
        return address(fl);
    }
}
