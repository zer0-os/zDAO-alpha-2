pragma solidity ^0.5.3;

import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Detailed.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title Synaps
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The Synaps is designed to be a flexible ERC20 token that can be used by a ZDAO in multiple ways.
**/

contract Synaps is  Initializable, ERC20, ERC20Detailed, Ownable {
    using SafeMath for uint256;

    /// @notice maxSupply is used as a cap on the tokens totalSupply
    uint256 public maxSupply;
    /// @notice transferable is a bool representing whether or not this rep token can be transfered by its owner
    bool public transferable;
    ///@notice isRep signafies whether or not the synaps being created will be used as a DAO's rep token
    bool public isRep;
    /// @notice tokenTimeTracker is responsible for tracking when tokens are transfered from one account to another
    /// @dev this is important for making sure proposal voting cant be done with the same tokens using multiple
    ///       accounts
    mapping(address => uint256) public tokenTimeTracker;
    /// @notice tokenSpaceTracker is used to track the amount of tokens an account has when its time is tracked by
    ///    tokenTimeTracker
    mapping(address => uint256) public tokenSpaceTracker;

    /**
     @notice the constructor function is fired only once during contract creation and is used to set up
                the ZDAO rep token
     @dev this function mints one token to the DAO creator so that they can install neurons on the DAO after
                its creation
     @param _tokenName is the name of the token
     @param _tokenSym is the symbol of the token
     @param _isTransferable is a bool representing whether of not this token is transferable
     @param _isRep is a bool representing whether or not this token will be used as a DAO repToken
     @param _DAOcreator is the address of the person who created the DAO that is creating this token.
     @dev if _DAOcreator is equal to the DAO(the msg.sender) and the token is not being used as a rep token
                then the constructor will not mint a first token
     @param _maxSupply is the maximum supply this synaps will be capped at(uncapped == 0)
     **/
    function initialize(
        string memory _tokenName,
        string memory _tokenSym,
        bool _isTransferable,
        bool _isRep,
        address _DAOcreator,
        address _DAO,
        uint256 _maxSupply
    ) initializer
    public {
      ERC20Detailed.initialize(_tokenName, _tokenSym, 18);
        Ownable.initialize(_DAO);
        transferable = _isTransferable;
        isRep = _isRep;
        maxSupply = _maxSupply;
        if (_isRep == true) {
            _mint(_DAOcreator, 1e18);
            tokenRelativity(_DAOcreator);
        }
    }

    /**
    @notice tokenRelativity is used to track which tokens where in an account when
    @param recipient is address being localized
    **/
    function tokenRelativity(address recipient) internal {
        tokenTimeTracker[recipient] = now;
        uint256 currentHodl = balanceOf(recipient);
        tokenSpaceTracker[recipient] = currentHodl;
    }

    /**
     @notice transfer is an override function for the standard ERC20 transfer function
     @dev this override function is used to check if a token allows for transfers
     @param recipient is the address the tokens are being transfered to
     @param amount is the amount of token being transfered
     @return is a bool representing whether or not the transfer was successful
    **/
    function transfer(address recipient, uint256 amount)
        public
        returns (bool)
    {
        if (!transferable) {
            return false;
        } else {
            tokenRelativity(recipient);
            transfer(recipient, amount);
        }
    }

    /**
     @notice _Mint allows the owner of this token contract to mint new tokens
     @dev this function will fail if called by anyone who isnt the contract owner
     @param _to is the address tokens are being minted to
     @param _amount is the amount of tokens being minted
    **/
    function _Mint(address _to, uint256 _amount) public onlyOwner {
        if (maxSupply > 0) {
            require(
                totalSupply().add(_amount) <= maxSupply,
                "Max total supply limit reached"
            );
        }
        tokenRelativity(_to);
        _mint(_to, _amount);
    }

    /**
     @notice _Burn allows the owner of this token contract to burn tokens from an account
     @dev this function will fail if called by anyone other than the owner
     @param _from is the address the tokens are being burnt from
     @param _amount is the amount of tokens being burnt
    **/
    function _Burn(address _from, uint256 _amount) public onlyOwner {
        tokenRelativity(_from);
        _burn(_from, _amount);
    }

    /**
    @notice getRelativePosition is used by the DAO to determine the voting status of an account in DAO's where
            the rep is transferable.
    @dev this is needed to ensure on person cant vote multiple times by transfering his rep to seperate accounts
    @param _account is the account whos position is being calculated
    **/
    function getRelativePosition(address _account)
        public
        view
        returns (uint256 time, uint256 space)
    {
        time = tokenTimeTracker[_account];
        space = tokenSpaceTracker[_account];
    }
}
