pragma solidity ^0.5.3;

import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import '@openzeppelin/upgrades/contracts/upgradeability/ProxyFactory.sol';
////////////////////////////////////////////////////////////////////////////////////////////
/// @title TokenLockFactory
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The TokenLockFactory contract is designed to produce individual TokenLock contracts
**/

contract TokenLockFactory is Initializable, Ownable, ProxyFactory{
  address public tokenLockInstance;

  function initialize(address _Matrix, address _tokenLockInstance) public {
    Ownable.initialize(_Matrix);
    tokenLockInstance = _tokenLockInstance;
  }
    /**
    @notice genesis is called to create a new TokenLock contract
    @param _DAO is the address of the Cortex DAO that will own the created
            TokenLock
    **/
    function genesis(address _DAO) public returns (address) {
        bytes memory payload = abi.encodeWithSignature("initialize(address)", _DAO);
        address ax = deployMinimal(tokenLockInstance, payload);
        return address(ax);
    }
}
