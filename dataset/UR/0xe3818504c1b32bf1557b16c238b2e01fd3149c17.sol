 

pragma solidity ^0.4.11;


 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract TeamAllocation is Ownable {
  using SafeMath for uint;
   
  uint public unlockedAt;
  PillarToken plr;
  mapping (address => uint) allocations;
  uint tokensCreated = 0;
  uint constant public lockedTeamAllocationTokens = 16000000e18;
   
  address public teamStorageVault = 0x3f5D90D5Cc0652AAa40519114D007Bf119Afe1Cf;

  function TeamAllocation() {
    plr = PillarToken(msg.sender);
     
    uint nineMonths = 9 * 30 days;
    unlockedAt = now.add(nineMonths);
     
    allocations[teamStorageVault] = lockedTeamAllocationTokens;
  }

  function getTotalAllocation() returns (uint){
      return lockedTeamAllocationTokens;
  }

  function unlock() external payable {
    if (now < unlockedAt) throw;

    if (tokensCreated == 0) {
      tokensCreated = plr.balanceOf(this);
    }
     
    plr.transfer(teamStorageVault, tokensCreated);
  }
}

contract UnsoldAllocation is Ownable {
  using SafeMath for uint;
  uint unlockedAt;
  uint allocatedTokens;
  PillarToken plr;
  mapping (address => uint) allocations;

  uint tokensCreated = 0;

   

  function UnsoldAllocation(uint _lockTime, address _owner, uint _tokens) {
    if(_lockTime == 0) throw;

    if(_owner == address(0)) throw;

    plr = PillarToken(msg.sender);
    uint lockTime = _lockTime * 1 years;
    unlockedAt = now.add(lockTime);
    allocatedTokens = _tokens;
    allocations[_owner] = _tokens;
  }

  function getTotalAllocation()returns(uint){
      return allocatedTokens;
  }

  function unlock() external payable {
    if (now < unlockedAt) throw;

    if (tokensCreated == 0) {
      tokensCreated = plr.balanceOf(this);
    }

    var allocation = allocations[msg.sender];
    allocations[msg.sender] = 0;
    var toTransfer = (tokensCreated.mul(allocation)).div(allocatedTokens);
    plr.transfer(msg.sender, toTransfer);
  }
}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    if (paused) throw;
    _;
  }

   
  modifier whenPaused {
    if (!paused) throw;
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}


 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

   
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;


   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint _value) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

 
 
