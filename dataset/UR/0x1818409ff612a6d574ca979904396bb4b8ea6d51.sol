 

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
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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

 
contract Crowdsale is Ownable  {
  using SafeMath for uint256;

   
  MintableToken public token;
  

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(){
    

    token = createTokenContract();
    startTime = 1513466281;
    endTime = 15198624000;
    rate = 300;
    wallet = 0x0073A4857faA9745bc5123F50beEd3d170fb0979;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () payable {
    buyTokens(msg.sender);
  }
  
   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    address team = 0xF7a2D1f54416E7B39ec6E06FA2EF6d34ACa9f316;
    address bounty = 0xF7a2D1f54416E7B39ec6E06FA2EF6d34ACa9f316;
    address reserve = 0xF7a2D1f54416E7B39ec6E06FA2EF6d34ACa9f316;

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);
    uint256 bountyAmount = weiAmount.mul(50);
    uint256 teamAmount = weiAmount.mul(100);
    uint256 reserveAmount = weiAmount.mul(50);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    token.mint(bounty, bountyAmount);
    token.mint(team, teamAmount);
    token.mint(reserve, reserveAmount);

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }
  
  function mint(address _to, uint256 _amount) onlyOwner {
    uint256 mintAmount = _amount;
    token.mint(_to, mintAmount);  
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }


}

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale() {
    cap = 48275862100000000000000;
  }

   
   
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}

 
contract BARToken is MintableToken {

  string public constant name = "Generic Token";
  string public constant symbol = "GEN";
  uint8 public constant decimals = 18;

}

 
contract BARTokenSale is CappedCrowdsale {


  

  function BARTokenSale()
    CappedCrowdsale()
     
    Crowdsale()
  {
    
  }

  function createTokenContract() internal returns (MintableToken) {
    return new BARToken();
  }

}


contract NewTokenSale is BARTokenSale {


  address public contractAddress = 0x6720F9015a280f8EB210fED2FDEd9745C9248621;
  
  function NewTokenSale(){
    startTime = 1514836800;
    endTime = 1519862400;
    rate = 725;
    wallet = 0x98935ab01caA7a162892FdF9c6423de24b078a4c;
  }
  
  function changeOwner(address _to) public onlyOwner {
      BARTokenSale target = BARTokenSale(contractAddress);
      target.transferOwnership(_to);
  }
  
  function mint(address _to, uint256 _amount) public onlyOwner {
    BARTokenSale target = BARTokenSale(contractAddress);
    uint256 mintAmount = _amount;
    target.mint(_to, mintAmount);  
  }
  
  function changeRate(uint256 _newRate) public onlyOwner {
      rate = _newRate;
  }
  
   
  function () payable {
    buyTokens(msg.sender);
  }
  
   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());
    BARTokenSale target = BARTokenSale(contractAddress);

    address team = 0xBEC6663703B674EAB943CE2011df4c6cf095642E;
    address bounty = 0x124e46dAD16c1e9aB59D7412142a131d673cB68f;
    address reserve = 0x417063A7f0417Af1E6c5bE356014c0259d4dE4a1;

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);
    uint256 bountyAmount = weiAmount.mul(125);
    uint256 teamAmount = weiAmount.mul(250);
    uint256 reserveAmount = weiAmount.mul(150);

     
    weiRaised = weiRaised.add(weiAmount);

    target.mint(beneficiary, tokens);
    target.mint(bounty, bountyAmount);
    target.mint(team, teamAmount);
    target.mint(reserve, reserveAmount);

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }

  
    

}