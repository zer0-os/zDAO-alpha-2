pragma solidity ^0.5.3;

import "../Cortex/Synaps.sol";
import "../Interfaces/CortexI.sol";
import "../Interfaces/NeuronI.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title VotingApp
/// @author Christopher Dixon
////////////////////////////////////////////////////////////////////////////////////////////
/**
The VotingApp contract is designed to be a simplistic voting system for a Cortex based DAO. The VotingApp
      uses one synaps(or other ERC20) contract to determine a Cortex DAO members voting power.
**/

contract VotingApp is Ownable, NeuronI {
    using SafeMath for uint256;
    /// @notice synaps is the address of the ERC20 token a zDAO is using for its reputation
    Synaps public synaps;

    CortexI public cortex;
    /// @notice proposalID is used to track proposals
    uint256 public proposalID;
    /// @notice proposalTime is the time in seconds a proposal is considered active
    uint256 public proposalTime;
    /// @notice quorum is the minimum percentage of voteWeight needed for a vote to pass
    uint256 public quorum;
    /// @notice transferable is used to determine if a members position needs to be check when voting
    bool public isTransferable;

    /// @notice Proposal stores proposals
    mapping(uint256 => Proposal) public proposals;

    /**
    @notice the modifier onlyMember requires that the function caller must be a member of the DAO to call a function
    @dev this requires the caller to have atleast 1e18 of a token(standard 1 for ERC20's)
    **/
    modifier onlyMember() {
        require(
            synaps.balanceOf(msg.sender) >= 1e18,
            "You are not a member of this DAO"
        );
        _;
    }

    /**
    @notice Proposal struct stores proposal information
    @param maker is the address of the account that made the proposal
    @param target is the address that the call_data will be passed to as a function call
    @param timeCreated is a blockstamp of when a proposal was created
    @param voteWeights stores the current weight of all votes for a proposal
    @param amount is used to store an ETH amount to be passed along with a function call
    @param executed is a bool representing whether or not a proposal has been executed
    @param proposalHash is an IPFS hash for a file representing a proposal
    @param call_data is a bytes representing a function call on the target contract
    @param votes is an array of Vote structs representing a users vote
    @param voted is a mapping that represents whether or not an account has voted
    **/
    struct Proposal {
        address maker;
        address payable target;
        uint256 timeCreated;
        uint256 voteWeights;
        uint256 voteID;
        uint256 amount;
        bool executed;
        bool proposalPassed;
        string proposalHash;
        bytes call_data;
        mapping(uint256 => Vote) votes;
        mapping(address => bool) voted;
    }

    /**
    @notice Vote is a struct used to store the information of a specific vote
    @param inSupport is a bool representing whether a vote supports a proposal or not
    @param voter is the address of the account that voted
    @param voteWeight is the weight of the account who voted based off the # of rep tokens it holds
    **/
    struct Vote {
        bool inSupport;
        address voter;
        uint256 voteWeight;
    }

    /**
@notice the constructor function is fired only once during contract creation and is used to set up
   the FrontalLobe contract to Its Cortex
**/
    function initialize(address _DAO) public initializer {
        Ownable.initialize(_DAO);
        cortex = CortexI(_DAO);
        isDelegator = true;
    }

    /**
    @notice connectNeuron is used to further set up a neuron
    @param _synaps is the address of the synaps(or other ERC20) contract this neuron will use for voting rights/weight
    @param _quorum is the minimum percentage threshold for a vote to pass
    @param _proposalTime is the amount of time a proposal should remain active
    @param _transferableRep is a bool representing whether or not the synaps used for rep is a transferable token
    **/
    function connectNeuron(
        address _synaps,
        uint256 _quorum,
        uint256 _proposalTime,
        bool _transferableRep
    ) public onlyOwner {
        synaps = Synaps(_synaps);
        isTransferable = _transferableRep;
        quorum = _quorum;
        proposalTime = _proposalTime;
    }


    /**
    @notice newProposaln allows a user to create a proposal
    @param _target is the address this proposal is targeting
    @param _proposalHash is an IPFS hash of a file representing a proposal
    @param _calldata is a bytes representation of a function call
    **/
    function newProposal(
        address payable _target,
        uint256 _amount,
        string memory _proposalHash,
        bytes memory _calldata
    ) public payable onlyMember returns (uint256) {
        proposalID++;
        Proposal storage p = proposals[proposalID];
        p.maker = msg.sender;
        p.target = _target;
        p.amount = _amount;
        p.voteWeights = 0;
        p.voteID = 0;
        p.amount = 0;
        p.timeCreated = now;
        p.proposalHash = _proposalHash;
        p.call_data = _calldata;
        return proposalID;
    }

    /**
    @notice setQuorum allows the owner of the DAO(normally set as the the DAO itself) to change
            the quorum used in voting
    @notice _quorum is the input quarum number being set
    **/
    function setQuorum(uint256 _quorum) public onlyOwner {
        quorum = _quorum;
    }

    /**
    @notice percent is an internal function used to calculate the ratio between a given numerator && denominator
    @param _numerator is the numerator of the equation
    @param _denominator is the denominator of the equation
    @param _precision is a precision point to ensure that decimals dont trail outside what the EVM can handle
    **/
    function _percent(
        uint256 _numerator,
        uint256 _denominator,
        uint256 _precision
    ) internal pure returns (uint256 quotient) {
        // caution, check safe-to-multiply here
        uint256 numerator = _numerator * 10**(_precision + 1);
        // with rounding of last digit
        uint256 _quotient = ((numerator / _denominator) + 5) / 10;
        return (_quotient);
    }

    /**
    @notice _checkThreshold is an internal function used by a vote counts to see if enough of the community has voted
    @param _numOfvotes is the total  voteWeight a proposal has received
    @param _numOfTokens is the total supply of the synaps
    @notice this function returns a bool
                -true if the threshold is met
                -false if the threshold is not met
    **/
    function _checkThreshold(uint256 _numOfvotes, uint256 _numOfTokens)
        internal
        view
        returns (bool)
    {
        uint256 percOfMemVoted = _percent(_numOfvotes, _numOfTokens, 2);
        if (_numOfvotes == _numOfTokens) {
            return true;
        }
        if (percOfMemVoted >= quorum) {
            return true;
        } else {
            return false;
        }
    }

    /**
    @notice the vote function allows a DAO member to vote on proposals made to the DAO
    @param _ProposalID is the number ID associated with the particular proposal the user wishes to vote on
    @param  supportsProposal is a bool value(true or false) representing whether or not a member supports a proposal
                    -true if they do support the proposal
                    -false if they do not support the proposal
    @dev this function will trigger the _checkThreshold function which determines if enough members have voted to
              fire the executeProposal function.(this is temporarily removed due to what im assuming are the gas block limit)
    **/
    function vote(uint256 _ProposalID, bool supportsProposal)
        public
        onlyMember
    {
        Proposal storage p = proposals[_ProposalID];
        require(
            p.voted[msg.sender] != true,
            "You Have already voted on this proposal"
        );
        uint256 vw = synaps.balanceOf(msg.sender);
        if (isTransferable) {
            (uint256 time, uint256 space) =
                synaps.getRelativePosition(msg.sender);
            require(
                vw == space,
                "Violating Relativity: Space error token amounts dont match"
            );
            require(
                p.timeCreated >= time,
                "Violating Relativity: Time error token times dont match"
            );
        }
        p.voteID = p.voteID++;
        p.votes[p.voteID] = Vote({
            inSupport: supportsProposal,
            voter: msg.sender,
            voteWeight: vw
        });
        p.voteWeights = p.voteWeights.add(vw);
        p.voted[msg.sender] = true;
        uint256 ts = synaps.totalSupply();
        //checks if enough members have voted
        bool met = _checkThreshold(p.voteWeights, ts);
        if(met) {
          executeProposal(_ProposalID);
        }
    }

    /**
    @notice executeProposal is the function that executes the terms of a proposal
    @dev this function is called by the vote function when the number of votes reaches the quorum
    @param _proposalID is the ID number of the proposal being executed.
    **/
    function executeProposal(uint256 _proposalID)  internal {
        Proposal storage p = proposals[_proposalID];

        if (now.sub(p.timeCreated) >= proposalTime) {
            // mark the proposal as executed and failed
            p.executed = true;
            p.proposalPassed = false;
        } else {
            // sets p equal to the specific proposalNumber

            require(!p.executed, "This proposal has already been executed");

            uint256 yea = 0;
            uint256 nay = 0;

            //this for loop cycles through each members vote and adds its value to the yea or nay tally
            for (uint256 i = 0; i <= p.voteID; ++i) {
                Vote storage v = p.votes[i];

                if (v.inSupport) {
                    yea = yea.add(v.voteWeight);
                } else {
                    nay = nay.add(v.voteWeight);
                }
            }

            //check if the yea votes outway the nay votes
            if (yea > nay) {
                cortex.delegateFunctionCall(p.target, p.amount, p.call_data);

                ///mark the proposal as executed and passed
                p.executed = true;
                p.proposalPassed = true;
            } else {
                // mark the proposal as executed and failed
                p.executed = true;
                p.proposalPassed = false;
            }
        }
    }
}
