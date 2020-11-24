 

pragma solidity ^0.4.18;

 
 
 
 
contract ERC20Interface {
   
  function totalSupply() public constant returns (uint256 _totalSupply);

   
  function balanceOf(address _owner) public constant returns (uint256 balance);

   
  function transfer(address _to, uint256 _value) public returns (bool success);

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

   
  function approve(address _spender, uint256 _value) public returns (bool success);

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

   
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

   
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
 
 
library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}
contract Ace is ERC20Interface {
  using SafeMath for uint;
  uint256 public constant decimals = 8;

  uint256 public constant oneAce = 10**8;
  uint256 public constant oneEth = 10**18;

  string public constant symbol = "ACEX";
  string public constant name = "ACEX";

   
  bool public _selling = true;

   
  uint256 public _totalSupply = oneAce.mul(2).mul(10 ** 9);  

   
   
   
  uint256 public _originalBuyPrice = oneAce.mul(4318);  

   
  address public owner;

   
  mapping(address => uint256) private balances;

   
  mapping(address => mapping (address => uint256)) private allowed;

   
  mapping(address => bool) private approvedInvestorList;

   
  mapping(address => uint256) private deposit;

   
  uint256 public _icoPercent = 10;

   
  uint256 public _icoSupply = _totalSupply.mul(_icoPercent).div(100);

   
  uint256 public _minimumBuy = 3 * 10 ** 17;

   
  uint256 public _maximumBuy = 25 * oneEth;

   
  uint256 public totalTokenSold = 0;

   
  bool public tradable = false;

   
  uint256 public _maximumBurn = 0;

   
  event Burn(address indexed burner, uint256 value);
   
  event Sale(address indexed safer, bool value);
   
  event Tradable(address indexed safer, bool value);
   
  event ParamConfig(uint256 paramType, uint256 value);

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  modifier onSale() {
    require(_selling);
    _;
  }

   
  modifier validInvestor() {
    require(approvedInvestorList[msg.sender]);
    _;
  }

   
  modifier validValue(){
     
    require ( (msg.value >= _minimumBuy) &&
      ( (deposit[msg.sender] + msg.value) <= _maximumBuy) );
    _;
  }

   
  modifier validAddress {
    require(address(0) != msg.sender);
    _;
  }

   
  modifier isTradable(){
    require(tradable == true || msg.sender == owner);
    _;
  }

   
  function()
  public
  payable {
    buyAce();
  }

   
  function buyAce()
  public
  payable
  onSale
  validValue
  validInvestor {
     
     
    uint256 requestedUnits = msg.value.mul(_originalBuyPrice).div(oneEth);
    require(balances[owner] >= requestedUnits);
     
    balances[owner] = balances[owner].sub(requestedUnits);
    balances[msg.sender] = balances[owner].add(requestedUnits);
     
    deposit[msg.sender] = deposit[msg.sender].add(msg.value);
    totalTokenSold = totalTokenSold.add(requestedUnits);
     
    if (totalTokenSold >= _icoSupply){
      _selling = false;
    }

     
    Transfer(owner, msg.sender, requestedUnits);
    owner.transfer(msg.value);
  }

   
  function Ace()
  public {
    owner = msg.sender;
    setBuyPrice(_originalBuyPrice);
    balances[owner] = _totalSupply;
    Transfer(0x0, owner, _totalSupply);
  }

   
   
  function totalSupply()
  public
  constant
  returns (uint256) {
    return _totalSupply;
  }

   
  function turnOnSale() onlyOwner
  public {
    _selling = true;
    Sale(msg.sender, true);
  }

   
  function turnOffSale() onlyOwner
  public {
    _selling = false;
    Sale(msg.sender, false);
  }

  function turnOnTradable()
  public
  onlyOwner{
    tradable = true;
    Tradable(msg.sender, true);
  }

   
   
  function setIcoPercent(uint256 newIcoPercent)
  public
  onlyOwner {
    _icoPercent = newIcoPercent;
     
    _icoSupply = _totalSupply.mul(_icoPercent).div(100);
    ParamConfig(1, _icoPercent);
  }

   
   
  function setMinimumBuy(uint256 newMinimumBuy)
  public
  onlyOwner {
    _minimumBuy = newMinimumBuy;
    ParamConfig(2, _minimumBuy);
  }

   
   
  function setMaximumBuy(uint256 newMaximumBuy)
  public
  onlyOwner {
    _maximumBuy = newMaximumBuy;
    ParamConfig(3, _maximumBuy);
  }

   
   
  function setBuyPrice(uint256 newBuyPrice)
  onlyOwner
  public {
    require(newBuyPrice>0);

     
     
     
    _originalBuyPrice = newBuyPrice;

     
     
     
     
     
     
    _maximumBuy = oneAce.mul(90910).mul(oneEth).div(_originalBuyPrice) ;
    ParamConfig(4, _originalBuyPrice);
  }

   
   
   
  function balanceOf(address _addr)
  public
  constant
  returns (uint256) {
    return balances[_addr];
  }

   
   
  function isApprovedInvestor(address _addr)
  public
  constant
  returns (bool) {
    return approvedInvestorList[_addr];
  }

   
   
   
  function getDeposit(address _addr)
  public
  constant
  returns(uint256){
    return deposit[_addr];
  }

   
   
  function addInvestorList(address[] newInvestorList)
  onlyOwner
  public {
     
    require(newInvestorList.length <= 150);
    for (uint256 i = 0; i < newInvestorList.length; i++){
      approvedInvestorList[newInvestorList[i]] = true;
    }
  }

   
   
  function removeInvestorList(address[] investorList)
  onlyOwner
  public {
     
    require(investorList.length <= 150);
    for (uint256 i = 0; i < investorList.length; i++){
      approvedInvestorList[investorList[i]] = false;
    }
  }

   
   
   
   
  function transfer(address _to, uint256 _amount)
  public
  isTradable
  validAddress
  returns (bool) {
     
     
     
    require(balances[msg.sender] >= _amount);
    require(_amount >= 0);
    require(balances[_to] + _amount > balances[_to]);
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);

    Transfer(msg.sender, _to, _amount);
    return true;
  }

   
   
   
   
   
   
  function transferFrom(
    address _from,
    address _to,
    uint256 _amount
  )
  public
  isTradable
  validAddress
  returns (bool success) {
    require(balances[_from] >= _amount);
    require(allowed[_from][msg.sender] >= _amount);
    require(_amount > 0);
    require(balances[_to] + _amount > balances[_to]);
    require(_to != address(0));

     

    balances[_from] = balances[_from].sub(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);

    Transfer(_from, _to, _amount);
    return true;
  }

   
   
  function approve(address _spender, uint256 _amount)
  public
  isTradable
  validAddress
  returns (bool success) {
     
     
    require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
    require(_spender != address(0));
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

   
  function allowance(address _owner, address _spender)
  public
  constant
  returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
   
  function withdraw() onlyOwner
  public
  returns (bool) {
    return owner.send(this.balance);
  }

   
   
  function setMaximumBurn(uint256 newMaximumBurn)
  public
  onlyOwner {
    _maximumBurn = newMaximumBurn;
  }

   
   
  function burn(uint256 _value)
  public
  onlyOwner {
    require(_value > 0 && _value <= _maximumBurn);
    require(balances[msg.sender] >= _value);
    require(_totalSupply >= _value);
     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    _totalSupply = _totalSupply.sub(_value);
     
     
    Burn(msg.sender, _value);
  }
}