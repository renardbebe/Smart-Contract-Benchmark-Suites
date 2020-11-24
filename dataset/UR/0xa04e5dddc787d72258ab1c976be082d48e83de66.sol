 

pragma solidity ^0.4.13;
 

 
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
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
}

contract RomanovEmpireTokenCoin is MintableToken {
    
    string public constant name = " Romanov Empire Imperium Token";
    
    string public constant symbol = "REI";
    
    uint32 public constant decimals = 0;
    
}


contract Crowdsale is Ownable {
    
    using SafeMath for uint;
    
    address multisig;
    
    address manager;

    uint restrictedPercent;

    address restricted;

    RomanovEmpireTokenCoin public token = new RomanovEmpireTokenCoin();

    uint start;

    uint preIcoEnd;
    
     

     
    
    uint preICOhardcap;

    uint public ETHUSD;
    
    uint public hardcapUSD;
    
    uint public collectedFunds;
    
    bool pause;

    function Crowdsale() {
         
        multisig = 0x1e129862b37Fe605Ef2099022F497caab7Db194c; 
         
        restricted = 0x1e129862b37Fe605Ef2099022F497caab7Db194c; 
         
        manager = msg.sender;
         
        restrictedPercent = 1200;
         
        ETHUSD = 70000;
         
        start = now;
	 
        preIcoEnd = 1546300800; 
         
         
         
        preICOhardcap = 42000;		
         
         
         
        hardcapUSD = 500000000;
         
        collectedFunds = 0;
         
        pause = false;
    }

    modifier saleIsOn() {
    	require(now > start && now < preIcoEnd);
    	require(pause!=true);
    	_;
    }
	
    modifier isUnderHardCap() {
        require(token.totalSupply() < preICOhardcap);
         
        require(collectedFunds < hardcapUSD);
        _;
    }

    function finishMinting() public {
        require(msg.sender == manager);
        
        uint issuedTokenSupply = token.totalSupply();
        uint restrictedTokens = issuedTokenSupply.mul(restrictedPercent).div(10000);
        token.mint(restricted, restrictedTokens);
        token.transferOwnership(restricted);
    }

    function createTokens() isUnderHardCap saleIsOn payable {

        require(msg.value > 0);
        
        uint256 totalSupply = token.totalSupply();
        
        uint256 numTokens = 0;
        uint256 summ1 = 1800000;
        uint256 summ2 = 3300000;
          
        uint256 price1 = 18000;
        uint256 price2 = 15000;
        uint256 price3 = 12000;
          
        uint256 usdValue = msg.value.mul(ETHUSD).div(1000000000000000000);
          
        uint256 spendMoney = 0; 
        
        uint256 tokenRest = 0;
        uint256 rest = 0;
        
          tokenRest = preICOhardcap.sub(totalSupply);
          require(tokenRest > 0);
            
          
          if(usdValue>summ2 && tokenRest > 200 ){
              numTokens = (usdValue.sub(summ2)).div(price3).add(200);
              if(numTokens > tokenRest)
                numTokens = tokenRest;              
              spendMoney = summ2.add((numTokens.sub(200)).mul(price3));
          }else if(usdValue>summ1 && tokenRest > 100 ) {
              numTokens = (usdValue.sub(summ1)).div(price2).add(100);
              if(numTokens > tokenRest)
                numTokens = tokenRest;
              spendMoney = summ1.add((numTokens.sub(100)).mul(price2));
          }else {
              numTokens = usdValue.div(price1);
              if(numTokens > tokenRest)
                numTokens = tokenRest;
              spendMoney = numTokens.mul(price1);
          }
    
          rest = (usdValue.sub(spendMoney)).mul(1000000000000000000).div(ETHUSD);
    
         msg.sender.transfer(rest);
         if(rest<msg.value){
            multisig.transfer(msg.value.sub(rest));
            collectedFunds = collectedFunds + msg.value.sub(rest).mul(ETHUSD).div(1000000000000000000); 
         }
         
          token.mint(msg.sender, numTokens);
          
        
        
    }

    function() external payable {
        createTokens();
    }

    function mint(address _to, uint _value) {
        require(msg.sender == manager);
        token.mint(_to, _value);   
    }    
    
    function setETHUSD( uint256 _newPrice ) {
        require(msg.sender == manager);
        ETHUSD = _newPrice;
    }    
    
    function setPause( bool _newPause ) {
        require(msg.sender == manager);
        pause = _newPause;
    } 
    
}