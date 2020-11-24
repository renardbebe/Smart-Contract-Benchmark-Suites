 

pragma solidity ^0.4.19;

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

contract Token {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));      
    owner = newOwner;
  }
}

contract Pausable is Ownable {
    
  uint public constant startPreICO = 1521072000;  
  uint public constant endPreICO = startPreICO + 31 days;

  uint public constant startICOStage1 = 1526342400;  
  uint public constant endICOStage1 = startICOStage1 + 3 days;

  uint public constant startICOStage2 = 1526688000;  
  uint public constant endICOStage2 = startICOStage2 + 5 days;

  uint public constant startICOStage3 = 1527206400;  
  uint public constant endICOStage3 = endICOStage2 + 6 days;

  uint public constant startICOStage4 = 1527811200;  
  uint public constant endICOStage4 = startICOStage4 + 7 days;

  uint public constant startICOStage5 = 1528502400;
  uint public endICOStage5 = startICOStage5 + 11 days;

   
  modifier whenNotPaused() {
    require(now < startPreICO || now > endICOStage5);
    _;
  }

}

contract StandardToken is Token, Pausable {
  using SafeMath for uint256;
  mapping (address => mapping (address => uint256)) internal allowed;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0));
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

 
contract BurnableToken is StandardToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
      require(_value > 0);
      require(_value <= balances[msg.sender]);

      address burner = msg.sender;
      balances[burner] = balances[burner].sub(_value);
      totalSupply = totalSupply.sub(_value);
      Burn(burner, _value);
  }
}

contract MBEToken is BurnableToken {
  string public constant name = "MoBee";
  string public constant symbol = "MBE";
  uint8 public constant decimals = 18;
  address public tokenWallet;
  address public founderWallet;
  address public bountyWallet;
  address public multisig=0xa74246dc71c0849accd564976b3093b0b2a522c3;
  uint public currentFundrise = 0;
  uint public raisedEthers = 0;

  uint public constant INITIAL_SUPPLY = 20000000 ether;
  
  uint256 constant THOUSAND = 1000;
  uint256 constant TEN_THOUSAND = 10000;
  uint public tokenRate = THOUSAND.div(9);  
  uint public tokenRate30 = tokenRate.mul(100).div(70);  
  uint public tokenRate20 = tokenRate.mul(100).div(80);  
  uint public tokenRate15 = tokenRate.mul(100).div(85);  
  uint public tokenRate10 = tokenRate.mul(100).div(90);  
  uint public tokenRate5 = tokenRate.mul(100).div(95);  

   
  function MBEToken(address tokenOwner, address founder, address bounty) public {
    totalSupply = INITIAL_SUPPLY;
    balances[tokenOwner] += INITIAL_SUPPLY / 100 * 85;
    balances[founder] += INITIAL_SUPPLY / 100 * 10;
    balances[bounty] += INITIAL_SUPPLY / 100 * 5;
    tokenWallet = tokenOwner;
    founderWallet = founder;
    bountyWallet = bounty;
    Transfer(0x0, tokenOwner, balances[tokenOwner]);
    Transfer(0x0, founder, balances[founder]);
    Transfer(0x0, bounty, balances[bounty]);
  }
  
  function setupTokenRate(uint newTokenRate) public onlyOwner {
    tokenRate = newTokenRate;
    tokenRate30 = tokenRate.mul(100).div(70);  
    tokenRate20 = tokenRate.mul(100).div(80);  
    tokenRate15 = tokenRate.mul(100).div(85);  
    tokenRate10 = tokenRate.mul(100).div(90);  
    tokenRate5 = tokenRate.mul(100).div(95);  
  }
  
  function setupFinal(uint finalDate) public onlyOwner returns(bool) {
    endICOStage5 = finalDate;
    return true;
  }

  function sellManually(address _to, uint amount) public onlyOwner returns(bool) {
    uint tokens = calcTokens(amount);
    uint256 balance = balanceOf(owner);
    if (balance < tokens) {
      sendTokens(_to, balance);
    } else {
      sendTokens(_to, tokens);
    }
    return true;
  }

  function () payable public {
    if (!isTokenSale()) revert();
    buyTokens(msg.value);
  }
  
  function isTokenSale() public view returns (bool) {
    if (now >= startPreICO && now < endICOStage5) {
      return true;
    } else {
      return false;
    }
  }

  function buyTokens(uint amount) internal {
    uint tokens = calcTokens(amount);  
    safeSend(tokens);
  }
  
  function calcTokens(uint amount) public view returns(uint) {
    uint rate = extraRate(amount, tokenRate);
    uint tokens = amount.mul(rate);
    if (now >= startPreICO && now < endPreICO) {
      rate = extraRate(amount, tokenRate30);
      tokens = amount.mul(rate);
      return tokens;
    } else if (now >= startICOStage1 && now < endICOStage1) {
      rate = extraRate(amount, tokenRate20);
      tokens = amount.mul(rate);
      return tokens;
    } else if (now >= startICOStage2 && now < endICOStage2) {
      rate = extraRate(amount, tokenRate15);
      tokens = amount.mul(rate);
      return tokens;
    } else if (now >= startICOStage3 && now < endICOStage3) {
      rate = extraRate(amount, tokenRate10);
      tokens = amount.mul(rate);
      return tokens;
    } else if (now >= startICOStage4 && now < endICOStage4) {
      rate = extraRate(amount, tokenRate5);
      tokens = amount.mul(rate);
      return tokens;
    } else if (now >= startICOStage5 && now < endICOStage5) {
      return tokens;
    }
  }

  function extraRate(uint amount, uint rate) public pure returns (uint) {
    return ( ( rate * 10 ** 20 ) / ( 100 - extraDiscount(amount) ) ) / ( 10 ** 18 );
  }

  function extraDiscount(uint amount) public pure returns(uint) {
    if ( 3 ether <= amount && amount <= 5 ether ) {
      return 5;
    } else if ( 5 ether < amount && amount <= 10 ether ) {
      return 7;
    } else if ( 10 ether < amount && amount <= 20 ether ) {
      return 10;
    } else if ( 20 ether < amount ) {
      return 15;
    }
    return 0;
  }

  function safeSend(uint tokens) private {
    uint256 balance = balanceOf(owner);
    if (balance < tokens) {
      uint toReturn = tokenRate.mul(tokens.sub(balance));
      sendTokens(msg.sender, balance);
      msg.sender.transfer(toReturn);
      multisig.transfer(msg.value.sub(toReturn));
      raisedEthers += msg.value.sub(toReturn);
    } else {
      sendTokens(msg.sender, tokens);
      multisig.transfer(msg.value);
      raisedEthers += msg.value;
    }
  }

  function sendTokens(address _to, uint tokens) private {
    balances[owner] = balances[owner].sub(tokens);
    balances[_to] += tokens;
    Transfer(owner, _to, tokens);
    currentFundrise += tokens;
  }
}