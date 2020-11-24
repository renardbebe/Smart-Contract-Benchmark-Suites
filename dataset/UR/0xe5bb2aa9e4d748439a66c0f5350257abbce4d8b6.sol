 

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
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
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
  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
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

 
contract MintableToken is StandardToken, Ownable{
  event Mint(address indexed to, uint256 amount);
  event MintFinished(); 
  uint256 public tokensMinted = 0; 
  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
     
    _amount = _amount * 1 ether;
    require(tokensMinted.add(_amount)<=totalSupply); 
    tokensMinted = tokensMinted.add(_amount);
     
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


 
contract WandToken is Ownable, MintableToken { 
   
  event TokenPreSaleTransfer(address indexed purchaser, address indexed beneficiary, uint256 amount);
  
   
  string public constant name = "Wand Token";
  string public constant symbol = "WAND";

   
  uint8 public constant decimals = 18;

   
  function WandToken(address _owner) {
       
      totalSupply = 75 * 10**24;  

       
      tokensMinted = tokensMinted.add(20400000 * (1 ether));
      balances[_owner] = 20400000 * 1 ether;
  }   

   
  function batchTransfers(address[] _accounts, uint256[] _tokens) onlyOwner public returns (bool) {
    require(_accounts.length > 0);
    require(_accounts.length == _tokens.length); 
    for (uint i = 0; i < _accounts.length; i++) {
      require(_accounts[i] != 0x0);
      require(_tokens[i] > 0); 
      transfer(_accounts[i], _tokens[i] * 1 ether);
      TokenPreSaleTransfer(msg.sender, _accounts[i], _tokens[i]); 
    }
    return true;   
  }
  
   
  function raiseInitialSupply(uint256 _supply) onlyOwner public returns (bool) {
      totalSupply = totalSupply.add(_supply * 1 ether);
      return true;
  }
}

 
contract WandCrowdsale is Ownable
{ 
    using SafeMath for uint256; 
     
     
    WandToken public token;  
     
    address public wallet;
     
    bool public crowdSaleOn = false;  

     
    uint256 public cap = 0;   
    uint256 public startTime;  
    uint256 public endTime;   
    uint256 public weiRaised = 0;   
    uint256 public tokensMinted = 0;  
    uint256[] public discountedRates ;  
    uint256[] public crowsaleSlots ;  
    
     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
     
    modifier activeCrowdSale() {
        require(crowdSaleOn);
        _;
    } 
    modifier inactiveCrowdSale() {
        require(!crowdSaleOn);
        _;
    } 
    
     
    function WandCrowdsale() { 
        wallet = msg.sender;  
        token = new WandToken(msg.sender);
    }
    
     
    function batchTransfers(address[] _accounts, uint256[] _tokens) onlyOwner public returns (bool) {
        require(_accounts.length > 0);
        require(_accounts.length == _tokens.length); 
        token.batchTransfers(_accounts,_tokens);
        return true;
    }
    
     
    function raiseInitialSupply(uint256 _supply) onlyOwner public returns (bool) {
        require(_supply > 0);
        token.raiseInitialSupply(_supply);
        return true;
    }
    
     
    function startCrowdsale(uint256 _startTime, uint256 _endTime,  uint256 _cap, uint256[] _crowsaleSlots, uint256[] _discountedRates) inactiveCrowdSale onlyOwner public returns (bool) {  
        require(_cap > 0);   
        require(_crowsaleSlots.length > 0); 
        require(_crowsaleSlots.length == _discountedRates.length);
        require(_startTime >= uint256(now));  
        require( _endTime > _startTime); 
        
         
        cap = _cap * 1 ether;   
        startTime = _startTime;
        endTime = _endTime;    
        crowdSaleOn = true;
        weiRaised = 0;
        tokensMinted = 0;
        discountedRates = _discountedRates;
        crowsaleSlots = _crowsaleSlots;
        return true;
    }  

     
    function endCrowdsale() activeCrowdSale onlyOwner public returns (bool) {
        endTime = now;  
        if(tokensMinted < cap){
            uint256 leftoverTokens = cap.sub(tokensMinted);
            require(tokensMinted.add(leftoverTokens) <= cap);
            tokensMinted = tokensMinted.add(leftoverTokens);
            token.mint(owner, leftoverTokens.div(1 ether)); 
        }
        crowdSaleOn = false;
        return true;
    }   
    
     
    function findDiscount() constant private returns (uint256 _discountedRate) {
        uint256 elapsedTime = now.sub(startTime);
        for(uint i=0; i<crowsaleSlots.length; i++){
            if(elapsedTime >= crowsaleSlots[i]) {
                elapsedTime = elapsedTime.sub(crowsaleSlots[i]);
            }
            else {
                _discountedRate = discountedRates[i];
                break;
            }
        } 
    }
    
     
    function () payable {
        buyTokens(msg.sender);
    }
  
     
    function buyTokens(address beneficiary) activeCrowdSale public payable {
        require(beneficiary != 0x0); 
        require(now >= startTime);
        require(now <= endTime);
        require(msg.value != 0);   
        
         
        uint256 weiAmount = msg.value; 
        weiRaised = weiRaised.add(weiAmount); 
        
         
        var currentRate = findDiscount();
         
        uint256 rate = uint256(1 * 1 ether).div(currentRate); 
        require(rate > 0);
         
         
        uint256 numTokens = weiAmount.div(rate); 
        require(numTokens > 0); 
        require(tokensMinted.add(numTokens.mul(1 ether)) <= cap);
        tokensMinted = tokensMinted.add(numTokens.mul(1 ether));
        
         
        token.mint(beneficiary, numTokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, numTokens); 
         
        wallet.transfer(weiAmount);
    } 
}