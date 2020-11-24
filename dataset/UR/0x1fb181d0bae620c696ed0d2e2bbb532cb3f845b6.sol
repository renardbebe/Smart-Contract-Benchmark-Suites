 

pragma solidity ^0.4.18;


contract AbstractTRMBalances {
    mapping(address => bool) public oldBalances;
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

contract TRM2TokenCoin is MintableToken {
    
    string public constant name = "Terraminer";
    
    string public constant symbol = "TRM2";
    
    uint32 public constant decimals = 8;
    
}



contract Crowdsale is Ownable, AbstractTRMBalances {
    event NewContribution(address indexed holder, uint256 tokenAmount, uint256 etherAmount);
    
    using SafeMath for uint;
    
    uint public ETHUSD;
    
    address multisig;
    
    address manager;

    TRM2TokenCoin public token = new TRM2TokenCoin();

    uint public startPreSale;
    uint public endPreSale;
    
    uint public startPreICO;
    uint public endPreICO;
    
    uint public startICO;
    uint public endICO;
    
    uint public startPostICO;
    uint public endPostICO;    
    
    uint hardcap;
    
    bool pause;
    
    AbstractTRMBalances oldBalancesP1;
    AbstractTRMBalances oldBalancesP2;   
    

    function Crowdsale() {
         
        multisig = 0xc2CDcE18deEcC1d5274D882aEd0FB082B813FFE8;
         
        manager = 0xf5c723B7Cc90eaA3bEec7B05D6bbeBCd9AFAA69a;
         
        ETHUSD = 72846;
        
         
        startPreSale = 1513728000;  
        endPreSale = 1514332800;  
        
        startPreICO = 1514332800;  
        endPreICO = 1517443200;  

        startICO = 1517443200;  
        endICO = 1519862400;  
        
        startPostICO = 1519862400;  
        endPostICO = 1522540800;  
		
         
        hardcap = 250000000 * 100000000;
         
        pause = false;
        
        oldBalancesP1 = AbstractTRMBalances(0xfcc6C3C19dcD67c282fFE27Ea79F1181693dA194);
        oldBalancesP2 = AbstractTRMBalances(0x4B7a1c77323c1e2ED6BcE44152b30092CAA9B1D3);
    }

    modifier saleIsOn() {
        require((now >= startPreSale && now < endPreSale) || (now >= startPreICO && now < endPreICO) || (now >= startICO && now < endICO) || (now >= startPostICO && now < endPostICO));
    	require(pause!=true);
    	_;
    }
	
    modifier isUnderHardCap() {
        require(token.totalSupply() < hardcap);
        _;
    }

    function finishMinting() public {
        require(msg.sender == manager);
        token.finishMinting();
        token.transferOwnership(manager);
    }

    function createTokens() isUnderHardCap saleIsOn payable {
        uint256 sum = msg.value;
        uint256 sumUSD = msg.value.mul(ETHUSD).div(100);

        
        require(sumUSD.div(1000000000000000000) > 100);
        
        uint256 totalSupply = token.totalSupply();
        
        uint256 numTokens = 0;
        
        uint256 tokenRest = 0;
        uint256 tokenPrice = 8 * 1000000000000000000;
        
        
         
         
        if(now >= startPreSale && now < endPreSale){
            
            require( (oldBalancesP1.oldBalances(msg.sender) == true)||(oldBalancesP2.oldBalances(msg.sender) == true) );
            
            
            tokenPrice = 35 * 100000000000000000; 

            numTokens = sumUSD.mul(100000000).div(tokenPrice);
            
        }
         
        
         
         
        if(now >= startPreICO && now < endPreICO){
            
            tokenPrice = 7 ether; 
            if(sum >= 151 ether){
               tokenPrice = 35 * 100000000000000000;
            } else if(sum >= 66 ether){
               tokenPrice = 40 * 100000000000000000;
            } else if(sum >= 10 ether){
               tokenPrice = 45 * 100000000000000000;
            } else if(sum >= 5 ether){
               tokenPrice = 50 * 100000000000000000;
            }
            
            numTokens = sumUSD.mul(100000000).div(tokenPrice);
            
        }
         
        
         
         
        if(now >= startICO && now < endICO){
            
            tokenPrice = 7 ether; 
            if(sum >= 151 ether){
               tokenPrice = 40 * 100000000000000000;
            } else if(sum >= 66 ether){
               tokenPrice = 50 * 100000000000000000;
            } else if(sum >= 10 ether){
               tokenPrice = 55 * 100000000000000000;
            } else if(sum >= 5 ether){
               tokenPrice = 60 * 100000000000000000;
            } 
            
            numTokens = sumUSD.mul(100000000).div(tokenPrice);
            
        }
         
        
         
         
        if(now >= startPostICO && now < endPostICO){
            
            tokenPrice = 8 ether; 
            if(sum >= 151 ether){
               tokenPrice = 45 * 100000000000000000;
            } else if(sum >= 66 ether){
               tokenPrice = 55 * 100000000000000000;
            } else if(sum >= 10 ether){
               tokenPrice = 60 * 100000000000000000;
            } else if(sum >= 5 ether){
               tokenPrice = 65 * 100000000000000000;
            } 
            
            numTokens = sumUSD.mul(100000000).div(tokenPrice);
            
        }
         
        numTokens = numTokens;
        require(msg.value > 0);
        require(numTokens > 0);
        
        tokenRest = hardcap.sub(totalSupply);
        require(tokenRest >= numTokens);
        
        token.mint(msg.sender, numTokens);
        multisig.transfer(msg.value);
        
        NewContribution(msg.sender, numTokens, msg.value);
        
        
    }

    function() external payable {
        createTokens();
    }

    function mint(address _to, uint _value) {
        require(msg.sender == manager);
        uint256 tokenRest = hardcap.sub(token.totalSupply());
        require(tokenRest > 0);
        if(_value > tokenRest)
            _value = tokenRest;
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