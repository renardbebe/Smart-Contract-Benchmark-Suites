 

pragma solidity ^0.4.13;

 
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

contract ChangeCoin is MintableToken {
  string public name = "Change COIN";
  string public symbol = "CAG";
  uint256 public decimals = 18;

  bool public tradingStarted = false;

   
  modifier hasStartedTrading() {
    require(tradingStarted);
    _;
  }

   
  function startTrading() onlyOwner {
    tradingStarted = true;
  }


   
  function transfer(address _to, uint _value) hasStartedTrading returns (bool){
    super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint _value) hasStartedTrading returns (bool){
    super.transferFrom(_from, _to, _value);
  }
}

contract ChangeCoinCrowdsale is Ownable {
    using SafeMath for uint256;

     
    ChangeCoin public token;

     
    uint256 public startBlock;
    uint256 public endBlock;

     
    address public multiSigWallet;

     
    uint256 public rate;

     
    uint256 public weiRaised;

    uint256 public minContribution;

    uint256 public hardcap;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event MainSaleClosed();

    uint256 public raisedInPresale = 0.5 ether;

    function ChangeCoinCrowdsale() {
      startBlock = 4204545;
      endBlock = 4215000;
      rate = 500;
      multiSigWallet = 0xCe5574fF9d1fD16A411c09c488935F4fc613498c;
      token = ChangeCoin(0x9C3386DeBA43A24B3653F35926D9DA8CBABC3FEC);

      minContribution = 0 ether;
      hardcap = 2 ether;
       
       

      require(startBlock >= block.number);
      require(endBlock >= startBlock);
    }

     
    function bonusAmmount(uint256 tokens) internal returns(uint256) {
      uint256 bonus5 = tokens.div(20);
       
      if (block.number < startBlock.add(10160)) {  
        return tokens.add(bonus5.mul(4));
      } else if (block.number < startBlock.add(15240)) {
        return tokens.add(bonus5.mul(3));
      } else if (block.number < startBlock.add(20320)) {
        return tokens.add(bonus5);
      } else {
        return 0;
      }
    }

     
    function validPurchase() internal constant returns (bool) {
      uint256 current = block.number;
      bool withinPeriod = current >= startBlock && current <= endBlock;
      bool nonZeroPurchase = msg.value >= minContribution;
      bool withinCap = weiRaised.add(msg.value).add(raisedInPresale) <= hardcap;
      return withinPeriod && nonZeroPurchase && withinCap;
    }

     
    function hasEnded() public constant returns (bool) {
      bool timeLimitReached = block.number > endBlock;
      bool capReached = weiRaised.add(raisedInPresale) >= hardcap;
      return timeLimitReached || capReached;
    }

     
    function buyTokens(address beneficiary) payable {
      require(beneficiary != 0x0);
      require(validPurchase());

      uint256 weiAmount = msg.value;

       
      uint256 tokens = weiAmount.mul(rate);
      tokens = tokens + bonusAmmount(tokens);

       
      weiRaised = weiRaised.add(weiAmount);

      token.mint(beneficiary, tokens);
      TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
      multiSigWallet.transfer(msg.value);
    }

     
    function finishMinting() public onlyOwner {
      uint issuedTokenSupply = token.totalSupply();
      uint restrictedTokens = issuedTokenSupply.mul(60).div(40);
      token.mint(multiSigWallet, restrictedTokens);
      token.finishMinting();
      token.transferOwnership(owner);
      MainSaleClosed();
    }

     
    function () payable {
      buyTokens(msg.sender);
    }

  }