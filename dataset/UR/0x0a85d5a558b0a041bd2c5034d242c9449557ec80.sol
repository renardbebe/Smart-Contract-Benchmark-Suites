 

pragma solidity ^0.4.25;


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


 
contract MintableTokenStub {
  address public minter;

  event Mint(address indexed to, uint256 amount);

   
  constructor (
    address _minter
  ) public {
    minter = _minter;
  }

   
  modifier onlyMinter() {
    require(msg.sender == minter);
    _;
  }

  function mint(address _to, uint256 _amount)
  public
  onlyMinter
  returns (bool)
  {
    emit Mint(_to, _amount);
    return true;
  }

}


 
contract Congress {
  using SafeMath for uint256;
   
  uint public voters;

   
  mapping(address => bool) public voter;

   
  mapping(bytes32 => MintProposal) public mintProposal;

   
   
  mapping(address => TrustRecord) public trustRegistry;

   
  MintableTokenStub public token;

   
  event TokenSet(address voter, address token);

   
  event MintProposalAdded(
    bytes32 proposalHash,
    address to,
    uint amount,
    string batchCode
  );

  event MintProposalVoted(
    bytes32 proposalHash,
    address voter,
    uint numberOfVotes
  );

  event MintProposalExecuted(
    bytes32 proposalHash,
    address to,
    uint amount,
    string batchCode
  );

   
  event TrustSet(address issuer, address subject);
  event TrustUnset(address issuer, address subject);

   
  event VoteGranted(address voter);
  event VoteRevoked(address voter);

   
   
  struct MintProposal {
    bool executed;
    uint numberOfVotes;
    mapping(address => bool) voted;
  }

   
  struct TrustRecord {
    uint256 totalTrust;
    mapping(address => bool) trustedBy;
  }


   
  modifier onlyVoters {
    require(voter[msg.sender]);
    _;
  }

   
  constructor () public {
    voter[msg.sender] = true;
    voters = 1;
  }

   
  function isMajority(uint256 votes) public view returns (bool) {
    return (votes >= voters.div(2).add(1));
  }

   
  function getTotalTrust(address subject) public view returns (uint256) {
    return (trustRegistry[subject].totalTrust);
  }

   
  function trust(address _subject) public onlyVoters {
    require(msg.sender != _subject);
    require(token != MintableTokenStub(0));
    if (!trustRegistry[_subject].trustedBy[msg.sender]) {
      trustRegistry[_subject].trustedBy[msg.sender] = true;
      trustRegistry[_subject].totalTrust = trustRegistry[_subject].totalTrust.add(1);
      emit TrustSet(msg.sender, _subject);
      if (!voter[_subject] && isMajority(trustRegistry[_subject].totalTrust)) {
        voter[_subject] = true;
        voters = voters.add(1);
        emit VoteGranted(_subject);
      }
      return;
    }
    revert();
  }

   
  function untrust(address _subject) public onlyVoters {
    require(token != MintableTokenStub(0));
    if (trustRegistry[_subject].trustedBy[msg.sender]) {
      trustRegistry[_subject].trustedBy[msg.sender] = false;
      trustRegistry[_subject].totalTrust = trustRegistry[_subject].totalTrust.sub(1);
      emit TrustUnset(msg.sender, _subject);
      if (voter[_subject] && !isMajority(trustRegistry[_subject].totalTrust)) {
        voter[_subject] = false;
         
        voters = voters.sub(1);
        emit VoteRevoked(_subject);
      }
      return;
    }
    revert();
  }

   
  function setToken(
    MintableTokenStub _token
  )
  public
  onlyVoters
  {
    require(_token != MintableTokenStub(0));
    require(token == MintableTokenStub(0));
    token = _token;
    emit TokenSet(msg.sender, token);
  }

   
  function mint(
    address to,
    uint256 amount,
    string batchCode
  )
  public
  onlyVoters
  returns (bool)
  {
    bytes32 proposalHash = keccak256(abi.encodePacked(to, amount, batchCode));
    assert(!mintProposal[proposalHash].executed);
    if (!mintProposal[proposalHash].voted[msg.sender]) {
      if (mintProposal[proposalHash].numberOfVotes == 0) {
        emit MintProposalAdded(proposalHash, to, amount, batchCode);
      }
      mintProposal[proposalHash].numberOfVotes = mintProposal[proposalHash].numberOfVotes.add(1);
      mintProposal[proposalHash].voted[msg.sender] = true;
      emit MintProposalVoted(proposalHash, msg.sender, mintProposal[proposalHash].numberOfVotes);
    }
    if (isMajority(mintProposal[proposalHash].numberOfVotes)) {
      mintProposal[proposalHash].executed = true;
      token.mint(to, amount);
      emit MintProposalExecuted(proposalHash, to, amount, batchCode);
    }
    return (true);
  }
}