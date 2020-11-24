 

pragma solidity ^0.4.19;

contract ERC223ReceivingContract {
  function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

contract ERC223Token {
  using SafeMath for uint256;

   
  string public name;
  bytes32 public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

   
  mapping(address => uint256) public balanceOf;
   
  mapping (address => mapping(address => uint256)) internal allowances;

   
  function transfer(address to, uint256 value, bytes data) public returns (bool) {
    require(balanceOf[msg.sender] >= value);
    uint256 codeLength;

    assembly {
       
      codeLength := extcodesize(to)
    }

    balanceOf[msg.sender] -= value;   
    balanceOf[to] = balanceOf[to].add(value);
    if (codeLength > 0) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
      receiver.tokenFallback(msg.sender, value, data);
    }
    ERC223Transfer(msg.sender, to, value, data);
    return true;
  }

   
   
  function transfer(address to, uint256 value) public returns (bool) {
    require(balanceOf[msg.sender] >= value);
    uint256 codeLength;
    bytes memory empty;

    assembly {
       
      codeLength := extcodesize(to)
    }

    balanceOf[msg.sender] -= value;   
    balanceOf[to] = balanceOf[to].add(value);
    if (codeLength > 0) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
      receiver.tokenFallback(msg.sender, value, empty);
    }
    ERC223Transfer(msg.sender, to, value, empty);
     
    Transfer(msg.sender, to, value);
    return true;
  }

   
   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_to != address(0));
    require(_value <= balanceOf[_from]);
    require(_value <= allowances[_from][msg.sender]);
    bytes memory empty;

    balanceOf[_from] = balanceOf[_from] -= _value;
    allowances[_from][msg.sender] -= _value;
    balanceOf[_to] = balanceOf[_to].add(_value);

     
     
    ERC223Transfer(_from, _to, _value, empty);
    Transfer(_from, _to, _value);
    return true;
  }

   
   
  function approve(address _spender, uint256 _value) public returns (bool success) {
    allowances[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowances[_owner][_spender];
  }

  event ERC223Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed from, address indexed spender, uint256 value);
}

contract ERC223MintableToken is ERC223Token {
  uint256 public circulatingSupply;
  function mint(address to, uint256 value) internal returns (bool) {
    uint256 codeLength;

    assembly {
       
      codeLength := extcodesize(to)
    }

    circulatingSupply += value;

    balanceOf[to] += value;   
    if (codeLength > 0) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
      bytes memory empty;
      receiver.tokenFallback(msg.sender, value, empty);
    }
    Mint(to, value);
    return true;
  }

  event Mint(address indexed to, uint256 value);
}

contract ERC20Token {
  function balanceOf(address owner) public view returns (uint256 balance);
  function transfer(address to, uint256 tokens) public returns (bool success);
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

}

contract BountyTokenAllocation is Ownable {

   
   
   

   
  uint256 public remainingBountyTokens;

   
  address[] public allocationAddressList;

   
   
   
   
   
   

   
  mapping (address => Types.StructBountyAllocation) public bountyOf;

   
  function BountyTokenAllocation(uint256 _remainingBountyTokens) Ownable() public {
    remainingBountyTokens = _remainingBountyTokens;
  }

   
  function proposeBountyTransfer(address _dest, uint256 _amount) public onlyOwner {
    require(_amount > 0);
    require(_amount <= remainingBountyTokens);
      
      
    require(bountyOf[_dest].proposalAddress == 0x0 || bountyOf[_dest].bountyState == Types.BountyState.Rejected);

    if (bountyOf[_dest].bountyState != Types.BountyState.Rejected) {
      allocationAddressList.push(_dest);
    }

    remainingBountyTokens = SafeMath.sub(remainingBountyTokens, _amount);
    bountyOf[_dest] = Types.StructBountyAllocation({
      amount: _amount,
      proposalAddress: msg.sender,
      bountyState: Types.BountyState.Proposed
    });
  }

   
  function approveBountyTransfer(address _approverAddress, address _dest) public onlyOwner returns (uint256) {
    require(bountyOf[_dest].bountyState == Types.BountyState.Proposed);
    require(bountyOf[_dest].proposalAddress != _approverAddress);

    bountyOf[_dest].bountyState = Types.BountyState.Approved;
    return bountyOf[_dest].amount;
  }

   
  function rejectBountyTransfer(address _dest) public onlyOwner {
    var tmp = bountyOf[_dest];
    require(tmp.bountyState == Types.BountyState.Proposed);

    bountyOf[_dest].bountyState = Types.BountyState.Rejected;
    remainingBountyTokens = remainingBountyTokens + bountyOf[_dest].amount;
  }

}

