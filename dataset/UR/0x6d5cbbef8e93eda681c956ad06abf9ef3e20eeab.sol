 

pragma solidity 0.4.17;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
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

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }


  function approve(address _spender, uint256 _value) public returns (bool) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
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

  function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  function finishMinting() public onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract EndtimesToken is MintableToken {
  string public name = "Endtimes";
  string public symbol = "END";
  uint256 public decimals = 18;
}

contract EndtimesCrowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public ICOBeginsAt = 1512719999;  

   
  address public wallet = 0x00A3f365CDcb90fE3a7d0158Cf9D8738f3477764;

   
  uint256 public rate = 7000;

   
  uint256 public weiRaised;
  
    
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount, uint tokenRate);

  function EndtimesCrowdsale() public {
    token = createTokenContract();
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new EndtimesToken();
  }


   
  function () public payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(ICOBeginsAt < now);
    require(msg.value > 0);

    uint256 weiAmount = msg.value;

     
    uint currentRate = getCurrentRate();
    uint256 tokens = weiAmount.mul(currentRate);
    assert(tokens > 0);
    
     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens, currentRate);

    forwardFunds();
  }
  
  function getCurrentRate() public view
  returns (uint)
  {
      uint timeFrame = 1 weeks;
      
      if (ICOBeginsAt < now && now < ICOBeginsAt + 1 * timeFrame)
        return (2 * rate);            

      if (ICOBeginsAt + 1 * timeFrame < now && now < ICOBeginsAt + 2 * timeFrame) 
        return (175 * rate / 100);    

      if (ICOBeginsAt + 2 * timeFrame < now && now < ICOBeginsAt + 3 * timeFrame)
        return (150 * rate / 100);    

      if (ICOBeginsAt + 3 * timeFrame < now && now < ICOBeginsAt + 4 * timeFrame)
        return (140 * rate / 100);    

      if (ICOBeginsAt + 4 * timeFrame < now && now < ICOBeginsAt + 5 * timeFrame)
        return (125 * rate / 100);    

        return rate;                  
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}