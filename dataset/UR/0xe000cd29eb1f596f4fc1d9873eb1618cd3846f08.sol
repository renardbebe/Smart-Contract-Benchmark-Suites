 

pragma solidity ^0.4.23;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


contract Vote {
  using SafeMath for uint256;
  struct Proposal {
    uint deadline;
    mapping(address => uint) votes;
    uint yeas;
    uint nays;
    string reason;
    bytes data;
    address target;
  }
  struct Deposit {
    uint balance;
    uint lockedUntil;
  }

  event Proposed(
    uint proposalId,
    uint deadline,
    address target
  );

  event Executed(
    uint indexed proposalId
  );

  event Vote(
    uint indexed proposalId,
    address indexed voter,
    uint yeas,
    uint nays,
    uint totalYeas,
    uint totalNays
  );

  ERC20 public token;
  uint public proposalDuration;
  Proposal[] public proposals;
  mapping(address => Deposit) public deposits;
  mapping(address => bool) public proposers;

  constructor(address _token) {
    proposers[msg.sender] = true;
    token = ERC20(_token);
    proposalDuration = 5;
     
     
     
     
     
     
    proposals.push(Proposal({
      deadline: block.timestamp,
      yeas: 1,
      nays: 0,
      reason: "",
       
      data: hex"7d007ac10000000000000000000000000000000000000000000000000000000000015180",
      target: this
    }));
  }

   
  function deposit(uint units) public {
    require(token.transferFrom(msg.sender, address(this), units), "Transfer failed");
    deposits[msg.sender].balance = deposits[msg.sender].balance.add(units);
  }

   
   
  function withdraw(uint units) external {
    require(deposits[msg.sender].balance >= units, "Insufficient balance");
    require(deposits[msg.sender].lockedUntil < block.timestamp, "Deposit locked");
    deposits[msg.sender].balance = deposits[msg.sender].balance.sub(units);
    token.transfer(msg.sender, units);
  }

   
   
   
   
  function vote(uint proposalId, uint yeas, uint nays) public {

    require(
      proposals[proposalId].deadline > block.timestamp,
      "Voting closed"
    );
    if(proposals[proposalId].deadline > deposits[msg.sender].lockedUntil) {
       
      deposits[msg.sender].lockedUntil = proposals[proposalId].deadline;
    }
     
    proposals[proposalId].votes[msg.sender] = proposals[proposalId].votes[msg.sender].add(yeas).add(nays);
    require(proposals[proposalId].votes[msg.sender] <= deposits[msg.sender].balance, "Insufficient balance");

     
    proposals[proposalId].yeas = proposals[proposalId].yeas.add(yeas);
    proposals[proposalId].nays = proposals[proposalId].nays.add(nays);

    emit Vote(proposalId, msg.sender, yeas, nays, proposals[proposalId].yeas, proposals[proposalId].nays);
  }

   
   
  function depositAndVote(uint proposalId, uint yeas, uint nays) external {
    deposit(yeas.add(nays));
    vote(proposalId, yeas, nays);
  }

   
   
   
  function propose(bytes data, address target, string reason) external {
    require(proposers[msg.sender], "Invalid proposer");
    require(data.length > 0, "Invalid proposal");
    uint proposalId = proposals.push(Proposal({
      deadline: block.timestamp + proposalDuration,
      yeas: 0,
      nays: 0,
      reason: reason,
      data: data,
      target: target
    }));
    emit Proposed(
      proposalId - 1,
      block.timestamp + proposalDuration,
      target
    );
  }

   
   
   
  function execute(uint proposalId) external {
    Proposal memory proposal = proposals[proposalId];
    require(
       
       
      proposal.deadline < block.timestamp || proposal.yeas > (token.totalSupply() / 2),
      "Voting is not complete"
    );
    require(proposal.data.length > 0, "Already executed");
    if(proposal.yeas > proposal.nays) {
      proposal.target.call(proposal.data);
      emit Executed(proposalId);
    }
     
    proposals[proposalId].data = "";
  }

   
  function setProposer(address proposer, bool value) public {
    require(msg.sender == address(this), "Setting a proposer requires a vote");
    proposers[proposer] = value;
  }

   
   
  function setProposalDuration(uint value) public {
    require(msg.sender == address(this), "Setting a duration requires a vote");
    proposalDuration = value;
  }

  function proposalDeadline(uint proposalId) public view returns (uint) {
    return proposals[proposalId].deadline;
  }

  function proposalData(uint proposalId) public view returns (bytes) {
    return proposals[proposalId].data;
  }

  function proposalReason(uint proposalId) public view returns (string) {
    return proposals[proposalId].reason;
  }

  function proposalTarget(uint proposalId) public view returns (address) {
    return proposals[proposalId].target;
  }

  function proposalVotes(uint proposalId) public view returns (uint[]) {
    uint[] memory votes = new uint[](2);
    votes[0] = proposals[proposalId].yeas;
    votes[1] = proposals[proposalId].nays;
    return votes;
  }
}