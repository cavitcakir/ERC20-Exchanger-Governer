pragma solidity ^0.8.0;
import "./token.sol";

contract Governer is HW2Govern {
    constructor() HW2Govern() {}

    /// @notice The delay before voting on a proposal may take place, once proposed
    function votingDelay() public pure returns (uint) { return 1; } // 1 block

    /// @notice The duration of voting on a proposal, in blocks
    function votingPeriod() public pure returns (uint) { return 20; } // ~5 mins in blocks (assuming 15s blocks)

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    function quorumVotes() public pure returns (uint) { return 100; } // 10% of Gov

    /// @notice The number of votes required in order for a voter to become a proposer
    function proposalThreshold() public pure returns (uint) { return 40; } // 4% of Gov

    struct Proposal {
        // @notice Creator of the proposal
        address proposer;

        // @notice the ordered list of target addresses for calls to be made
        address target;

        // @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint startBlock;

        // @notice The block at which voting ends: votes must be cast prior to this block
        uint endBlock;

        // @notice Current number of votes in favor of this proposal
        uint forVotes;

        // @notice Current number of votes in opposition to this proposal
        uint againstVotes;

        // @notice Flag marking whether the proposal has been canceled
        bool canceled;

        // @notice Flag marking whether the proposal has been executed
        bool registered;

        bool isActive;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        // @notice Whether or not a vote has been cast
        bool hasVoted;

        // @notice Whether or not the voter supports the proposal
        bool support;

        // @notice The number of votes the voter had, which were cast
        uint256 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending, // 0
        Active, // 1
        Canceled, // 2
        Defeated, // 3
        Succeeded, // 4
        Registered // 5
    }

    /// @notice The official record of all proposals, last record for each token
    mapping (address => Proposal) public proposals;
    mapping (address => bool) public registered_tokens;     // registered_tokens[token] = registerd/not_registered
    // @notice Receipts of ballots for the entire set of voters
    mapping (address => mapping (address => Receipt)) public receipts; // receipts[token][voter]


    function propose(address target) public returns (bool success) {
        // require(this.balanceOf(msg.sender) > proposalThreshold(), "GovernorAlpha::propose: proposer votes below proposal threshold");
        require(this.getPriorVotes(msg.sender, sub256(block.number, 1)) > proposalThreshold(), "GovernorAlpha::propose: proposer votes below proposal threshold");

        Proposal storage newProposal = proposals[target];

        require(newProposal.isActive == false, "Only one proposal can be active at time.");
        require(newProposal.registered == false, "This token is already registered.");

        uint startBlock = add256(block.number, votingDelay());
        uint endBlock = add256(startBlock, votingPeriod());

        newProposal.proposer = msg.sender;
        newProposal.target = target;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.canceled = false;
        newProposal.registered = false;
        newProposal.isActive = true;

        // Proposal memory newProposal = Proposal(msg.sender,target,startBlock,endBlock,0,0,false,false);
        return true;
    }

    function castVote(address _addrs, bool support) public {
        return _castVote(msg.sender, _addrs, support);
    }

    function _castVote(address voter, address _addrs, bool support) internal {

        require(state(_addrs) == ProposalState.Active, "GovernorAlpha::_castVote: voting is closed");
        Proposal storage proposal = proposals[_addrs];
        Receipt storage receipt = receipts[_addrs][voter];
        require(proposal.isActive == true, "GovernorAlpha::state: proposal is not active");
        require(receipt.hasVoted == false, "GovernorAlpha::_castVote: voter already voted");

        uint256 votes = this.getPriorVotes(voter, proposal.startBlock);

        if (support) {
            proposal.forVotes = add256(proposal.forVotes, votes);
        } else {
            proposal.againstVotes = add256(proposal.againstVotes, votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;
    }

    function cancel(address _addrs) public {
        ProposalState current_state = state(_addrs);
        require(current_state != ProposalState.Registered, "GovernorAlpha::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[_addrs];
        require(proposal.isActive == true, "GovernorAlpha::state: proposal is not active");
        require(current_state == ProposalState.Defeated || (current_state == ProposalState.Active && (this.getPriorVotes(proposal.proposer, sub256(block.number, 1)) < proposalThreshold())), "GovernorAlpha::cancel: proposer above threshold");

        proposal.canceled = true;
        proposal.isActive = false;
    }

    function getReceipt(address _addrs, address voter) public view returns (Receipt memory) {
        return receipts[_addrs][voter];
    }

    function register(address _addrs) public returns (bool success) {
        ProposalState current_state = state(_addrs);
        require(current_state == ProposalState.Succeeded, "GovernorAlpha::Proposal should Succeeded");

        Proposal storage proposal = proposals[_addrs];
        require(proposal.isActive == true, "GovernorAlpha::state: proposal is not active");

        proposal.registered = true;
        proposal.isActive = false;
        registered_tokens[_addrs] = true;
        return true;
    }

    function state(address _addrs) public view returns (ProposalState) {
        Proposal storage proposal = proposals[_addrs];
        require(proposal.isActive == true, "GovernorAlpha::state: proposal is not active");
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number < proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
            return ProposalState.Defeated;
        } else if (proposal.registered) {
            return ProposalState.Registered;
        } else{
            return ProposalState.Succeeded;
        }
    }

}
