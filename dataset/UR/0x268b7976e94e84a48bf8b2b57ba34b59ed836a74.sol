 

pragma solidity ^0.4.11;

 
contract ERC20Interface {
   
  function totalSupply() constant returns (uint256 totalSupply);

   
  function balanceOf(address _owner) constant returns (uint256 balance);

   
  function transfer(address _to, uint256 _value) returns (bool success);

   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

   
   
   
  function approve(address _spender, uint256 _value) returns (bool success);

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);

   
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

   
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract AICoin is ERC20Interface {

   

   
  string public constant name = 'AICoin';
  string public constant symbol = 'XAI';
  uint8 public constant decimals = 8;
  string public constant smallestUnit = 'Hofstadter';

   
  address m_administrator;
  uint256 m_totalSupply;

   
  mapping(address => uint256) balances;

   
  mapping(address => mapping (address => uint256)) allowed;

   
  function AICoin (uint256 _initialSupply) {
    m_administrator = msg.sender;
    m_totalSupply = _initialSupply;
    balances[msg.sender] = _initialSupply;
  }

   
  function administrator() constant returns (address adminAddress) {
    return m_administrator;
  }

   
  function totalSupply() constant returns (uint256 totalSupply) {
    return m_totalSupply;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

   
  function transfer(address _to, uint256 _amount) returns (bool success) {
    if (balances[msg.sender] >= _amount
        && _amount > 0
        && balances[_to] + _amount > balances[_to]
        && (! accountHasCurrentVote(msg.sender))) {
      balances[msg.sender] -= _amount;
      balances[_to] += _amount;
      Transfer(msg.sender, _to, _amount);
      return true;
    } else {
      return false;
    }
  }

   
  function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
    if (balances[_from] >= _amount
        && allowed[_from][msg.sender] >= _amount
        && _amount > 0
        && balances[_to] + _amount > balances[_to]
        && (! accountHasCurrentVote(_from))) {
      balances[_from] -= _amount;
      allowed[_from][msg.sender] -= _amount;
      balances[_to] += _amount;
      Transfer(_from, _to, _amount);
      return true;
    } else {
      return false;
    }
  }

   
  function approve(address _spender, uint256 _amount) returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   

   

   
  struct BallotDetails {
    uint256 start;
    uint256 end;
    uint32 numOptions;  
    bool sealed;
  }

  uint32 public numBallots = 0;  
  mapping (uint32 => string) public ballotNames;
  mapping (uint32 => BallotDetails) public ballotDetails;
  mapping (uint32 => mapping (uint32 => string) ) public ballotOptions;

   
  function adminAddBallot(string _proposal, uint256 _start, uint256 _end) {

     
    require(msg.sender == m_administrator);

     
    numBallots++;
    uint32 ballotId = numBallots;
    ballotNames[ballotId] = _proposal;
    ballotDetails[ballotId] = BallotDetails(_start, _end, 0, false);
  }

   
  function adminAmendBallot(uint32 _ballotId, string _proposal, uint256 _start, uint256 _end) {

     
    require(msg.sender == m_administrator);

     
    require(_ballotId > 0 && _ballotId <= numBallots);

     
    ballotNames[_ballotId] = _proposal;
    ballotDetails[_ballotId].start = _start;
    ballotDetails[_ballotId].end = _end;
  }

   
  function adminAddBallotOption(uint32 _ballotId, string _option) {

     
    require(msg.sender == m_administrator);

     
    require(_ballotId > 0 && _ballotId <= numBallots);

     
    if(isBallotSealed(_ballotId)) {
      revert();
    }

     
    ballotDetails[_ballotId].numOptions += 1;
    uint32 optionId = ballotDetails[_ballotId].numOptions;
    ballotOptions[_ballotId][optionId] = _option;
  }

   
  function adminEditBallotOption(uint32 _ballotId, uint32 _optionId, string _option) {

     
    require(msg.sender == m_administrator);

     
    require(_ballotId > 0 && _ballotId <= numBallots);

     
    if(isBallotSealed(_ballotId)) {
      revert();
    }

     
    require(_optionId > 0 && _optionId <= ballotDetails[_ballotId].numOptions);

     
    ballotOptions[_ballotId][_optionId] = _option;
  }

   
  function adminSealBallot(uint32 _ballotId) {

     
    require(msg.sender == m_administrator);

     
    require(_ballotId > 0 && _ballotId <= numBallots);

     
    if(isBallotSealed(_ballotId)) {
      revert();
    }

     
    ballotDetails[_ballotId].sealed = true;
  }

   
  function isBallotInProgress(uint32 _ballotId) private constant returns (bool) {
    return (isBallotSealed(_ballotId)
            && ballotDetails[_ballotId].start <= now
            && ballotDetails[_ballotId].end >= now);
  }

   
  function hasBallotEnded(uint32 _ballotId) private constant returns (bool) {
    return (ballotDetails[_ballotId].end < now);
  }

   
  function isBallotSealed(uint32 _ballotId) private returns (bool) {
    return ballotDetails[_ballotId].sealed;
  }

   

  mapping (uint32 => mapping (address => uint256) ) public ballotVoters;
  mapping (uint32 => mapping (uint32 => uint256) ) public ballotVoteCount;

   
  function vote(uint32 _ballotId, uint32 _selectedOptionId) {

     
    require(_ballotId > 0 && _ballotId <= numBallots);

     
    require(isBallotInProgress(_ballotId));

     
    uint256 votableBalance = balanceOf(msg.sender) - ballotVoters[_ballotId][msg.sender];
    require(votableBalance > 0);

     
    require(_selectedOptionId > 0 && _selectedOptionId <= ballotDetails[_ballotId].numOptions);

     
    ballotVoteCount[_ballotId][_selectedOptionId] += votableBalance;
    ballotVoters[_ballotId][msg.sender] += votableBalance;
  }

   
  function hasAddressVotedInBallot(uint32 _ballotId, address _voter) constant returns (bool hasVoted) {
    return ballotVoters[_ballotId][_voter] > 0;
  }

   
  function accountHasCurrentVote(address _voter) constant returns (bool) {
    for(uint32 id = 1; id <= numBallots; id++) {
      if (isBallotInProgress(id) && hasAddressVotedInBallot(id, _voter)) {
        return true;
      }
    }
    return false;
  }
}