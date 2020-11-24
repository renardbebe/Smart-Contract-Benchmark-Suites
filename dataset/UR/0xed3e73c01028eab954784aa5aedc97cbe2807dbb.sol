 

 
 
 

pragma solidity ^0.4.18;

 
 
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

  

contract TipperToken {
    
  using SafeMath for uint256;
  
  string public name;
  string public symbol;
  uint256 public decimals;
  
  uint256 public totalSupply;
  
  uint256 private tprFund;
  uint256 private founderCoins;
  uint256 private icoReleaseTokens;
  
  uint256 private tprFundReleaseTime;
  uint256 private founderCoinsReleaseTime;
  
  bool private tprFundUnlocked;
  bool private founderCoinsUnlocked;
  
  address private tprFundDeposit;
  address private founderCoinsDeposit;

  mapping(address => uint256) internal balances;
  
  mapping (address => mapping (address => uint256)) internal allowed;
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Burn(address indexed burner, uint256 value);
  
  function TipperToken () public {
      
      name = "Tipper";
      symbol = "TIPR";
      decimals = 18;
      
      tprFund = 420000000 * (10**decimals);  
      founderCoins = 70000000 * (10**decimals);  
      icoReleaseTokens = 210000000 * (10**decimals);  
      
      totalSupply = tprFund + founderCoins + icoReleaseTokens;  
      
      balances[msg.sender] = icoReleaseTokens;
      
      Transfer(0, msg.sender, icoReleaseTokens);
      
      tprFundDeposit = 0x443174D48b39a18Aae6d7FfCa5c7712B6E94496b;  
      balances[tprFundDeposit] = 0;
      tprFundReleaseTime = 129600 * 1 minutes;  
      
      tprFundUnlocked = false;
      
      founderCoinsDeposit = 0x703D1d5DFf7D6079f44D6C56a2E455DaC7f2D8e6;  
      balances[founderCoinsDeposit] = 0;
      founderCoinsReleaseTime = 525600 * 1 minutes;  
      founderCoinsUnlocked = false;
  } 
  
  
   
   
  function releaseTprFund() public {
    require(now >= tprFundReleaseTime);  
    require(!tprFundUnlocked);  

    balances[tprFundDeposit] = tprFund;  
    
    Transfer(0, tprFundDeposit, tprFund);  

    tprFundUnlocked = true; 
    
  }
  
    
   
  
  function releaseFounderCoins() public {
    require(now >= founderCoinsReleaseTime);  
    require(!founderCoinsUnlocked);  

    balances[founderCoinsDeposit] = founderCoins;  
    
    Transfer(0, founderCoinsDeposit, founderCoins);  
    
    founderCoinsUnlocked = true;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    require(_value > 0);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_value > 0);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    require(_value>0);
    require(balances[msg.sender]>_value);
    allowed[msg.sender][_spender] = 0;
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

}