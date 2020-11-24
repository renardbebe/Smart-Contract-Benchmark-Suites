 

pragma solidity ^0.4.13;

contract AllocationAddressList {

  address[] public allocationAddressList;
}

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

   
  function transfer(address to, uint256 value, bytes data) public returns (bool) {
     
     
    uint256 codeLength;

    assembly {
       
      codeLength := extcodesize(to)
    }

    balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
    balanceOf[to] = balanceOf[to].add(value);
    if (codeLength > 0) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
      receiver.tokenFallback(msg.sender, value, data);
    }
    Transfer(msg.sender, to, value, data);
    return true;
  }

   
   
  function transfer(address to, uint256 value) public returns (bool) {
    uint256 codeLength;
    bytes memory empty;

    assembly {
       
      codeLength := extcodesize(to)
    }

    balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
    balanceOf[to] = balanceOf[to].add(value);
    if (codeLength > 0) {
      ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
      receiver.tokenFallback(msg.sender, value, empty);
    }
    Transfer(msg.sender, to, value, empty);
     
    Transfer(msg.sender, to, value);
    return true;
  }

  event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC223MintableToken is ERC223Token {
  using SafeMath for uint256;
  uint256 public circulatingSupply;
  function mint(address to, uint256 value) internal returns (bool) {
    uint256 codeLength;

    assembly {
       
      codeLength := extcodesize(to)
    }

    circulatingSupply += value;

    balanceOf[to] = balanceOf[to].add(value);
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

contract TestToken is ERC223MintableToken {
  mapping (address => bool) public IS_SIGNATURER;

  VestingAllocation private partnerTokensAllocation;
  VestingAllocation private companyTokensAllocation;
  BountyTokenAllocation private bountyTokensAllocation;

    
  uint256 constant ICO_TOKENS = 25346500000000000000000000;
  address constant ICO_TOKENS_ADDRESS = 0xCE1182147FD13A59E4Ca114CAa1cD58719e09F67;
   
  uint256 constant SEED_TOKENS = 25346500000000000000000000;
  address constant SEED_TOKENS_ADDRESS = 0x8746177Ff2575E826f6f73A1f90351e0FD0A6649;

   
  uint256 constant COMPANY_TOKENS_PER_PERIOD = 704069444444444000000000;
  uint256 constant COMPANY_PERIODS = 36;
  uint256 constant MINUTES_IN_COMPANY_PERIOD = 10;  

   
  uint256 constant PARTNER_TOKENS_PER_PERIOD = 23042272727272700000000000;
  uint256 constant PARTNER_PERIODS = 1;
  uint256 constant MINUTES_IN_PARTNER_PERIOD = 60 * 2;  

   
  uint256 constant BOUNTY_TOKENS = 2304227272727270000000000;

   
  uint256 constant MARKETING_COST_TOKENS = 768075757575758000000000;
  address constant MARKETING_COST_ADDRESS = 0x54a0AB12710fad2a24CB391406c234855C835340;

  uint256 public INIT_DATE;

  string public constant name = "Test Token";
  bytes32 public constant symbol = "TST";
  uint8 public constant decimals = 18;
  uint256 public constant totalSupply = (
    COMPANY_TOKENS_PER_PERIOD * COMPANY_PERIODS +
    PARTNER_TOKENS_PER_PERIOD * PARTNER_PERIODS +
    BOUNTY_TOKENS + MARKETING_COST_TOKENS +
    ICO_TOKENS + SEED_TOKENS);

   
  function TestToken() public {
    address signaturer0 = 0xe029b7b51b8c5B71E6C6f3DC66a11DF3CaB6E3B5;
    address signaturer1 = 0xBEE9b5e75383f56eb103DdC1a4343dcA6124Dfa3;
    address signaturer2 = 0xcdD1Db16E83AA757a5B3E6d03482bBC9A27e8D49;
    IS_SIGNATURER[signaturer0] = true;
    IS_SIGNATURER[signaturer1] = true;
    IS_SIGNATURER[signaturer2] = true;
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

   
  function proposeCompanyAllocation(address _dest, uint256 _tokensPerPeriod) public onlySignaturer {
    companyTokensAllocation.proposeAllocation(msg.sender, _dest, _tokensPerPeriod);
  }

   
  function approveCompanyAllocation(address _dest) public onlySignaturer {
    companyTokensAllocation.approveAllocation(msg.sender, _dest);
  }

   
  function rejectCompanyAllocation(address _dest) public onlySignaturer {
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

   
  function proposePartnerAllocation(address _dest, uint256 _tokensPerPeriod) public onlySignaturer {
    partnerTokensAllocation.proposeAllocation(msg.sender, _dest, _tokensPerPeriod);
  }

   
  function approvePartnerAllocation(address _dest) public onlySignaturer {
    partnerTokensAllocation.approveAllocation(msg.sender, _dest);
  }

   
  function rejectPartnerAllocation(address _dest) public onlySignaturer {
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

  function proposeBountyTransfer(address _dest, uint256 _amount) public onlySignaturer {
    bountyTokensAllocation.proposeBountyTransfer(_dest, _amount);
  }

   
  function approveBountyTransfer(address _dest) public onlySignaturer {
    uint256 tokensToMint = bountyTokensAllocation.approveBountyTransfer(msg.sender, _dest);
    mint(_dest, tokensToMint);
  }

   
  function rejectBountyTransfer(address _dest) public onlySignaturer {
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

  function claimTokens() public returns (uint256) {
    mint(msg.sender,
      partnerTokensAllocation.claimTokens(msg.sender) +
      companyTokensAllocation.claimTokens(msg.sender));
  }
  modifier onlySignaturer() {
    require(IS_SIGNATURER[msg.sender]);
    _;
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

}

contract BountyTokenAllocation is Ownable, AllocationAddressList {

   
   
   

   
  uint256 public remainingBountyTokens;

   
   
   
   
   
   

   
  mapping (address => Types.StructBountyAllocation) public bountyOf;

  address public owner = msg.sender;

   
  function BountyTokenAllocation(uint256 _remainingBountyTokens) onlyOwner public {
    remainingBountyTokens = _remainingBountyTokens;
  }

   
  function proposeBountyTransfer(address _dest, uint256 _amount) public onlyOwner {
    require(_amount > 0);
    require(_amount <= remainingBountyTokens);
      
      
    require(bountyOf[_dest].proposalAddress == 0x0 || bountyOf[_dest].bountyState == Types.BountyState.Rejected);

    if (bountyOf[_dest].bountyState != Types.BountyState.Rejected) {
      allocationAddressList.push(_dest);
    }

    bountyOf[_dest] = Types.StructBountyAllocation({
      amount: _amount,
      proposalAddress: msg.sender,
      bountyState: Types.BountyState.Proposed
    });

    remainingBountyTokens = remainingBountyTokens - _amount;
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

contract VestingAllocation is Ownable, AllocationAddressList {

   

   
  uint256 public periods;
   
  uint256 public minutesInPeriod;
   
  uint256 public remainingTokensPerPeriod;
   
  uint256 public totalSupply;
   
  uint256 public initTimestamp;

   
   
  mapping (address => Types.StructVestingAllocation) public allocationOf;

   
   
  function VestingAllocation(uint256 _tokensPerPeriod, uint256 _periods, uint256 _minutesInPeriod, uint256 _initalTimestamp)  Ownable() public {
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

    allocationOf[_dest] = Types.StructVestingAllocation({
      tokensPerPeriod: _tokensPerPeriod,
      allocationState: Types.AllocationState.Proposed,
      proposerAddress: _proposerAddress,
      claimedPeriods: 0
    });

    remainingTokensPerPeriod = remainingTokensPerPeriod - _tokensPerPeriod;  
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