 

pragma solidity ^0.4.18;


 
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


 
contract EtherGoToken is StandardToken, Ownable {

  string public name = "ETHERGO";           
  uint8 public decimals = 2;                         
  string public symbol = "XGO";                            
                                           
  uint256 public constant INITIAL_SUPPLY = 0.0000000095 ether;

   
  bool public transfersEnabled = false;

   
  function EtherGoToken() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }


    
    
   function enableTransfers(bool _transfersEnabled) onlyOwner {
      transfersEnabled = _transfersEnabled;
   }

  function transferFromContract(address _to, uint256 _value) onlyOwner returns (bool success) {
    return super.transfer(_to, _value);
  }

  function transfer(address _to, uint256 _value) returns (bool success) {
    require(transfersEnabled);
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    require(transfersEnabled);
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) returns (bool) {
      require(transfersEnabled);
      return super.approve(_spender, _value);
  }
}



 
contract DatCrowdPreSale is Ownable {
  using SafeMath for uint256;

   
  EtherGoToken public token;

   
  uint256 public startDate = 1523469083; 
  uint256 public endDate = 1555005081; 

   
  uint256 public minimumParticipationAmount = 300000000000000 wei;  

   
  uint256 public maximalParticipationAmount = 5000000000000000000 wei;  

   
  address wallet;

   
  uint256 rate = 150000;

   
  uint256 public weiRaised;

   
  bool public isFinalized = false;

   
  uint256 public cap = 5000000000000000000000 wei;  
 



  event Finalized();

    
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);



   
  event LogParticipation(address indexed sender, uint256 value, uint256 timestamp);


  
  function DatCrowdPreSale(address _wallet) {
    token = createTokenContract();
    wallet = _wallet;
  }


 
   
  function createTokenContract() internal returns (EtherGoToken) {
    return new EtherGoToken();
}

   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

     
    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(425);

     
    token.transferFromContract(beneficiary, 45500);

     
    weiRaised = weiRaised.add(weiAmount);

     
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

     
    forwardFunds();
  }

   
  function transferTokensManual(address beneficiary, uint256 amount) onlyOwner {
    require(beneficiary != 0x0);
    require(amount != 0);
    require(weiRaised.add(amount) <= cap);

     
    token.transferFromContract(beneficiary, amount);

     
    weiRaised = weiRaised.add(amount);

     
    TokenPurchase(wallet, beneficiary, 0, amount);

  }

    
    
   function enableTransfers(bool _transfersEnabled) onlyOwner {
      token.enableTransfers(_transfersEnabled);
   }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function finalize() onlyOwner {
    require(!isFinalized);
    Finalized();
    isFinalized = true;
  }


   
   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = startDate <= now && endDate >= now;
    bool nonZeroPurchase = msg.value != 0;
    bool minAmount = msg.value >= minimumParticipationAmount;
    bool withinCap = weiRaised.add(msg.value) <= cap;

    return withinPeriod && nonZeroPurchase && minAmount && !isFinalized && withinCap;
  }

     
  function capReached() public constant returns (bool) {
    return weiRaised >= cap;
  }

   
  function hasEnded() public constant returns (bool) {
    return isFinalized;
  }

}