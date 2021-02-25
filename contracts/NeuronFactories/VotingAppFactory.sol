pragma solidity ^0.5.3;


import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import '@openzeppelin/upgrades/contracts/upgradeability/ProxyFactory.sol';
////////////////////////////////////////////////////////////////////////////////////////////
/// @title VotingAppFactory
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The VotingAppFactory contract is designed to produce individual VotingApp contracts
**/

contract VotingAppFactory is Initializable, Ownable, ProxyFactory {
  address public votingInstance;

  function initialize(address _Matrix, address _VotingInstance) public {
    Ownable.initialize(_Matrix);
    votingInstance = _VotingInstance;
  }
    /**
    @notice genesis is called to create a new VotingApp contract
    @param _DAO is the address of the Cortex DAO that will own the created
            VotingApp
    **/
    function genesis(address _DAO) public returns (address) {
        bytes memory payload = abi.encodeWithSignature("initialize(address)", _DAO);
        address fl = deployMinimal(votingInstance, payload);
        return address(fl);
    }
}
