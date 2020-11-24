 

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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
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

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract INV is Ownable, MintableToken {
  using SafeMath for uint256;    
  string public constant name = "Invest";
  string public constant symbol = "INV";
  uint32 public constant decimals = 18;

  address public addressTeam;  
  address public addressReserve;
  address public addressAdvisors;
  address public addressBounty;

  uint public summTeam;
  uint public summReserve;
  uint public summAdvisors;
  uint public summBounty;
  
  function INV() public {
    summTeam =     42000000 * 1 ether;
    summReserve =  27300000 * 1 ether;
    summAdvisors = 10500000 * 1 ether;
    summBounty =    4200000 * 1 ether;  

    addressTeam =     0xE347C064D8535b2f7D7C0f7bc5d6763125FC2Dc6;
    addressReserve =  0xB7C8163F7aAA51f1836F43d76d263e72529413ad;
    addressAdvisors = 0x461361e2b78F401db76Ea1FD4E0125bF3c56a222;
    addressBounty =   0x4060F9bf893fa563C272F5E4d4E691e84eF983CA;

     
    mint(addressTeam, summTeam);
    mint(addressReserve, summReserve);
    mint(addressAdvisors, summAdvisors);
    mint(addressBounty, summBounty);
  }
  function getTotalSupply() public constant returns(uint256){
      return totalSupply;
  }
}

 
contract Crowdsale is Ownable {
  using SafeMath for uint256;
   
  uint256 public totalTokens;
   
  uint256 public totalAllStage;
   
  INV public token;
   
     
  uint256 public startSeedStage;
  uint256 public startPrivateSaleStage;
  uint256 public startPreSaleStage;
  uint256 public startPublicSaleStage; 
     
  uint256 public endSeedStage;
  uint256 public endPrivateSaleStage;
  uint256 public endPreSaleStage;
  uint256 public endPublicSaleStage;    

  
   
   
  uint256 public maxSeedStage;
  uint256 public maxPrivateSaleStage;
  uint256 public maxPreSaleStage;
  uint256 public maxPublicSaleStage;   
   
  uint256 public totalSeedStage;
  uint256 public totalPrivateSaleStage;
  uint256 public totalPreSaleStage;
  uint256 public totalPublicSaleStage; 

   
  uint256 public rateSeedStage;
  uint256 public ratePrivateSaleStage;
  uint256 public ratePreSaleStage;
  uint256 public ratePublicSaleStage;   

   
  address public wallet;

   
  uint256 public minPayment; 

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  
  function Crowdsale() public {
    token = createTokenContract();
     
    totalTokens = 126000000 * 1 ether;
     
    minPayment = 10000000000000000;  
    
   
     
  startSeedStage = 1523275200;  
  startPrivateSaleStage = 1526385600;  
  startPreSaleStage = 1527336000;  
  startPublicSaleStage = 1534334400;  
     
  endSeedStage = 1525867200;  
  endPrivateSaleStage = 1526817600;  
  endPreSaleStage = 1531656000;  
  endPublicSaleStage = 1538308800;  

   
   
  maxSeedStage = 126000000 * 1 ether;
  maxPrivateSaleStage = 126000000 * 1 ether;
  maxPreSaleStage = 126000000 * 1 ether;
  maxPublicSaleStage = 126000000 * 1 ether;   

   
  rateSeedStage = 10000;
  ratePrivateSaleStage = 8820;
  ratePreSaleStage = 7644;
  ratePublicSaleStage = 4956;   

   
  wallet = 0x72b0FeF6BB61732e97AbA95D64B33f1345A7ABf7;  
  
  }

  function createTokenContract() internal returns (INV) {
    return new INV();
  }

  function () external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address beneficiary) public payable {
    uint256 tokens;
    uint256 weiAmount = msg.value;
    uint256 backAmount;
    require(beneficiary != address(0));
     
    require(weiAmount >= minPayment);
    require(totalAllStage < totalTokens);
     
    if (now >= startSeedStage && now < endSeedStage && totalSeedStage < maxSeedStage){
      tokens = weiAmount.mul(rateSeedStage);
      if (maxSeedStage.sub(totalSeedStage) < tokens){
        tokens = maxSeedStage.sub(totalSeedStage); 
        weiAmount = tokens.div(rateSeedStage);
        backAmount = msg.value.sub(weiAmount);
      }
      totalSeedStage = totalSeedStage.add(tokens);
    }
     
    if (now >= startPrivateSaleStage && now < endPrivateSaleStage && totalPrivateSaleStage < maxPrivateSaleStage){
      tokens = weiAmount.mul(ratePrivateSaleStage);
      if (maxPrivateSaleStage.sub(totalPrivateSaleStage) < tokens){
        tokens = maxPrivateSaleStage.sub(totalPrivateSaleStage); 
        weiAmount = tokens.div(ratePrivateSaleStage);
        backAmount = msg.value.sub(weiAmount);
      }
      totalPrivateSaleStage = totalPrivateSaleStage.add(tokens);
    }    
     
    if (now >= startPreSaleStage && now < endPreSaleStage && totalPreSaleStage < maxPreSaleStage){
      tokens = weiAmount.mul(ratePreSaleStage);
      if (maxPreSaleStage.sub(totalPreSaleStage) < tokens){
        tokens = maxPreSaleStage.sub(totalPreSaleStage); 
        weiAmount = tokens.div(ratePreSaleStage);
        backAmount = msg.value.sub(weiAmount);
      }
      totalPreSaleStage = totalPreSaleStage.add(tokens);
    }    
     
    if (now >= startPublicSaleStage && now < endPublicSaleStage && totalPublicSaleStage < maxPublicSaleStage){
      tokens = weiAmount.mul(ratePublicSaleStage);
      if (maxPublicSaleStage.sub(totalPublicSaleStage) < tokens){
        tokens = maxPublicSaleStage.sub(totalPublicSaleStage); 
        weiAmount = tokens.div(ratePublicSaleStage);
        backAmount = msg.value.sub(weiAmount);
      }
      totalPublicSaleStage = totalPublicSaleStage.add(tokens);
    }   
    
    require(tokens > 0);
    token.mint(beneficiary, tokens);
    totalAllStage = totalAllStage.add(tokens);
    wallet.transfer(weiAmount);
    
    if (backAmount > 0){
      msg.sender.transfer(backAmount);    
    }
    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }
}