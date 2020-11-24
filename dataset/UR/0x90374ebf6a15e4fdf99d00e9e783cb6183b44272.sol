 

pragma solidity ^0.4.19;

 
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
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
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
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract GOToken is MintableToken {	
    
  string public constant name = "GO Token";
   
  string public constant symbol = "GO";
    
  uint32 public constant decimals = 18;

  mapping(address => bool) public locked;

  modifier notLocked() {
    require(msg.sender == owner || (mintingFinished && !locked[msg.sender]));
    _;
  }

  function lock(address to) public onlyOwner {
    require(!mintingFinished);
    locked[to] = true;
  }
  
  function unlock(address to) public onlyOwner {
    locked[to] = false;
  }

  function retrieveTokens(address anotherToken) public onlyOwner {
    ERC20 alienToken = ERC20(anotherToken);
    alienToken.transfer(owner, alienToken.balanceOf(this));
  }

  function transfer(address _to, uint256 _value) public notLocked returns (bool) {
    return super.transfer(_to, _value); 
  }

  function transferFrom(address from, address to, uint256 value) public notLocked returns (bool) {
    return super.transferFrom(from, to, value); 
  }

}

contract CommonCrowdsale is Ownable {

  using SafeMath for uint256;

  uint public constant PERCENT_RATE = 100;

  uint public price = 5000000000000000000000;

  uint public minInvestedLimit = 100000000000000000;

  uint public maxInvestedLimit = 20000000000000000000;

  uint public hardcap = 114000000000000000000000;

  uint public start = 1513342800;

  uint public invested;
  
  uint public extraTokensPercent;

  address public wallet;

  address public directMintAgent;

  address public bountyTokensWallet;

  address public foundersTokensWallet;

  uint public bountyTokensPercent = 5;

  uint public foundersTokensPercent = 15;
  
  uint public index;
 
  bool public isITOFinished;

  bool public extraTokensTransferred;
  
  address[] public tokenHolders;
  
  mapping (address => uint) public balances;
  
  struct Milestone {
    uint periodInDays;
    uint discount;
  }

  Milestone[] public milestones;

  GOToken public token = new GOToken();

  modifier onlyDirectMintAgentOrOwner() {
    require(directMintAgent == msg.sender || owner == msg.sender);
    _;
  }

  modifier saleIsOn(uint value) {
    require(value >= minInvestedLimit && now >= start && now < end() && invested < hardcap);
    _;
  }

  function tokenHoldersCount() public view returns(uint) {
    return tokenHolders.length;
  }

  function setDirectMintAgent(address newDirectMintAgent) public onlyOwner {
    directMintAgent = newDirectMintAgent;
  }

  function setHardcap(uint newHardcap) public onlyOwner { 
    hardcap = newHardcap;
  }
 
  function setStart(uint newStart) public onlyOwner { 
    start = newStart;
  }

  function setBountyTokensPercent(uint newBountyTokensPercent) public onlyOwner { 
    bountyTokensPercent = newBountyTokensPercent;
  }

  function setFoundersTokensPercent(uint newFoundersTokensPercent) public onlyOwner { 
    foundersTokensPercent = newFoundersTokensPercent;
  }

  function setBountyTokensWallet(address newBountyTokensWallet) public onlyOwner { 
    bountyTokensWallet = newBountyTokensWallet;
  }

  function setFoundersTokensWallet(address newFoundersTokensWallet) public onlyOwner { 
    foundersTokensWallet = newFoundersTokensWallet;
  }

  function setWallet(address newWallet) public onlyOwner { 
    wallet = newWallet;
  }

  function setPrice(uint newPrice) public onlyOwner {
    price = newPrice;
  }

  function setMaxInvestedLimit(uint naxMinInvestedLimit) public onlyOwner {
    maxInvestedLimit = naxMinInvestedLimit;
  }

  function setMinInvestedLimit(uint newMinInvestedLimit) public onlyOwner {
    minInvestedLimit = newMinInvestedLimit;
  }
 
  function milestonesCount() public view returns(uint) {
    return milestones.length;
  }

  function end() public constant returns(uint) {
    uint last = start;
    for (uint i = 0; i < milestones.length; i++) {
      Milestone storage milestone = milestones[i];
      last += milestone.periodInDays * 1 days;
    }
    return last;
  }

  function addMilestone(uint periodInDays, uint discount) public onlyOwner {
    milestones.push(Milestone(periodInDays, discount));
  }

  function setExtraTokensPercent(uint newExtraTokensPercent) public onlyOwner {
    extraTokensPercent = newExtraTokensPercent;
  }

  function payExtraTokens(uint count) public onlyOwner {
    require(isITOFinished && !extraTokensTransferred);
    if(extraTokensPercent == 0) {
      extraTokensTransferred = true;
    } else {
      for(uint i = 0; index < tokenHolders.length && i < count; i++) {
        address tokenHolder = tokenHolders[index];
        uint value = token.balanceOf(tokenHolder);
        if(value != 0) {
          uint targetValue = value.mul(extraTokensPercent).div(PERCENT_RATE);
          token.mint(this, targetValue);
          token.transfer(tokenHolder, targetValue);
        }
        index++;
      }
      if(index == tokenHolders.length) extraTokensTransferred = true;
    }
  }

  function finishITO() public onlyOwner {
    require(!isITOFinished);
      
    uint extendedTokensPercent = bountyTokensPercent.add(foundersTokensPercent);      
    uint totalSupply = token.totalSupply();
    uint allTokens = totalSupply.mul(PERCENT_RATE).div(PERCENT_RATE.sub(extendedTokensPercent));

    uint bountyTokens = allTokens.mul(bountyTokensPercent).div(PERCENT_RATE);
    mint(bountyTokensWallet, bountyTokens);

    uint foundersTokens = allTokens.mul(foundersTokensPercent).div(PERCENT_RATE);
    mint(foundersTokensWallet, foundersTokens);

    isITOFinished = true;
  }

  function tokenOperationsFinished() public onlyOwner {
    require(extraTokensTransferred);
    token.finishMinting();
    token.transferOwnership(owner);
  }

  function getDiscount() public view returns(uint) {
    uint prevTimeLimit = start;
    for (uint i = 0; i < milestones.length; i++) {
      Milestone storage milestone = milestones[i];
      prevTimeLimit += milestone.periodInDays * 1 days;
      if (now < prevTimeLimit)
        return milestone.discount;
    }
    revert();
  }

  function mint(address to, uint value) internal {
    if(token.balanceOf(to) == 0) tokenHolders.push(to);
    token.mint(to, value);
  }

  function calculateAndTransferTokens(address to, uint investedInWei) internal {
    invested = invested.add(msg.value);
    uint tokens = investedInWei.mul(price.mul(PERCENT_RATE)).div(PERCENT_RATE.sub(getDiscount())).div(1 ether);
    mint(to, tokens);
    balances[to] = balances[to].add(investedInWei);
    if(balances[to] >= maxInvestedLimit) token.lock(to);
  }

  function directMint(address to, uint investedWei) public onlyDirectMintAgentOrOwner saleIsOn(investedWei) {
    calculateAndTransferTokens(to, investedWei);
  }

  function createTokens() public payable saleIsOn(msg.value) {
    require(!isITOFinished);
    wallet.transfer(msg.value);
    calculateAndTransferTokens(msg.sender, msg.value);
  }

  function() external payable {
    createTokens();
  }

  function retrieveTokens(address anotherToken) public onlyOwner {
    ERC20 alienToken = ERC20(anotherToken);
    alienToken.transfer(wallet, alienToken.balanceOf(this));
  }
  
  function unlock(address to) public onlyOwner {
    token.unlock(to);
  }

}

contract GOTokenCrowdsale is CommonCrowdsale {

  function GOTokenCrowdsale() public {
    hardcap = 114000000000000000000000;
    price = 5000000000000000000000;
    start = 1513342800;
    wallet = 0x727436A7E7B836f3AB8d1caF475fAfEaeb25Ff27;
    bountyTokensWallet = 0x38e4f2A7625A391bFE59D6ac74b26D8556d6361E;
    foundersTokensWallet = 0x76A13d4F571107f363FF253E80706DAcE889aDED;
    addMilestone(7, 30);
    addMilestone(21, 15);
    addMilestone(56, 0);
  }

}