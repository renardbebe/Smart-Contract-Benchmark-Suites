 

pragma solidity ^0.4.19;
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0){
        return 0;
    }
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {

  address public owner;

  address public newOwner;

  address public techSupport;

  address public newTechSupport;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyTechSupport() {
    require(msg.sender == techSupport);
    _;
  }

  function Ownable() public {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    if (msg.sender == newOwner) {
      owner = newOwner;
    }
  }

  function transferTechSupport (address _newSupport) public{
    require (msg.sender == owner || msg.sender == techSupport);
    newTechSupport = _newSupport;
  }

  function acceptSupport() public{
    if(msg.sender == newTechSupport){
      techSupport = newTechSupport;
    }
  }
}

 
contract VGCToken is Ownable {
  using SafeMath for uint;
   
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

   
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  string public constant symbol = "VGC";
  string public constant name = "VooGlueC";
  uint8 public constant decimals = 2;
  uint256 _totalSupply = 55000000*pow(10,decimals);

   
  address public owner;

   
  mapping(address => uint256) balances;

   
  mapping(address => mapping (address => uint256)) allowed;

   
  function pow(uint256 a, uint256 b) internal pure returns (uint256){  
    return (a**b);
  }

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   

  function balanceOf(address _address) public constant returns (uint256 balance) {
    return balances[_address];
  }

   
  function transfer(address _to, uint256 _amount) public returns (bool success) {
     
    require(this != _to);
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    Transfer(msg.sender,_to,_amount);
    return true;
  }

  address public crowdsaleContract;
  bool flag = false;
   
  function setCrowdsaleContract (address _address) public {
    require (!flag);
    crowdsaleContract = _address;
    reserveBalanceMap[_address] = true;
    flag = true;
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _amount
    )public returns (bool success) {
      require(this != _to);

      if (balances[_from] >= _amount
       && allowed[_from][msg.sender] >= _amount
       && _amount > 0
       && balances[_to] + _amount > balances[_to]) {
       balances[_from] -= _amount;
       allowed[_from][msg.sender] -= _amount;
       balances[_to] += _amount;
       Transfer(_from, _to, _amount);
    return true;
    } else {
    return false;
    }
  }

   
  function approve(address _spender, uint256 _amount)public returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

   
  function allowance(address _owner, address _spender)public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function VGCToken(address _addressOwner) public {
    owner = _addressOwner;
    techSupport = msg.sender;
    balances[this] = _totalSupply;
    teamBalanceMap[_addressOwner] = true;
    bountyBalanceMap[_addressOwner] = true;
    advisorsBalanceMap[_addressOwner] = true;
    referalFundBalanceMap[_addressOwner] = true;
    reserveBalanceMap[_addressOwner] = true;
  }
   
  function burnTokens(address _address) public{
    require(msg.sender == crowdsaleContract);
    balances[_address] = 0;
  }
   
  mapping (address => bool) public teamBalanceMap;
  mapping (address => bool) public bountyBalanceMap;
  mapping (address => bool) public advisorsBalanceMap;
  mapping (address => bool) public referalFundBalanceMap;
  mapping (address => bool) public reserveBalanceMap;


  uint private crowdsaleBalance = 36000000*pow(10,decimals);

  function getCrowdsaleBalance() public view returns(uint) {
    return crowdsaleBalance;
  }


  uint public teamBalance = 1000000*pow(10,decimals);
  uint public bountyBalance = 3000000*pow(10,decimals);
  uint public ownerBalance = 1000000*pow(10,decimals);
  uint public advisorsBalance = 1000000*pow(10,decimals);
  uint public referalFundBalance = 3000000*pow(10,decimals);
  uint public reserveBalance = 10000000*pow(10,decimals);

  function addTRA (address _address) public onlyOwner {
    teamBalanceMap[_address] = true;
  }

  function removeTRA (address _address) public onlyOwner {
    teamBalanceMap[_address] = false;
  }

  function addBRA (address _address) public onlyOwner {
    bountyBalanceMap[_address] = true;
  }

  function removeBRA (address _address) public onlyOwner {
    bountyBalanceMap[_address] = false;
  }

  function addARA (address _address) public onlyOwner {
    advisorsBalanceMap[_address] = true;
  }

  function removeARA (address _address) public onlyOwner {
    advisorsBalanceMap[_address] = false;
  }

  function addFRA (address _address) public onlyOwner {
    referalFundBalanceMap[_address] = true;
  }

  function removeFRA (address _address) public onlyOwner {
    referalFundBalanceMap[_address] = false;
  }

  function addRRA (address _address) public onlyOwner {
    reserveBalanceMap[_address] = true;
  }

  function removeRRA (address _address) public onlyOwner {
    reserveBalanceMap[_address] = false;
  }

  function sendTeamBalance (address _address, uint _value) public{
    require(teamBalanceMap[msg.sender]);
    teamBalance = teamBalance.sub(_value);
    balances[this] = balances[this].sub(_value);
    balances[_address] = balances[_address].add(_value);
    Transfer(this,_address, _value);
  }

  function sendBountyBalance (address _address, uint _value) public{
    require(bountyBalanceMap[msg.sender]);
    bountyBalance = bountyBalance.sub(_value);
    balances[this] = balances[this].sub(_value);
    balances[_address] = balances[_address].add(_value);
    Transfer(this,_address, _value);
  }

  function sendAdvisorsBalance (address _address, uint _value) public{
    require(advisorsBalanceMap[msg.sender]);
    advisorsBalance = advisorsBalance.sub(_value);
    balances[this] = balances[this].sub(_value);
    balances[_address] = balances[_address].add(_value);
    Transfer(this,_address, _value);
  }

  function sendReferallFundBalance (address _address, uint _value) public{
    require(referalFundBalanceMap[msg.sender]);
    referalFundBalance = referalFundBalance.sub(_value);
    balances[this] = balances[this].sub(_value);
    balances[_address] = balances[_address].add(_value);
    Transfer(this,_address, _value);
  }

  function sendReserveBalance (address _address, uint _value) public{
    require(reserveBalanceMap[msg.sender]);
    reserveBalance = reserveBalance.sub(_value);
    balances[this] = balances[this].sub(_value);
    balances[_address] = balances[_address].add(_value);
    Transfer(this,_address, _value);
  }

  function sendOwnersBalance (address _address, uint _value) public onlyOwner{
    ownerBalance = ownerBalance.sub(_value);
    balances[this] = balances[this].sub(_value);
    balances[_address] = balances[_address].add(_value);
    Transfer(this,_address, _value);
  }

  function sendCrowdsaleBalance (address _address, uint _value) public {
    require (msg.sender == crowdsaleContract);
    crowdsaleBalance = crowdsaleBalance.sub(_value);
    balances[this] = balances[this].sub(_value);
    balances[_address] = balances[_address].add(_value);
    Transfer(this,_address, _value);
  }

  bool private isReferralBalancesSended = false;

  function getRefBalSended () public view returns(bool){
      return isReferralBalancesSended;
  }


   
  function referralProgram (address[] _addresses, uint[] _values, uint _summary) public onlyTechSupport {
    require (_summary <= getCrowdsaleBalance());
    require(_addresses.length == _values.length);
    balances[this] = balances[this].sub(_summary);
    for (uint i = 0; i < _addresses.length; i++){
      balances[_addresses[i]] = balances[_addresses[i]].add(_values[i]);
      Transfer(this,_addresses[i],_values[i]);
    }
    isReferralBalancesSended = true;
  }

   
  function finishIco() public{
      require(msg.sender == crowdsaleContract);
      balances[this] = balances[this].sub(crowdsaleBalance);
      Transfer(this,0,crowdsaleBalance);
      _totalSupply = _totalSupply.sub(crowdsaleBalance);
      crowdsaleBalance = 0;
  }
}