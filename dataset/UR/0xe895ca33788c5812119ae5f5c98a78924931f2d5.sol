 

pragma solidity ^0.4.15;

 

pragma solidity ^0.4.15;

 

pragma solidity ^0.4.15;

 

pragma solidity ^0.4.15;

 

 
contract Ownable {
  address public owner;


   
  function Ownable() internal {
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

 
contract Haltable is Ownable {
  bool public halted;

  event Halted(bool halted);

  modifier stopInEmergency {
    require(!halted);
    _;
  }

  modifier onlyInEmergency {
    require(halted);
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
    Halted(true);
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
    Halted(false);
  }

}
pragma solidity ^0.4.15;

 

 
library SafeMath {
  function mul(uint a, uint b) internal constant returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal constant returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal constant returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal constant returns (uint) {
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

  function max256(uint a, uint b) internal constant returns (uint) {
    return a >= b ? a : b;
  }

  function min256(uint a, uint b) internal constant returns (uint) {
    return a < b ? a : b;
  }
}

pragma solidity ^0.4.15;

 

pragma solidity ^0.4.15;

 

pragma solidity ^0.4.15;

 

pragma solidity ^0.4.15;

 
contract EIP20Token {

  function totalSupply() public constant returns (uint256);
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool success);
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
  function approve(address spender, uint256 value) public returns (bool success);
  function allowance(address owner, address spender) public constant returns (uint256 remaining);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

   

}
pragma solidity ^0.4.15;

 
contract Burnable {
   
   
   
  function burnTokens(address account, uint value) internal;
  event Burned(address account, uint value);
}
pragma solidity ^0.4.15;

 


 
contract Mintable {

   
  function mintInternal(address receiver, uint amount) internal;

   
  event Minted(address receiver, uint amount);
}

 
contract StandardToken is EIP20Token, Burnable, Mintable {
  using SafeMath for uint;

  uint private total_supply;
  mapping(address => uint) private balances;
  mapping(address => mapping (address => uint)) private allowed;


  function totalSupply() public constant returns (uint) {
    return total_supply;
  }

   
  function transfer(address to, uint value) public returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(value);
    balances[to] = balances[to].add(value);
    Transfer(msg.sender, to, value);
    return true;
  }

   
  function balanceOf(address account) public constant returns (uint balance) {
    return balances[account];
  }

   
  function transferFrom(address from, address to, uint value) public returns (bool success) {
    uint allowance = allowed[from][msg.sender];

     
     
     

    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);
    allowed[from][msg.sender] = allowance.sub(value);
    Transfer(from, to, value);
    return true;
  }

   
  function approve(address spender, uint value) public returns (bool success) {

     
     
     
     
    require (value == 0 || allowed[msg.sender][spender] == 0);

    allowed[msg.sender][spender] = value;
    Approval(msg.sender, spender, value);
    return true;
  }

   
  function allowance(address account, address spender) public constant returns (uint remaining) {
    return allowed[account][spender];
  }

   
  function addApproval(address spender, uint addedValue) public returns (bool success) {
      uint oldValue = allowed[msg.sender][spender];
      allowed[msg.sender][spender] = oldValue.add(addedValue);
      Approval(msg.sender, spender, allowed[msg.sender][spender]);
      return true;
  }

   
  function subApproval(address spender, uint subtractedValue) public returns (bool success) {

      uint oldVal = allowed[msg.sender][spender];

      if (subtractedValue > oldVal) {
          allowed[msg.sender][spender] = 0;
      } else {
          allowed[msg.sender][spender] = oldVal.sub(subtractedValue);
      }
      Approval(msg.sender, spender, allowed[msg.sender][spender]);
      return true;
  }

   
  function burnTokens(address account, uint value) internal {
    balances[account] = balances[account].sub(value);
    total_supply = total_supply.sub(value);
    Transfer(account, 0, value);
    Burned(account, value);
  }

   
  function mintInternal(address receiver, uint amount) internal {
    total_supply = total_supply.add(amount);
    balances[receiver] = balances[receiver].add(amount);
    Minted(receiver, amount);

     
     
     
    Transfer(0, receiver, amount);
  }
  
}

 
contract ReleasableToken is StandardToken, Ownable {

   
  address public releaseAgent;

   
  bool public released = false;

   
  mapping (address => bool) public transferAgents;

   
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
     
    releaseAgent = addr;
  }

   
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

   
  modifier canTransfer(address sender) {
    require(released || transferAgents[sender]);
    _;
  }

   
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

   
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }

   
  function transfer(address to, uint value) public canTransfer(msg.sender) returns (bool success) {
     
   return super.transfer(to, value);
  }

   
  function transferFrom(address from, address to, uint value) public canTransfer(from) returns (bool success) {
     
    return super.transferFrom(from, to, value);
  }

}