library SafeMath {
  function sub(uint256 a, uint256 b) pure internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  function min(uint256 a, uint256 b) pure internal returns (uint256) {
    if(a > b)
      return b;
    else
      return a;
  }
}

contract SignatoryOwnable {
  mapping (address => bool) public IS_SIGNATORY;

  function SignatoryOwnable(address signatory0, address signatory1, address signatory2) internal {
    IS_SIGNATORY[signatory0] = true;
    IS_SIGNATORY[signatory1] = true;
    IS_SIGNATORY[signatory2] = true;
  }

  modifier onlySignatory() {
    require(IS_SIGNATORY[msg.sender]);
    _;
  }
}

contract SignatoryPausable is SignatoryOwnable {
  bool public paused;   
  address public pauseProposer;   

  function SignatoryPausable(address signatory0, address signatory1, address signatory2)
      SignatoryOwnable(signatory0, signatory1, signatory2)
      internal {}

  modifier whenPaused(bool status) {
    require(paused == status);
    _;
  }

   
  function proposePauseChange(bool status) onlySignatory whenPaused(!status) public {
    require(pauseProposer == 0x0);   
    pauseProposer = msg.sender;
  }

   
  function approvePauseChange(bool status) onlySignatory whenPaused(!status) public {
    require(pauseProposer != 0x0);   
    require(pauseProposer != msg.sender);   
    pauseProposer = 0x0;
    paused = status;
    LogPause(paused);
  }

   
  function rejectPauseChange(bool status) onlySignatory whenPaused(!status) public {
    pauseProposer = 0x0;
  }

  event LogPause(bool status);
}

