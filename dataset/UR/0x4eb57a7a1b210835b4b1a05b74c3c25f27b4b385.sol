 

pragma solidity ^0.4.15;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
library SafeMath {

  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}
 
contract BasicToken is ERC20Basic {

  using SafeMath for uint256;

  modifier onlyPayloadSize(uint size) {
    assert(msg.data.length == size + 4);
    _;
  }

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract Ownable {

  address public owner;

   
  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

 

contract MintableToken is StandardToken, Ownable {

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;
  mapping (address => bool) public crowdsaleContracts;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier onlyCrowdsaleContract() {
    require(crowdsaleContracts[msg.sender]);
    _;
  }

  function addCrowdsaleContract(address _crowdsaleContract) onlyOwner {
    crowdsaleContracts[_crowdsaleContract] = true;
  }

  function deleteCrowdsaleContract(address _crowdsaleContract) onlyOwner {
    require(crowdsaleContracts[_crowdsaleContract]);
    delete crowdsaleContracts[_crowdsaleContract];
  }

  function mint(address _to, uint256 _amount) onlyCrowdsaleContract canMint returns (bool) {

    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(this, _to, _amount);
    return true;
  }

  function finishMinting() onlyCrowdsaleContract returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

}

contract ABHCoin is MintableToken {

  string public constant name = "ABH Coin";

  string public constant symbol = "ABH";

  uint32 public constant decimals = 18;

}



contract PrivatePlacement is Ownable {

  using SafeMath for uint;

  address public multisig;

  ABHCoin public token;

  uint256 public hardcap;
  uint public rate;
   

  bool refundAllowed;
  bool privatePlacementIsOn = true;
  bool PrivatePlacementFinished = false;
   
   
  mapping(address => uint) public balances;

  function PrivatePlacement(address _ABHCoinAddress, address _multisig, uint _rate) {
    multisig = _multisig;
    rate = _rate * 1 ether;
    hardcap = 120600000 * 1 ether;  
    token = ABHCoin(_ABHCoinAddress);
  }

  modifier isUnderHardCap() {
    require(token.totalSupply() <= hardcap);
    _;
  }

  function stopPrivatePlacement() onlyOwner {
    privatePlacementIsOn = false;
  }

  function restartPrivatePlacement() onlyOwner {
    require(!PrivatePlacementFinished);
    privatePlacementIsOn = true;
  }

  function finishPrivatePlacement() onlyOwner {
    require(!refundAllowed);
    multisig.transfer(this.balance);
     
    privatePlacementIsOn = false;
    PrivatePlacementFinished = true;
  }

  function alloweRefund() onlyOwner {
    refundAllowed = true;
  }

  function refund() public {
    require(refundAllowed);
    uint valueToReturn = balances[msg.sender];
    balances[msg.sender] = 0;
    msg.sender.transfer(valueToReturn);
  }

  function createTokens() isUnderHardCap payable {
    require(privatePlacementIsOn);
    uint valueWEI = msg.value;
    uint tokens = rate.mul(msg.value).div(1 ether);
    if (token.totalSupply() + tokens > hardcap){
      tokens = hardcap - token.totalSupply();
      valueWEI = tokens.mul(1 ether).div(rate);
      token.mint(msg.sender, tokens);
      uint change = msg.value - valueWEI;
      bool isSent = msg.sender.call.gas(3000000).value(change)();
    require(isSent);
    } else {
      token.mint(msg.sender, tokens);
    }
    balances[msg.sender] = balances[msg.sender].add(valueWEI);
  }
  
  function changeRate(uint _rate) onlyOwner {
     rate = _rate; 
  }

  function() external payable {
    createTokens();
  }

}