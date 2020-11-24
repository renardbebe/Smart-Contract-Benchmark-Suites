 

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


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
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

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 
contract TokenDestructible is Ownable {

  function TokenDestructible() payable { } 

   
  function destroy(address[] tokens) onlyOwner {

     
    for (uint256 i = 0; i < tokens.length; i++) {
      ERC20Basic token = ERC20Basic(tokens[i]);
      uint256 balance = token.balanceOf(this);
      token.transfer(owner, balance);
    }

     
    selfdestruct(owner);
  }
}

 
 
contract JesusCoin is StandardToken, Ownable, TokenDestructible {

  string public name = "Jesus Coin";
  uint8 public decimals = 18;
  string public symbol = "JC";
  string public version = "0.2";

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


 
contract JesusCrowdsale is Ownable, Pausable, TokenDestructible {
  using SafeMath for uint256;

  JesusCoin public token;

  uint256 constant public START = 1507755600;  
  uint256 constant public END = 1513029600;  

  address public wallet = 0x61cc738Aef5D67ec7954B03871BA13dDe5B87DE8;
  address public bountyWallet = 0x03D299B68f8a0e47edd0609FB2B77FC0F2e4fa9e;

  uint256 public weiRaised;

  bool public bountyDistributed;

  function JesusCrowdsale() payable {
    token = new JesusCoin();
  }

   
   
  function getRate() constant returns (uint8) {
    if      (block.timestamp < START)            return 166;  
    else if (block.timestamp <= START +  6 days) return 162;  
    else if (block.timestamp <= START + 13 days) return 156;  
    else if (block.timestamp <= START + 20 days) return 150;  
    else if (block.timestamp <= START + 27 days) return 144;  
    else if (block.timestamp <= START + 34 days) return 138;  
    else if (block.timestamp <= START + 41 days) return 132;  
    else if (block.timestamp <= START + 48 days) return 126;  
    return 120;  
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address beneficiary) whenNotPaused() payable {
    require(beneficiary != 0x0);
    require(msg.value != 0);
    require(block.timestamp <= END);

    uint256 weiAmount = msg.value;
    weiRaised = weiRaised.add(weiAmount);

    uint256 tokens = weiAmount.mul(getRate()).div(10);
    token.mint(beneficiary, tokens);

    wallet.transfer(msg.value);
  }

  function distributeBounty() onlyOwner {
    require(!bountyDistributed);
    require(block.timestamp >= END);

     
    uint256 amount = weiRaised.div(100).mul(2);  
    token.mint(bountyWallet, amount);
    
    bountyDistributed = true;
  }
  
   
  function finishMinting() onlyOwner returns (bool) {
    require(bountyDistributed);
    require(block.timestamp >= END);

    return token.finishMinting();
  }

}