contract ExyToken is ERC223MintableToken, SignatoryPausable {
  using SafeMath for uint256;

  VestingAllocation private partnerTokensAllocation;
  VestingAllocation private companyTokensAllocation;
  BountyTokenAllocation private bountyTokensAllocation;

   
  uint256 private constant ICO_TOKENS = 14503506112248500000000000;
  address private constant ICO_TOKENS_ADDRESS = 0x97c967524d1eacAEb375d4269bE4171581a289C7;
   
  uint256 private constant SEED_TOKENS = 11700000000000000000000000;
  address private constant SEED_TOKENS_ADDRESS = 0x7C32c7649aA1335271aF00cd4280f87166474778;

   
  uint256 private constant COMPANY_TOKENS_PER_PERIOD = 727875169784680000000000;
  uint256 private constant COMPANY_PERIODS = 36;
  uint256 private constant MINUTES_IN_COMPANY_PERIOD = 60 * 24 * 365 / 12;

   
  uint256 private constant PARTNER_TOKENS_PER_PERIOD = 23821369192953200000000000;
  uint256 private constant PARTNER_PERIODS = 1;
  uint256 private constant MINUTES_IN_PARTNER_PERIOD = MINUTES_IN_COMPANY_PERIOD * 18;  

   
  uint256 private constant BOUNTY_TOKENS = 2382136919295320000000000;

   
  uint256 private constant MARKETING_COST_TOKENS = 794045639765106000000000;
  address private constant MARKETING_COST_ADDRESS = 0xF133ef3BE68128c9Af16F5aF8F8707f7A7A51452;

  uint256 public INIT_DATE;

  string public constant name = "Experty Token";
  bytes32 public constant symbol = "EXY";
  uint8 public constant decimals = 18;
  uint256 public constant totalSupply = (
    COMPANY_TOKENS_PER_PERIOD * COMPANY_PERIODS +
    PARTNER_TOKENS_PER_PERIOD * PARTNER_PERIODS +
    BOUNTY_TOKENS + MARKETING_COST_TOKENS +
    ICO_TOKENS + SEED_TOKENS);

   
  function ExyToken(address signatory0, address signatory1, address signatory2)
      SignatoryPausable(signatory0, signatory1, signatory2)
      public {

     
     
     
    INIT_DATE = block.timestamp;

    companyTokensAllocation = new VestingAllocation(
      COMPANY_TOKENS_PER_PERIOD,
      COMPANY_PERIODS,
      MINUTES_IN_COMPANY_PERIOD,
      INIT_DATE);

    partnerTokensAllocation = new VestingAllocation(
      PARTNER_TOKENS_PER_PERIOD,
      PARTNER_PERIODS,
      MINUTES_IN_PARTNER_PERIOD,
      INIT_DATE);

    bountyTokensAllocation = new BountyTokenAllocation(
      BOUNTY_TOKENS
    );

     
    mint(MARKETING_COST_ADDRESS, MARKETING_COST_TOKENS);

     
    mint(ICO_TOKENS_ADDRESS, ICO_TOKENS);
     
    mint(SEED_TOKENS_ADDRESS, SEED_TOKENS);
  }

   
  function erc20TokenTransfer(address _tokenAddr, address _dest) public onlySignatory {
    ERC20Token token = ERC20Token(_tokenAddr);
    token.transfer(_dest, token.balanceOf(address(this)));
  }

   
  function proposeCompanyAllocation(address _dest, uint256 _tokensPerPeriod) public onlySignatory onlyPayloadSize(2 * 32) {
    companyTokensAllocation.proposeAllocation(msg.sender, _dest, _tokensPerPeriod);
  }

   
  function approveCompanyAllocation(address _dest) public onlySignatory {
    companyTokensAllocation.approveAllocation(msg.sender, _dest);
  }

   
  function rejectCompanyAllocation(address _dest) public onlySignatory {
    companyTokensAllocation.rejectAllocation(_dest);
  }

   
  function getRemainingCompanyTokensAllocation() public view returns (uint256) {
    return companyTokensAllocation.remainingTokensPerPeriod();
  }

   
  function getCompanyAllocation(uint256 nr) public view returns (uint256, address, uint256, Types.AllocationState, address) {
    address recipientAddress = companyTokensAllocation.allocationAddressList(nr);
    var (tokensPerPeriod, proposalAddress, claimedPeriods, allocationState) = companyTokensAllocation.allocationOf(recipientAddress);
    return (tokensPerPeriod, proposalAddress, claimedPeriods, allocationState, recipientAddress);
  }

   
  function proposePartnerAllocation(address _dest, uint256 _tokensPerPeriod) public onlySignatory onlyPayloadSize(2 * 32) {
    partnerTokensAllocation.proposeAllocation(msg.sender, _dest, _tokensPerPeriod);
  }

   
  function approvePartnerAllocation(address _dest) public onlySignatory {
    partnerTokensAllocation.approveAllocation(msg.sender, _dest);
  }

   
  function rejectPartnerAllocation(address _dest) public onlySignatory {
    partnerTokensAllocation.rejectAllocation(_dest);
  }

   
  function getRemainingPartnerTokensAllocation() public view returns (uint256) {
    return partnerTokensAllocation.remainingTokensPerPeriod();
  }

   
  function getPartnerAllocation(uint256 nr) public view returns (uint256, address, uint256, Types.AllocationState, address) {
    address recipientAddress = partnerTokensAllocation.allocationAddressList(nr);
    var (tokensPerPeriod, proposalAddress, claimedPeriods, allocationState) = partnerTokensAllocation.allocationOf(recipientAddress);
    return (tokensPerPeriod, proposalAddress, claimedPeriods, allocationState, recipientAddress);
  }

  function proposeBountyTransfer(address _dest, uint256 _amount) public onlySignatory onlyPayloadSize(2 * 32) {
    bountyTokensAllocation.proposeBountyTransfer(_dest, _amount);
  }

   
  function approveBountyTransfer(address _dest) public onlySignatory {
    uint256 tokensToMint = bountyTokensAllocation.approveBountyTransfer(msg.sender, _dest);
    mint(_dest, tokensToMint);
  }

   
  function rejectBountyTransfer(address _dest) public onlySignatory {
    bountyTokensAllocation.rejectBountyTransfer(_dest);
  }

  function getBountyTransfers(uint256 nr) public view returns (uint256, address, Types.BountyState, address) {
    address recipientAddress = bountyTokensAllocation.allocationAddressList(nr);
    var (amount, proposalAddress, bountyState) = bountyTokensAllocation.bountyOf(recipientAddress);
    return (amount, proposalAddress, bountyState, recipientAddress);
  }

   
  function getRemainingBountyTokens() public view returns (uint256) {
    return bountyTokensAllocation.remainingBountyTokens();
  }

  function claimTokens() public {
    mint(
      msg.sender,
      partnerTokensAllocation.claimTokens(msg.sender) +
      companyTokensAllocation.claimTokens(msg.sender)
    );
  }

   
  function transfer(address to, uint256 value, bytes data) public whenPaused(false) returns (bool) {
    return super.transfer(to, value, data);
  }

  function transfer(address to, uint256 value) public whenPaused(false) returns (bool) {
    return super.transfer(to, value);
  }

  function mint(address to, uint256 value) internal whenPaused(false) returns (bool) {
    if (circulatingSupply.add(value) > totalSupply) {
      paused = true;   
      return false;
    }
    return super.mint(to, value);
  }

  modifier onlyPayloadSize(uint size) {
    assert(msg.data.length == size + 4);
    _;
  }

}