contract PillarToken is StandardToken, Ownable {

    using SafeMath for uint;
    string public constant name = "PILLAR";
    string public constant symbol = "PLR";
    uint public constant decimals = 18;

    TeamAllocation public teamAllocation;
    UnsoldAllocation public unsoldTokens;
    UnsoldAllocation public twentyThirtyAllocation;
    UnsoldAllocation public futureSaleAllocation;

    uint constant public minTokensForSale  = 32000000e18;

    uint constant public maxPresaleTokens             =  48000000e18;
    uint constant public totalAvailableForSale        = 528000000e18;
    uint constant public futureTokens                 = 120000000e18;
    uint constant public twentyThirtyTokens           =  80000000e18;
    uint constant public lockedTeamAllocationTokens   =  16000000e18;
    uint constant public unlockedTeamAllocationTokens =   8000000e18;

    address public unlockedTeamStorageVault = 0x4162Ad6EEc341e438eAbe85f52a941B078210819;
    address public twentyThirtyVault = 0xe72bA5c6F63Ddd395DF9582800E2821cE5a05D75;
    address public futureSaleVault = 0xf0231160Bd1a2a2D25aed2F11B8360EbF56F6153;
    address unsoldVault;

     
    uint constant coldStorageYears = 10;
    uint constant futureStorageYears = 3;

    uint totalPresale = 0;

     
    uint public constant tokenPrice  = 0.0005 ether;

     
    address public pillarTokenFactory;

    uint fundingStartBlock;
    uint fundingStopBlock;

     
    bool fundingMode;

     
    uint totalUsedTokens;

    event Refund(address indexed _from,uint256 _value);
    event Migrate(address indexed _from, address indexed _to, uint256 _value);
    event MoneyAddedForRefund(address _from, uint256 _value,uint256 _total);

    modifier isNotFundable() {
        if (fundingMode) throw;
        _;
    }

    modifier isFundable() {
        if (!fundingMode) throw;
        _;
    }

     
     
     
    function PillarToken(address _pillarTokenFactory, address _icedWallet) {
      if(_pillarTokenFactory == address(0)) throw;
      if(_icedWallet == address(0)) throw;

      pillarTokenFactory = _pillarTokenFactory;
      totalUsedTokens = 0;
      totalSupply = 800000000e18;
      unsoldVault = _icedWallet;

       
      balances[unlockedTeamStorageVault] = unlockedTeamAllocationTokens;

       
      futureSaleAllocation = new UnsoldAllocation(futureStorageYears,futureSaleVault,futureTokens);
      balances[address(futureSaleAllocation)] = futureTokens;

       
      twentyThirtyAllocation = new UnsoldAllocation(futureStorageYears,twentyThirtyVault,twentyThirtyTokens);
      balances[address(twentyThirtyAllocation)] = twentyThirtyTokens;

      fundingMode = false;
    }

     
     
    function() payable isFundable external {
      purchase();
    }

     
     
    function purchase() payable isFundable {
      if(block.number < fundingStartBlock) throw;
      if(block.number > fundingStopBlock) throw;
      if(totalUsedTokens >= totalAvailableForSale) throw;

      if (msg.value < tokenPrice) throw;

      uint numTokens = msg.value.div(tokenPrice);
      if(numTokens < 1) throw;
       
      pillarTokenFactory.transfer(msg.value);

      uint tokens = numTokens.mul(1e18);
      totalUsedTokens = totalUsedTokens.add(tokens);
      if (totalUsedTokens > totalAvailableForSale) throw;

      balances[msg.sender] = balances[msg.sender].add(tokens);

       
      Transfer(0, msg.sender, tokens);
    }

     
    function numberOfTokensLeft() constant returns (uint256) {
      uint tokensAvailableForSale = totalAvailableForSale.sub(totalUsedTokens);
      return tokensAvailableForSale;
    }

     
     
     
    function finalize() isFundable onlyOwner external {
      if (block.number <= fundingStopBlock) throw;

      if (totalUsedTokens < minTokensForSale) throw;

      if(unsoldVault == address(0)) throw;

       
      fundingMode = false;

       
      teamAllocation = new TeamAllocation();
      balances[address(teamAllocation)] = lockedTeamAllocationTokens;

       
      uint totalUnSold = numberOfTokensLeft();
      if(totalUnSold > 0) {
        unsoldTokens = new UnsoldAllocation(coldStorageYears,unsoldVault,totalUnSold);
        balances[address(unsoldTokens)] = totalUnSold;
      }

       
      pillarTokenFactory.transfer(this.balance);
    }

     
     
    function refund() isFundable external {
      if(block.number <= fundingStopBlock) throw;
      if(totalUsedTokens >= minTokensForSale) throw;

      uint plrValue = balances[msg.sender];
      if(plrValue == 0) throw;

      balances[msg.sender] = 0;

      uint ethValue = plrValue.mul(tokenPrice).div(1e18);
      msg.sender.transfer(ethValue);
      Refund(msg.sender, ethValue);
    }

     
     
    function allocateForRefund() external payable onlyOwner returns (uint){
       
      MoneyAddedForRefund(msg.sender,msg.value,this.balance);
      return this.balance;
    }

     
     
     
     
    function allocateTokens(address _to,uint _tokens) isNotFundable onlyOwner external {
      uint numOfTokens = _tokens.mul(1e18);
      totalPresale = totalPresale.add(numOfTokens);

      if(totalPresale > maxPresaleTokens) throw;

      balances[_to] = balances[_to].add(numOfTokens);
    }

     
     
    function unPauseTokenSale() onlyOwner isNotFundable external returns (bool){
      fundingMode = true;
      return fundingMode;
    }

     
     
    function pauseTokenSale() onlyOwner isFundable external returns (bool){
      fundingMode = false;
      return !fundingMode;
    }

     
     
     
     
    function startTokenSale(uint _fundingStartBlock, uint _fundingStopBlock) onlyOwner isNotFundable external returns (bool){
      if(_fundingStopBlock <= _fundingStartBlock) throw;

      fundingStartBlock = _fundingStartBlock;
      fundingStopBlock = _fundingStopBlock;
      fundingMode = true;
      return fundingMode;
    }

     
    function fundingStatus() external constant returns (bool){
      return fundingMode;
    }
}