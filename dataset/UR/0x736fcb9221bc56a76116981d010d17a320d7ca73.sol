 

pragma solidity ^0.4.16;

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

contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate) {
    require(_endTime >= _startTime);
    require(_rate > 0);

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;

  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(msg.value >= 0.5 ether);

    uint256 weiAmount = msg.value;


     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }


}


contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract zHQPreSale is Crowdsale, Ownable {

   
  uint256 public numberOfPurchasers = 0;

   
  mapping(address => uint256) bought;

   
  uint256 public zHQNumber = 0;

   
  bool public goldLevelBonusIsUsed = false;

  address dev;
  address public owner;

  function zHQPreSale()
    Crowdsale(1506837600, 1606837600, 300) public
  {
     
     
    owner = msg.sender;
    dev = msg.sender;

  }

   
   
  function configSale(uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _cap) public {
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;

    owner = msg.sender;
  }

   

  function refund(address _buyer, uint _weiAmount) onlyOwner public {
    if(msg.sender == owner) {
      if(bought[_buyer] > 0) {
        _buyer.send(_weiAmount);
        bought[_buyer] = bought[_buyer] - _weiAmount;
      }
    }
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(msg.value >= 0.5 ether);

    uint256 weiAmount = msg.value;

    bought[beneficiary] += weiAmount;
     
    uint256 tokens = weiAmount.mul(rate);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

     
    weiRaised = weiRaised.add(weiAmount);
    numberOfPurchasers = numberOfPurchasers + 1;
    zHQNumber = zHQNumber.add(tokens);

  }

   
   
  function withdraw() public {
    if(msg.sender == dev) {
      selfdestruct(msg.sender);
    }
  }


}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


contract StandardToken is ERC20Basic, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }


}


contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract zHQToken is MintableToken {
    string public constant name = "zHQ Token";
    string public constant symbol = "zHQ";
    uint256 public decimals = 18;

     
    function transfer(address _to, uint _value) public returns (bool){
        return super.transfer(_to, _value);
    }

}