 

pragma solidity ^0.4.18;

 

 
library SafeMath {
  function mul(uint256 a, uint256 b) pure internal  returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) pure internal  returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) pure internal  returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) pure internal  returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
 
pragma solidity ^0.4.8;

contract Token {
     
     
    uint256 public totalSupply;
    address public sale;
    bool public transfersAllowed;
    
     
     
    function balanceOf(address _owner) constant public returns (uint256 balance);

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 

 


 
 
contract Disbursement {

     
    address public owner;
    address public receiver;
    uint public disbursementPeriod;
    uint public startDate;
    uint public withdrawnTokens;
    Token public token;

     
    modifier isOwner() {
        if (msg.sender != owner)
             
            revert();
        _;
    }

    modifier isReceiver() {
        if (msg.sender != receiver)
             
            revert();
        _;
    }

    modifier isSetUp() {
        if (address(token) == 0)
             
            revert();
        _;
    }

     
     
     
     
     
    function Disbursement(address _receiver, uint _disbursementPeriod, uint _startDate)
        public
    {
        if (_receiver == 0 || _disbursementPeriod == 0)
             
            revert();
        owner = msg.sender;
        receiver = _receiver;
        disbursementPeriod = _disbursementPeriod;
        startDate = _startDate;
        if (startDate == 0)
            startDate = now;
    }

     
     
    function setup(Token _token)
        public
        isOwner
    {
        if (address(token) != 0 || address(_token) == 0)
             
            revert();
        token = _token;
    }

     
     
     
    function withdraw(address _to, uint256 _value)
        public
        isReceiver
        isSetUp
    {
        uint maxTokens = calcMaxWithdraw();
        if (_value > maxTokens)
            revert();
        withdrawnTokens = SafeMath.add(withdrawnTokens, _value);
        token.transfer(_to, _value);
    }

     
     
    function calcMaxWithdraw()
        public
        constant
        returns (uint)
    {
        uint maxTokens = SafeMath.mul(SafeMath.add(token.balanceOf(this), withdrawnTokens), SafeMath.sub(now,startDate)) / disbursementPeriod;
         
        if (withdrawnTokens >= maxTokens || startDate > now)
            return 0;
        if (SafeMath.sub(maxTokens, withdrawnTokens) > token.totalSupply())
            return token.totalSupply();
        return SafeMath.sub(maxTokens, withdrawnTokens);
    }
}

 

contract Owned {
  event OwnerAddition(address indexed owner);

  event OwnerRemoval(address indexed owner);

   
  mapping (address => bool) public isOwner;

  address[] public owners;

  address public operator;

  modifier onlyOwner {

    require(isOwner[msg.sender]);
    _;
  }

  modifier onlyOperator {
    require(msg.sender == operator);
    _;
  }

  function setOperator(address _operator) external onlyOwner {
    require(_operator != address(0));
    operator = _operator;
  }

  function removeOwner(address _owner) public onlyOwner {
    require(owners.length > 1);
    isOwner[_owner] = false;
    for (uint i = 0; i < owners.length - 1; i++) {
      if (owners[i] == _owner) {
        owners[i] = owners[SafeMath.sub(owners.length, 1)];
        break;
      }
    }
    owners.length = SafeMath.sub(owners.length, 1);
    OwnerRemoval(_owner);
  }

  function addOwner(address _owner) external onlyOwner {
    require(_owner != address(0));
    if(isOwner[_owner]) return;
    isOwner[_owner] = true;
    owners.push(_owner);
    OwnerAddition(_owner);
  }

  function setOwners(address[] _owners) internal {
    for (uint i = 0; i < _owners.length; i++) {
      require(_owners[i] != address(0));
      isOwner[_owners[i]] = true;
      OwnerAddition(_owners[i]);
    }
    owners = _owners;
  }

  function getOwners() public constant returns (address[])  {
    return owners;
  }

}

 

 
contract TokenLock is Owned {
  using SafeMath for uint;

  uint public shortLock;

  uint public longLock;

  uint public shortShare;

  address public levAddress;

  address public disbursement;

  uint public longTermTokens;

  modifier validAddress(address _address){
    require(_address != 0);
    _;
  }

  function TokenLock(address[] _owners, uint _shortLock, uint _longLock, uint _shortShare) public {
    require(_longLock > _shortLock);
    require(_shortLock > 0);
    require(_shortShare <= 100);
    setOwners(_owners);
    shortLock = block.timestamp.add(_shortLock);
    longLock = block.timestamp.add(_longLock);
    shortShare = _shortShare;
  }

  function setup(address _disbursement, address _levToken) public onlyOwner {
    require(_disbursement != address(0));
    require(_levToken != address(0));
    disbursement = _disbursement;
    levAddress = _levToken;
  }

  function transferShortTermTokens(address _wallet) public validAddress(_wallet) onlyOwner {
    require(now > shortLock);
    uint256 tokenBalance = Token(levAddress).balanceOf(disbursement);
     
    if (longTermTokens == 0) {
      longTermTokens = tokenBalance.mul(100 - shortShare).div(100);
    }
    require(tokenBalance > longTermTokens);
    uint256 amountToSend = tokenBalance.sub(longTermTokens);
    Disbursement(disbursement).withdraw(_wallet, amountToSend);
  }

  function transferLongTermTokens(address _wallet) public validAddress(_wallet) onlyOwner {
    require(now > longLock);
     
    uint256 tokenBalance = Token(levAddress).balanceOf(disbursement);

     
    Disbursement(disbursement).withdraw(_wallet, tokenBalance);
  }
}