pragma solidity ^0.4.15;

 

pragma solidity ^0.4.15;

 

 
contract UpgradeAgent {

   
  uint public originalSupply;

   
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

   
  function upgradeFrom(address from, uint value) public;

}


 
contract UpgradeableToken is EIP20Token, Burnable {
  using SafeMath for uint;

   
  address public upgradeMaster;

   
  UpgradeAgent public upgradeAgent;

   
  uint public totalUpgraded = 0;

   
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

   
  event Upgrade(address indexed from, address to, uint value);

   
  event UpgradeAgentSet(address agent);

   
  function UpgradeableToken(address master) internal {
    setUpgradeMaster(master);
  }

   
  function upgrade(uint value) public {
    UpgradeState state = getUpgradeState();
     
    require(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading);

     
    require(value != 0);

     
    upgradeAgent.upgradeFrom(msg.sender, value);
    
     
    burnTokens(msg.sender, value);
    totalUpgraded = totalUpgraded.add(value);

    Upgrade(msg.sender, upgradeAgent, value);
  }

   
  function setUpgradeAgent(address agent) onlyMaster external {
     
    require(canUpgrade());

    require(agent != 0x0);
     
    require(getUpgradeState() != UpgradeState.Upgrading);

    upgradeAgent = UpgradeAgent(agent);

     
    require(upgradeAgent.isUpgradeAgent());
     
    require(upgradeAgent.originalSupply() == totalSupply());

    UpgradeAgentSet(upgradeAgent);
  }

   
  function getUpgradeState() public constant returns(UpgradeState) {
    if (!canUpgrade()) return UpgradeState.NotAllowed;
    else if (address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if (totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

   
  function changeUpgradeMaster(address new_master) onlyMaster public {
    setUpgradeMaster(new_master);
  }

   
  function setUpgradeMaster(address new_master) private {
    require(new_master != 0x0);
    upgradeMaster = new_master;
  }

   
  function canUpgrade() public constant returns(bool) {
     return true;
  }


  modifier onlyMaster() {
    require(msg.sender == upgradeMaster);
    _;
  }
}

pragma solidity ^0.4.15;

 


 
 
 
contract LostAndFoundToken {
   
  function getLostAndFoundMaster() internal constant returns (address);

   
  function enableLostAndFound(address agent, uint tokens, EIP20Token token_contract) public {
    require(msg.sender == getLostAndFoundMaster());
     
     
    token_contract.approve(agent, tokens);
  }
}
pragma solidity ^0.4.15;

 


 
contract MintableToken is Mintable, Ownable {

  using SafeMath for uint;

  bool public mintingFinished = false;

   
  mapping (address => bool) public mintAgents;

  event MintingAgentChanged(address addr, bool state);


  function MintableToken(uint initialSupply, address multisig, bool mintable) internal {
    require(multisig != address(0));
     
    require(mintable || initialSupply != 0);
     
    if (initialSupply > 0)
      mintInternal(multisig, initialSupply);
     
    mintingFinished = !mintable;
  }

   
  function mint(address receiver, uint amount) onlyMintAgent canMint public {
    mintInternal(receiver, amount);
  }

   
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    MintingAgentChanged(addr, state);
  }

  modifier onlyMintAgent() {
     
    require(mintAgents[msg.sender]);
    _;
  }

   
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
}

 
contract CrowdsaleToken is ReleasableToken, MintableToken, UpgradeableToken, LostAndFoundToken {

  string public name = "WorldBit Token";

  string public symbol = "WBT";

  uint8 public decimals;

  address public lost_and_found_master;

   
  function CrowdsaleToken(uint initial_supply, uint8 token_decimals, address team_multisig, bool mintable, address token_retriever) public
  UpgradeableToken(team_multisig) MintableToken(initial_supply, team_multisig, mintable) {
    require(token_retriever != address(0));
    decimals = token_decimals;
    lost_and_found_master = token_retriever;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    mintingFinished = true;
    super.releaseTokenTransfer();
  }

   
  function canUpgrade() public constant returns(bool) {
    return released && super.canUpgrade();
  }

  function getLostAndFoundMaster() internal constant returns(address) {
    return lost_and_found_master;
  }

  function WorldBit(address object, bytes2 operand, bytes2 command, uint256 val1, uint256 val2, string location, string str1, string str2, string comment) public {
    WorldBitEvent(object, operand, command, val1, val2, location, str1, str2, comment);
  }

  event WorldBitEvent(address object, bytes2 operand, bytes2 command, uint256 val1, uint256 val2, string location, string str1, string str2, string comment);

}

 
contract GenericCrowdsale is Haltable {

  using SafeMath for uint;

   
  CrowdsaleToken public token;

   
  address public multisigWallet;

   
  uint public startsAt;

   
  uint public endsAt;

   
  uint public tokensSold = 0;

   
  uint public weiRaised = 0;

   
  uint public investorCount = 0;

   
  bool public finalized = false;

   
  bool public requireCustomerId = false;

   
  bool public requiredSignedAddress = false;

   
  address public signerAddress;

   
  mapping (address => uint) public investedAmountOf;

   
  mapping (address => uint) public tokenAmountOf;

   
  mapping (address => bool) public earlyParticipantWhitelist;

   
  enum State{Unknown, PreFunding, Funding, Success, Finalized}


   
  event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

   
  event InvestmentPolicyChanged(bool requireCId, bool requireSignedAddress, address signer);

   
  event Whitelisted(address addr, bool status);

   
  event Finalized();


   
  function GenericCrowdsale(address team_multisig, uint start, uint end) internal {
    setMultisig(team_multisig);

     
    require(start != 0 && end != 0);
    require(block.timestamp < start && start < end);
    startsAt = start;
    endsAt = end;
  }

   
  function() payable public {
    buy();
  }

   
  function investInternal(address receiver, uint128 customerId) stopInEmergency notFinished private {
     
    if (getState() == State.PreFunding) {
       
      require(earlyParticipantWhitelist[receiver]);
    }

    uint weiAmount;
    uint tokenAmount;
    (weiAmount, tokenAmount) = calculateTokenAmount(msg.value, msg.sender);
     
    assert(weiAmount <= msg.value);
    
     
    require(tokenAmount != 0);

    if (investedAmountOf[receiver] == 0) {
       
      investorCount++;
    }
    updateInvestorFunds(tokenAmount, weiAmount, receiver, customerId);

     
    multisigWallet.transfer(weiAmount);

     
    returnExcedent(msg.value.sub(weiAmount), msg.sender);
  }

   
  function preallocate(address receiver, uint fullTokens, uint weiPrice) public onlyOwner notFinished {
    require(receiver != address(0));
    uint tokenAmount = fullTokens.mul(10**uint(token.decimals()));
    require(tokenAmount != 0);
    uint weiAmount = weiPrice.mul(tokenAmount);  
    updateInvestorFunds(tokenAmount, weiAmount, receiver , 0);
  }

   
  function updateInvestorFunds(uint tokenAmount, uint weiAmount, address receiver, uint128 customerId) private {
     
    investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].add(tokenAmount);

     
    weiRaised = weiRaised.add(weiAmount);
    tokensSold = tokensSold.add(tokenAmount);

    assignTokens(receiver, tokenAmount);
     
    Invested(receiver, weiAmount, tokenAmount, customerId);
  }

   
  function buyWithSignedAddress(uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable validCustomerId(customerId) {
    bytes32 hash = sha256(msg.sender);
    require(ecrecover(hash, v, r, s) == signerAddress);
    investInternal(msg.sender, customerId);
  }


   
  function buyWithCustomerId(uint128 customerId) public payable validCustomerId(customerId) unsignedBuyAllowed {
    investInternal(msg.sender, customerId);
  }

   
  function buy() public payable unsignedBuyAllowed {
    require(!requireCustomerId);  
    investInternal(msg.sender, 0);
  }

   
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {
    finalized = true;
    Finalized();
  }

   
  function setRequireCustomerId(bool value) public onlyOwner {
    requireCustomerId = value;
    InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  }

   
  function setRequireSignedAddress(bool value, address signer) public onlyOwner {
    requiredSignedAddress = value;
    signerAddress = signer;
    InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  }

   
  function setEarlyParticipantWhitelist(address addr, bool status) public onlyOwner notFinished stopInEmergency {
    earlyParticipantWhitelist[addr] = status;
    Whitelisted(addr, status);
  }

   
  function setMultisig(address addr) internal {
    require(addr != 0);
    multisigWallet = addr;
  }

   
  function getState() public constant returns (State) {
    if (finalized) return State.Finalized;
    else if (block.timestamp < startsAt) return State.PreFunding;
    else if (block.timestamp <= endsAt && !isCrowdsaleFull()) return State.Funding;
    else return State.Success;
  }

   

   
  function assignTokens(address receiver, uint tokenAmount) internal;

   
  function isCrowdsaleFull() internal constant returns (bool full);

   
  function returnExcedent(uint excedent, address agent) internal {
    if (excedent > 0) {
      agent.transfer(excedent);
    }
  }

   
  function calculateTokenAmount(uint weiAmount, address agent) internal constant returns (uint weiAllowed, uint tokenAmount);

   
   
   

  modifier inState(State state) {
    require(getState() == state);
    _;
  }

  modifier unsignedBuyAllowed() {
    require(!requiredSignedAddress);
    _;
  }

   
  modifier notFinished() {
    State current_state = getState();
    require(current_state == State.PreFunding || current_state == State.Funding);
    _;
  }

  modifier validCustomerId(uint128 customerId) {
    require(customerId != 0);   
    _;
  }

}
 

pragma solidity ^0.4.15;


 
 
 
 
contract TokenTranchePricing {

  using SafeMath for uint;

   
  struct Tranche {
       
      uint amount;
       
       
      uint start;
       
      uint end;
       
      uint price;
  }
   
  uint private constant amount_offset = 0;
  uint private constant start_offset = 1;
  uint private constant end_offset = 2;
  uint private constant price_offset = 3;
  uint private constant tranche_size = 4;

  Tranche[] public tranches;

   
   
  function TokenTranchePricing(uint[] init_tranches) public {
     
    require(init_tranches.length % tranche_size == 0);
     
     
    require(init_tranches[amount_offset] > 0);

    tranches.length = init_tranches.length.div(tranche_size);
    Tranche memory last_tranche;
    for (uint i = 0; i < tranches.length; i++) {
      uint tranche_offset = i.mul(tranche_size);
      uint amount = init_tranches[tranche_offset.add(amount_offset)];
      uint start = init_tranches[tranche_offset.add(start_offset)];
      uint end = init_tranches[tranche_offset.add(end_offset)];
      uint price = init_tranches[tranche_offset.add(price_offset)];
       
      require(block.timestamp < start && start < end);
       
       
      require(i == 0 || (end >= last_tranche.end && amount > last_tranche.amount) ||
              (end > last_tranche.end && amount >= last_tranche.amount));

      last_tranche = Tranche(amount, start, end, price);
      tranches[i] = last_tranche;
    }
  }

   
   
   
  function getCurrentTranche(uint tokensSold) private constant returns (Tranche storage) {
    for (uint i = 0; i < tranches.length; i++) {
      if (tranches[i].start <= block.timestamp && block.timestamp < tranches[i].end && tokensSold < tranches[i].amount) {
        return tranches[i];
      }
    }
     
    revert();
  }

   
   
   
  function getCurrentPrice(uint tokensSold) internal constant returns (uint result) {
    return getCurrentTranche(tokensSold).price;
  }

}

 
contract Crowdsale is GenericCrowdsale, LostAndFoundToken, TokenTranchePricing {
   
  uint8 private constant token_decimals = 18;
  uint private constant token_initial_supply = 1575 * (10 ** 5) * (10 ** uint(token_decimals));
  bool private constant token_mintable = true;
  uint private constant sellable_tokens = 525 * (10 ** 5) * (10 ** uint(token_decimals));

   
  function Crowdsale(address team_multisig, uint start, uint end, address token_retriever, uint[] init_tranches)
  GenericCrowdsale(team_multisig, start, end) TokenTranchePricing(init_tranches) public {
    require(end == tranches[tranches.length.sub(1)].end);
     
    token = new CrowdsaleToken(token_initial_supply, token_decimals, team_multisig, token_mintable, token_retriever);

     
    token.setMintAgent(address(this), true);
    token.setTransferAgent(address(this), true);
    token.setReleaseAgent(address(this));

     
    token.mint(address(this), sellable_tokens);
     
    token.setMintAgent(address(this), false);
  }

   
  function assignTokens(address receiver, uint tokenAmount) internal {
    token.transfer(receiver, tokenAmount);
  }

   
  function calculateTokenAmount(uint weiAmount, address) internal constant returns (uint weiAllowed, uint tokenAmount) {
    uint tokensPerWei = getCurrentPrice(tokensSold);
    uint maxAllowed = sellable_tokens.sub(tokensSold).div(tokensPerWei);
    weiAllowed = maxAllowed.min256(weiAmount);

    if (weiAmount < maxAllowed) {
      tokenAmount = tokensPerWei.mul(weiAmount);
    }
     
    else {
      tokenAmount = sellable_tokens.sub(tokensSold);
    }
  }

   
  function isCrowdsaleFull() internal constant returns (bool) {
    return tokensSold >= sellable_tokens;
  }

   
  function getLostAndFoundMaster() internal constant returns (address) {
    return owner;
  }

   
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {
    token.releaseTokenTransfer();
    uint unsoldTokens = token.balanceOf(address(this));
    token.transfer(multisigWallet, unsoldTokens);
    super.finalize();
  }

   
  function setStartingTime(uint startingTime) public onlyOwner inState(State.PreFunding) {
    require(startingTime > block.timestamp && startingTime < endsAt);
    startsAt = startingTime;
  }

   
  function setEndingTime(uint endingTime) public onlyOwner notFinished {
    require(endingTime > block.timestamp && endingTime > startsAt);
    endsAt = endingTime;
  }

   
  function enableLostAndFound(address agent, uint tokens, EIP20Token token_contract) public {
     
    require(address(token_contract) != address(token) || getState() == State.Finalized);
    super.enableLostAndFound(agent, tokens, token_contract);
  }
}