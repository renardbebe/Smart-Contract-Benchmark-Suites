 

pragma solidity ^0.4.15;

 

 
 
 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Token is ERC20Basic {
   
   
   
   
  function balanceOfAt(address _owner, uint _blockNumber) public constant returns (uint);
}

 
 
 
 
 
contract Ownable {
  address public owner;

   
   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

contract Voting is Ownable {
   
  uint8 public candidates;
   
  Token public msp;
   
  uint public cap;
   
  uint public endBlock;

   
  mapping(address => uint8) public votes;
   
  address[] public voters;

   
   
   
   
   
  function Voting(uint8 _candidatesCount, address _msp, uint _cap, uint _endBlock) public {
    candidates = _candidatesCount;
    msp = Token(_msp);
    cap = _cap;
    endBlock = _endBlock;
  }

   
   
  function vote(uint8 _candidate) public {
    require(_candidate > 0 && _candidate <= candidates);
    assert(endBlock == 0 || getBlockNumber() <= endBlock);
    if (votes[msg.sender] == 0) {
      voters.push(msg.sender);
    }
    votes[msg.sender] = _candidate;
    Vote(msg.sender, _candidate);
  }

   
  function votersCount()
    public
    constant
    returns(uint) {
    return voters.length;
  }

   
   
   
   
   
  function getVoters(uint _offset, uint _limit)
    public
    constant
    returns(address[] _voters, uint8[] _candidates, uint[] _amounts) {
    return getVotersAt(_offset, _limit, getBlockNumber());
  }

   
   
   
   
   
   
  function getVotersAt(uint _offset, uint _limit, uint _blockNumber)
    public
    constant
    returns(address[] _voters, uint8[] _candidates, uint[] _amounts) {

    if (_offset < voters.length) {
      uint count = 0;
      uint resultLength = voters.length - _offset > _limit ? _limit : voters.length - _offset;
      uint _block = _blockNumber > endBlock ? endBlock : _blockNumber;
      _voters = new address[](resultLength);
      _candidates = new uint8[](resultLength);
      _amounts = new uint[](resultLength);
      for(uint i = _offset; (i < voters.length) && (count < _limit); i++) {
        _voters[count] = voters[i];
        _candidates[count] = votes[voters[i]];
        _amounts[count] = msp.balanceOfAt(voters[i], _block);
        count++;
      }

      return(_voters, _candidates, _amounts);
    }
  }

  function getSummary() public constant returns (uint8[] _candidates, uint[] _summary) {
    uint _block = getBlockNumber() > endBlock ? endBlock : getBlockNumber();

     
    _candidates = new uint8[](candidates);
    for(uint8 c = 1; c <= candidates; c++) {
      _candidates[c - 1] = c;
    }

     
    _summary = new uint[](candidates);
    uint8 _candidateIndex;
    for(uint i = 0; i < voters.length; i++) {
      _candidateIndex = votes[voters[i]] - 1;
      _summary[_candidateIndex] = _summary[_candidateIndex] + min(msp.balanceOfAt(voters[i], _block), cap);
    }

    return (_candidates, _summary);
  }

   
   
   
   
  function claimTokens(address _token) public onlyOwner {
    if (_token == 0x0) {
      owner.transfer(this.balance);
      return;
    }

    ERC20Basic token = ERC20Basic(_token);
    uint balance = token.balanceOf(this);
    token.transfer(owner, balance);
    ClaimedTokens(_token, owner, balance);
  }

   
  function getBlockNumber() internal constant returns (uint) {
    return block.number;
  }

   
  function min(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }

  event Vote(address indexed _voter, uint indexed _candidate);
  event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
}