contract Types {

   
   
   
   
   
   
  enum AllocationState {
    Proposed,
    Approved,
    Rejected
  }

   
  struct StructVestingAllocation {
     
    uint256 tokensPerPeriod;
     
    address proposerAddress;
     
    uint256 claimedPeriods;
     
    AllocationState allocationState;
  }

  enum BountyState {
    Proposed,  
    Approved,  
    Rejected   
  }

  struct StructBountyAllocation {
     
    uint256 amount;
     
    address proposalAddress;
     
    BountyState bountyState;
  }
}

contract VestingAllocation is Ownable {

   

   
  address[] public allocationAddressList;

   
  uint256 public periods;
   
  uint256 public minutesInPeriod;
   
  uint256 public remainingTokensPerPeriod;
   
  uint256 public totalSupply;
   
  uint256 public initTimestamp;

   
   
  mapping (address => Types.StructVestingAllocation) public allocationOf;

   
  function VestingAllocation(uint256 _tokensPerPeriod, uint256 _periods, uint256 _minutesInPeriod, uint256 _initalTimestamp) Ownable() public {
    totalSupply = _tokensPerPeriod * _periods;
    periods = _periods;
    minutesInPeriod = _minutesInPeriod;
    remainingTokensPerPeriod = _tokensPerPeriod;
    initTimestamp = _initalTimestamp;
  }

   
  function proposeAllocation(address _proposerAddress, address _dest, uint256 _tokensPerPeriod) public onlyOwner {
    require(_tokensPerPeriod > 0);
    require(_tokensPerPeriod <= remainingTokensPerPeriod);
     
     
     
    require(allocationOf[_dest].proposerAddress == 0x0 || allocationOf[_dest].allocationState == Types.AllocationState.Rejected);

    if (allocationOf[_dest].allocationState != Types.AllocationState.Rejected) {
      allocationAddressList.push(_dest);
    }

    remainingTokensPerPeriod = remainingTokensPerPeriod - _tokensPerPeriod;
    allocationOf[_dest] = Types.StructVestingAllocation({
      tokensPerPeriod: _tokensPerPeriod,
      allocationState: Types.AllocationState.Proposed,
      proposerAddress: _proposerAddress,
      claimedPeriods: 0
    });
  }

   
  function approveAllocation(address _approverAddress, address _address) public onlyOwner {
    require(allocationOf[_address].allocationState == Types.AllocationState.Proposed);
    require(allocationOf[_address].proposerAddress != _approverAddress);
    allocationOf[_address].allocationState = Types.AllocationState.Approved;
  }

  
  function rejectAllocation(address _address) public onlyOwner {
    var tmp = allocationOf[_address];
    require(tmp.allocationState == Types.AllocationState.Proposed);
    allocationOf[_address].allocationState = Types.AllocationState.Rejected;
    remainingTokensPerPeriod = remainingTokensPerPeriod + tmp.tokensPerPeriod;
  }

  function claimTokens(address _address) public returns (uint256) {
    Types.StructVestingAllocation storage alloc = allocationOf[_address];
    if (alloc.allocationState == Types.AllocationState.Approved) {
      uint256 periodsElapsed = SafeMath.min((block.timestamp - initTimestamp) / (minutesInPeriod * 1 minutes), periods);
      uint256 tokens = (periodsElapsed - alloc.claimedPeriods) * alloc.tokensPerPeriod;
      alloc.claimedPeriods = periodsElapsed;
      return tokens;
    }
    return 0;
  }

}