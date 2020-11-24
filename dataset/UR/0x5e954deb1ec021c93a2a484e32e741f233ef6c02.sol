 

pragma solidity ^0.4.15;

 
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

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
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
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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

 

contract ConpayToken is StandardToken, Ownable {
  string public name = 'ConpayToken';
  string public symbol = 'COP';
  uint public decimals = 18;

  uint public constant crowdsaleEndTime = 1509580800;

  uint256 public startTime;
  uint256 public endTime;
  uint256 public tokensSupply;
  uint256 public rate;
  uint256 public perAddressCap;
  address public wallet;

  uint256 public tokensSold;

  bool public stopped; 
  event SaleStart();
  event SaleStop();

  modifier crowdsaleTransferLock() {
    require(now > crowdsaleEndTime);
    _;
  }

  function ConpayToken() {
    totalSupply = 2325000000 * (10**18);
    balances[msg.sender] = totalSupply;
    startSale(
      1503921600,  
      1505131200,  
      75000000 * (10**18),  
      45000,  
      0,  
      address(0x2D0a11e28b71788ae72A9beae8FAb937584B05Fd)  
    );
  }

  function() payable {
    buy(msg.sender);
  }

  function buy(address buyer) public payable {
    require(!stopped);
    require(buyer != 0x0);
    require(msg.value > 0);
    require(now >= startTime && now <= endTime);

    uint256 tokens = msg.value.mul(rate);
    assert(perAddressCap == 0 || balances[buyer].add(tokens) <= perAddressCap);
    assert(tokensSupply.sub(tokens) >= 0);

    balances[buyer] = balances[buyer].add(tokens);
    balances[owner] = balances[owner].sub(tokens);
    tokensSupply = tokensSupply.sub(tokens);
    tokensSold = tokensSold.add(tokens);

    assert(wallet.send(msg.value));
    Transfer(this, buyer, tokens);
  }

  function startSale(
    uint256 saleStartTime,
    uint256 saleEndTime,
    uint256 saletokensSupply,
    uint256 saleRate,
    uint256 salePerAddressCap,
    address saleWallet
  ) onlyOwner {
    startTime = saleStartTime;
    endTime = saleEndTime;
    tokensSupply = saletokensSupply;
    rate = saleRate;
    perAddressCap = salePerAddressCap;
    wallet = saleWallet;
    stopped = false;
    SaleStart();
  }

  function stopSale() onlyOwner {
    stopped = true;
    SaleStop();
  }

  function transfer(address _to, uint _value) crowdsaleTransferLock returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) crowdsaleTransferLock returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
}