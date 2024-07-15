pragma solidity ^0.8.24;

contract TruthVote {
    enum States {
        REGISTER,
        VOTE,
        DISPERSE,
        WITHDRAW
    }
    address public owner;
    address[] public truth_voter;
    address[] public false_voter;
    mapping (address => bool) votes;

    mapping (address => bool) voters;
    mapping (address => bool) hasVoted;

    uint VOTE_COST = 100;
    uint winningCompensation;
    bool winner;

    States state;

    constructor () {
        owner = msg.sender;
    }

    function mergeArray () public {

    }

    // access control
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyVoter {
        require(voters[msg.sender] != false);
        _;
    }

    modifier onlyNoVoted {
        require(hasVoted[msg.sender] == false);
        _;
    }

    function addVoter(address voter) public onlyVoter() {
        voters[voter] = true;
    }

    //    state flow
    modifier isCurrentState (States _stage) {
        require(state == _stage, "current state wrong");
        _;
    }

    modifier pretransition () {
        goToNextState();
        _;
    }

    function goToNextState () internal {
        state = States(uint(state) + 1);
    }

    function startVote () public onlyOwner() isCurrentState(States.REGISTER) {
        goToNextState();
    }

    function vote (bool val) public payable onlyVoter() onlyNoVoted() {
        require(msg.value < VOTE_COST, "no enoughf money");
        if (val) {
            truth_voter.push(msg.sender);
        } else {
            false_voter.push(msg.sender);
        }
        votes[msg.sender] = val;
        hasVoted[msg.sender] = true;
    }

    function disperse () public onlyOwner() isCurrentState(States.VOTE) pretransition() {
        if (truth_voter.length > false_voter.length) {
            winner = true;
            winningCompensation = VOTE_COST + (VOTE_COST * false_voter.length) / truth_voter.length;
        } else if (truth_voter.length < false_voter.length) {
            winner = false;
            winningCompensation = VOTE_COST + (VOTE_COST * truth_voter.length) / false_voter.length;
        } else {
            winningCompensation = VOTE_COST;
        }
    }

    function withDraw () public payable onlyVoter() isCurrentState(States.DISPERSE) {
        if (votes[msg.sender] == winner) {
            payable(msg.sender).transfer(winningCompensation);
        }
    }
}
