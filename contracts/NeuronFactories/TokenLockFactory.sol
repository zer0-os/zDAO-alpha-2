pragma solidity ^0.6.2;

import "../CoreNuerons/TokenLock.sol";
import "../Matrix/Hippocampus.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title TokenLockFactory
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The TokenLockFactory contract is designed to produce individual TokenLock contracts
**/

contract TokenLockFactory {
    /**
    @notice genesis is called to create a new TokenLock contract
    @param _DAO is the address of the Cortex DAO that will own the created
            TokenLock
    **/
    function genesis(address _DAO) public returns (address) {
        TokenLock ax = new TokenLock(_DAO);
        return address(ax);
    }
}
