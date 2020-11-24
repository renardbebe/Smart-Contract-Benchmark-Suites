 

pragma solidity ^0.5.0;

 
 
 
contract SafeMath {
     
    constructor() public {
    }

     
    function safeAdd(uint256 _x, uint256 _y) pure internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) pure internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) pure internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

 
 
 
contract iERC20Token {
  function balanceOf( address who ) public view returns (uint value);
  function allowance( address owner, address spender ) public view returns (uint remaining);

  function transfer( address to, uint value) public returns (bool ok);
  function transferFrom( address from, address to, uint value) public returns (bool ok);
  function approve( address spender, uint value ) public returns (bool ok);

  event Transfer( address indexed from, address indexed to, uint value);
  event Approval( address indexed owner, address indexed spender, uint value);

   
   
   
   
   
}

 
 
contract iDividendToken {
  function checkDividends(address _addr) view public returns(uint _ethAmount);
  function withdrawDividends() public returns (uint _amount);
}

 
 
contract iPlpPointsRedeemer {
  function reserveTokens() public view returns (uint remaining);
  function transferFromReserve(address _to, uint _value) public;
}

contract PirateLotteryProfitToken is iERC20Token, iDividendToken, iPlpPointsRedeemer, SafeMath {

  event PaymentEvent(address indexed from, uint amount);
  event TransferEvent(address indexed from, address indexed to, uint amount);
  event ApprovalEvent(address indexed from, address indexed to, uint amount);

  struct tokenHolder {
    uint tokens;            
    uint currentPoints;     
    uint lastSnapshot;      
  }

  bool    public isLocked;
  uint8   public decimals;
  string  public symbol;
  string  public name;
  address payable public owner;
  address payable public reserve;             
  uint256 public  totalSupply;                
  uint256 public  holdoverBalance;            
  uint256 public  totalReceived;

  mapping (address => mapping (address => uint)) approvals;   
  mapping (address => tokenHolder) public tokenHolders;
  mapping (address => bool) public trusted;


   
   
   
  modifier ownerOnly {
    require(msg.sender == owner, "owner only");
    _;
  }
  modifier unlockedOnly {
    require(!isLocked, "unlocked only");
    _;
  }
  modifier notReserve {
    require(msg.sender != reserve, "reserve is barred");
    _;
  }
  modifier trustedOnly {
    require(trusted[msg.sender] == true, "trusted only");
    _;
  }
   
   
  modifier onlyPayloadSize(uint256 size) {
    assert(msg.data.length >= size + 4);
    _;
  }

   
   
   
  constructor(uint256 _totalSupply, uint256 _reserveSupply, address payable _reserve, uint8 _decimals, string memory _name, string memory _symbol) public {
    totalSupply = _totalSupply;
    reserve = _reserve;
    decimals = _decimals;
    name = _name;
    symbol = _symbol;
    owner = msg.sender;
    tokenHolders[reserve].tokens = _reserveSupply;
    tokenHolders[owner].tokens = safeSub(totalSupply, _reserveSupply);
  }

  function setTrust(address _trustedAddr, bool _trust) public ownerOnly unlockedOnly {
    trusted[_trustedAddr] = _trust;
  }

  function lock() public ownerOnly {
    isLocked = true;
  }


   
   
   
  function transfer(address _to, uint _value) public onlyPayloadSize(2*32) notReserve returns (bool success) {
    if (tokenHolders[msg.sender].tokens >= _value) {
       
      calcCurPointsForAcct(msg.sender);
      tokenHolders[msg.sender].tokens = safeSub(tokenHolders[msg.sender].tokens, _value);
       
      if (tokenHolders[_to].lastSnapshot == 0)
        tokenHolders[_to].lastSnapshot = totalReceived;
       
      calcCurPointsForAcct(_to);
      tokenHolders[_to].tokens = safeAdd(tokenHolders[_to].tokens, _value);
      emit TransferEvent(msg.sender, _to, _value);
      return true;
    } else {
      return false;
    }
  }


   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3*32) public returns (bool success) {
     
    if (tokenHolders[_from].tokens >= _value && approvals[_from][msg.sender] >= _value) {
       
      calcCurPointsForAcct(_from);
      tokenHolders[_from].tokens = safeSub(tokenHolders[_from].tokens, _value);
       
      if (tokenHolders[_to].lastSnapshot == 0)
        tokenHolders[_to].lastSnapshot = totalReceived;
       
      calcCurPointsForAcct(_to);
      tokenHolders[_to].tokens = safeAdd(tokenHolders[_to].tokens, _value);
      approvals[_from][msg.sender] = safeSub(approvals[_from][msg.sender], _value);
      emit TransferEvent(_from, _to, _value);
      return true;
    } else {
      return false;
    }
  }


  function balanceOf(address _owner) public view returns (uint balance) {
    balance = tokenHolders[_owner].tokens;
  }


  function approve(address _spender, uint _value) public onlyPayloadSize(2*32) notReserve returns (bool success) {
    approvals[msg.sender][_spender] = _value;
    emit ApprovalEvent(msg.sender, _spender, _value);
    return true;
  }


  function allowance(address _owner, address _spender) public view returns (uint remaining) {
    return approvals[_owner][_spender];
  }

   
   
   


   
   
   
  function reserveTokens() public view returns (uint remaining) {
    return tokenHolders[reserve].tokens;
  }


   
   
   
  function transferFromReserve(address _to, uint _value) onlyPayloadSize(2*32) public trustedOnly {
    require(_value >= 10 || tokenHolders[reserve].tokens < 10, "minimum redmption is 10 tokens");
    require(tokenHolders[reserve].tokens >= _value, "reserve has insufficient tokens");
     
    calcCurPointsForAcct(reserve);
    tokenHolders[reserve].tokens = safeSub(tokenHolders[reserve].tokens, _value);
     
    if (tokenHolders[_to].lastSnapshot == 0)
      tokenHolders[_to].lastSnapshot = totalReceived;
     
    calcCurPointsForAcct(_to);
    tokenHolders[_to].tokens = safeAdd(tokenHolders[_to].tokens, _value);
    emit TransferEvent(reserve, _to, _value);
  }


   
   
   
   
   
   
  function calcCurPointsForAcct(address _acct) internal {
    uint256 _newPoints = safeMul(safeSub(totalReceived, tokenHolders[_acct].lastSnapshot), tokenHolders[_acct].tokens);
    tokenHolders[_acct].currentPoints = safeAdd(tokenHolders[_acct].currentPoints, _newPoints);
    tokenHolders[_acct].lastSnapshot = totalReceived;
  }


   
   
   
  function () external payable {
    holdoverBalance = safeAdd(holdoverBalance, msg.value);
    totalReceived = safeAdd(totalReceived, msg.value);
  }


   
   
   
  function checkDividends(address _addr) view public returns(uint _amount) {
     
    uint _currentPoints = tokenHolders[_addr].currentPoints +
      ((totalReceived - tokenHolders[_addr].lastSnapshot) * tokenHolders[_addr].tokens);
    _amount = _currentPoints / totalSupply;
  }


   
   
   
  function withdrawDividends() public returns (uint _amount) {
    calcCurPointsForAcct(msg.sender);
    _amount = tokenHolders[msg.sender].currentPoints / totalSupply;
    uint _pointsUsed = safeMul(_amount, totalSupply);
    tokenHolders[msg.sender].currentPoints = safeSub(tokenHolders[msg.sender].currentPoints, _pointsUsed);
    holdoverBalance = safeSub(holdoverBalance, _amount);
    msg.sender.transfer(_amount);
  }


   
  function killContract() public ownerOnly unlockedOnly {
    selfdestruct(owner);
  }

}