 

pragma solidity ^0.4.21;
 
 
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
 
contract AriumToken is BurnableToken {
   
  string public constant name = "Arium Token";
   
  string public constant symbol = "ARM";
   
  uint32 public constant decimals = 10;
 
  uint256 public INITIAL_SUPPLY = 400000000000000000;         
 
 
  function AriumToken() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
 
}
 
contract AriumCrowdsale is Ownable {
   
  using SafeMath for uint;
   
  address multisig;
 
  uint restrictedPercent;
 
  address restricted;
 
  AriumToken public token;
 
  uint start;
   
  uint preico;
 
  uint rate;
 
  uint icostart;
 
  uint ico;
  
  bool hardcap = false;
 
  function AriumCrowdsale(AriumToken _token) {
    token=_token;
    multisig = 0xA2Bfd3EE5ffdd78f7172edF03f31D1184eE627F3;           
    restricted = 0x8e7d40bb76BFf10DDe91D1757c4Ceb1A5385415B;         
    restrictedPercent = 13;              
    rate = 10000000000000;
    start = 1521849600;      
    preico = 30;         
    icostart= 1528588800;        
    ico = 67;            
   
   
  }
 
  modifier saleIsOn() {
    require((now > start && now < start + preico * 1 days) || (now > icostart && now < icostart + ico * 1 days ) );
    _;
  }
 
  function createTokens() saleIsOn payable {
    multisig.transfer(msg.value);
   
    uint tokens = rate.mul(msg.value).div(1 ether);
    uint bonusTokens = 0;
    uint BonusPerAmount = 0;
    if(msg.value >= 0.5 ether && msg.value < 1 ether){
        BonusPerAmount = tokens.div(20);                      
    } else if (msg.value >= 1 ether && msg.value < 5 ether){
        BonusPerAmount = tokens.div(10);                      
    } else if (msg.value >= 5 ether && msg.value < 10 ether){
        BonusPerAmount = tokens.mul(15).div(100);
    } else if (msg.value >= 10 ether && msg.value < 20 ether){
        BonusPerAmount = tokens.div(5);
    } else if (msg.value >= 20 ether){
        BonusPerAmount = tokens.div(4);
    }
    if(now < start + (preico * 1 days).div(3)) {
      bonusTokens = tokens.div(10).mul(3);
    } else if(now >= start + (preico * 1 days).div(3) && now < start + (preico * 1 days).div(3).mul(2)) {
      bonusTokens = tokens.div(5);
    } else if(now >= start + (preico * 1 days).div(3).mul(2) && now < start + (preico * 1 days)) {
      bonusTokens = tokens.div(10);
    }
    uint tokensWithBonus = tokens.add(BonusPerAmount);
    tokensWithBonus = tokensWithBonus.add(bonusTokens);
    token.transfer(msg.sender, tokensWithBonus);
    uint restrictedTokens = tokens.mul(restrictedPercent).div(100);
    token.transfer(restricted, restrictedTokens);
  }
 
    function ManualTransfer(address _to , uint ammount) saleIsOn onlyOwner payable{            
    token.transfer(_to, rate.div(1000).mul(ammount));                              
    }
    

    function BurnUnsoldToken(uint _value) onlyOwner payable{                                 
        token.burn(_value);
    }
    
    function setHardcupTrue() onlyOwner{
        hardcap = true;
    }
    function setHardcupFalse() onlyOwner{
        hardcap = false;
    }
 
  function() external payable {
    createTokens();
  }
   
}