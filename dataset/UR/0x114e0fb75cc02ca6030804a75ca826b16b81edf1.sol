 

pragma solidity ^0.4.18;

 
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

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

 
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
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

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

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

 
contract BurnableToken is StandardToken {

   
  function burn(uint _value) public {
    require(_value > 0);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
  }

  event Burn(address indexed burner, uint indexed value);

}

contract Testcoin is BurnableToken {
    
  string public constant name = "Testcoin";
   
  string public constant symbol = "TSX";
    
  uint32 public constant decimals = 18;

  uint256 public INITIAL_SUPPLY = 100000000 * 1 ether;

  function Testcoin() public {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
    
}

contract Crowdsale is Ownable {
    
  using SafeMath for uint;
    
  address multisig;

  address restricted;

  Testcoin public token = new Testcoin();

  uint public start;
    
  uint public period;
  
  uint per_p_sale;
  
  uint per_sale;
  
  uint start_ico;
  
  uint sale_pre_sale;
  uint sale_1_week;
  uint sale_2_week;
  uint sale_3_week;
  uint sale_4_week;
  uint sale_5_week;

  uint rate;
  uint256 public presaleTokens;
  uint256 public restrictedTokens;
  uint256 public ini_supply;
  function Crowdsale() public {
    multisig = 0x476Bb28Bc6D0e9De04dB5E19912C392F9a76535d;
    restricted = 0x476Bb28Bc6D0e9De04dB5E19912C392F9a76535d;
    rate = 1000000000000000000000;
    start = 1513555200;  
    period = 5 * 365;
    per_p_sale = 5;
    per_sale = 365;
    sale_pre_sale = 50;
    sale_1_week = 40;
    sale_2_week = 30;
    sale_3_week = 20;
    sale_4_week = 10;
    sale_5_week = 5;
    ini_supply = 100000000 * 1 ether;
    presaleTokens    = 60000000 * 1 ether;
    restrictedTokens = 30000000 * 1 ether;
    
    token.transfer(restricted, restrictedTokens);
  }

  modifier saleIsOn() {
    require(now > start && now < start + period * 1 days);
    _;
  }

  function setStart(uint _start) public onlyOwner {
    start = _start;
  }
  
  function setPeriod(uint _period) public onlyOwner {
    period = _period;
  }  
  
  function setSail(uint _sale_pre_sale, uint _sale_1_week, uint _sale_2_week, uint _sale_3_week, uint _sale_4_week, uint _sale_5_week) public onlyOwner {
    sale_pre_sale = _sale_pre_sale;
    sale_1_week = _sale_1_week;
    sale_2_week = _sale_2_week;
    sale_3_week = _sale_3_week;
    sale_4_week = _sale_4_week;
    sale_5_week = _sale_5_week; 
  }    

  function createTokens() saleIsOn payable public {

    uint tokens = rate.mul(msg.value).div(1 ether);
    uint bonusTokens = 0;
    start_ico = start + per_p_sale * 1 days; 
    multisig.transfer(msg.value);    
    if(now < start_ico) 
    { 
     if(address(this).balance >= ini_supply.sub(restrictedTokens).sub(presaleTokens))
       {
         bonusTokens = tokens.div(100).mul(sale_pre_sale);
       } 
	  
    } else if(now >= start_ico && now < start_ico + (per_sale * 1 days)) {
      bonusTokens = tokens.div(100).mul(sale_1_week);
    } else if(now >= start_ico + (per_sale * 1 days) && now < start_ico + (per_sale * 1 days).mul(2)) {
      bonusTokens = tokens.div(100).mul(sale_2_week);
    } else if(now >= start_ico + (per_sale * 1 days).mul(2) && now < start_ico + (per_sale * 1 days).mul(3)) {
      bonusTokens = tokens.div(100).mul(sale_3_week);  
    } else if(now >= start_ico + (per_sale * 1 days).mul(3) && now < start_ico + (per_sale * 1 days).mul(4)) {
      bonusTokens = tokens.div(100).mul(sale_4_week);       
    } else if(now >= start_ico + (per_sale * 1 days).mul(4) && now < start_ico + (per_sale * 1 days).mul(5)) {
      bonusTokens = tokens.div(100).mul(sale_5_week);      
    }
    uint tokensWithBonus = tokens.add(bonusTokens);
    token.transfer(msg.sender, tokensWithBonus);
    
  }

  function() external payable {
    createTokens();
  }
    
}