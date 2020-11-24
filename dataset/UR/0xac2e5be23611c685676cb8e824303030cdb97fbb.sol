 

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


 
contract Shareable {

   
  struct PendingState {
    uint yetNeeded;
    uint ownersDone;
    uint index;
  }

   
  uint public required;

   
  address[256] owners;
   
  mapping(address => uint) ownerIndex;
   
  mapping(bytes32 => PendingState) pendings;
  bytes32[] pendingsIndex;


   
   
  event Confirmation(address owner, bytes32 operation);
  event Revoke(address owner, bytes32 operation);


   
  modifier onlyOwner {
    if (!isOwner(msg.sender)) {
      throw;
    }
    _;
  }

   
  modifier onlymanyowners(bytes32 _operation) {
    if (confirmAndCheck(_operation)) {
      _;
    }
  }

   
  function Shareable(address[] _owners, uint _required) {
    owners[1] = msg.sender;
    ownerIndex[msg.sender] = 1;
    for (uint i = 0; i < _owners.length; ++i) {
      owners[2 + i] = _owners[i];
      ownerIndex[_owners[i]] = 2 + i;
    }
    required = _required;
    if (required > owners.length) {
      throw;
    }
  }

   
  function revoke(bytes32 _operation) external {
    uint index = ownerIndex[msg.sender];
     
    if (index == 0) {
      return;
    }
    uint ownerIndexBit = 2**index;
    var pending = pendings[_operation];
    if (pending.ownersDone & ownerIndexBit > 0) {
      pending.yetNeeded++;
      pending.ownersDone -= ownerIndexBit;
      Revoke(msg.sender, _operation);
    }
  }

   
  function getOwner(uint ownerIndex) external constant returns (address) {
    return address(owners[ownerIndex + 1]);
  }

   
  function isOwner(address _addr) constant returns (bool) {
    return ownerIndex[_addr] > 0;
  }

   
  function hasConfirmed(bytes32 _operation, address _owner) constant returns (bool) {
    var pending = pendings[_operation];
    uint index = ownerIndex[_owner];

     
    if (index == 0) {
      return false;
    }

     
    uint ownerIndexBit = 2**index;
    return !(pending.ownersDone & ownerIndexBit == 0);
  }

   
  function confirmAndCheck(bytes32 _operation) internal returns (bool) {
     
    uint index = ownerIndex[msg.sender];
     
    if (index == 0) {
      throw;
    }

    var pending = pendings[_operation];
     
    if (pending.yetNeeded == 0) {
       
      pending.yetNeeded = required;
       
      pending.ownersDone = 0;
      pending.index = pendingsIndex.length++;
      pendingsIndex[pending.index] = _operation;
    }
     
    uint ownerIndexBit = 2**index;
     
    if (pending.ownersDone & ownerIndexBit == 0) {
      Confirmation(msg.sender, _operation);
       
      if (pending.yetNeeded <= 1) {
         
        delete pendingsIndex[pendings[_operation].index];
        delete pendings[_operation];
        return true;
      } else {
         
        pending.yetNeeded--;
        pending.ownersDone |= ownerIndexBit;
      }
    }
    return false;
  }


   
  function clearPending() internal {
    uint length = pendingsIndex.length;
    for (uint i = 0; i < length; ++i) {
      if (pendingsIndex[i] != 0) {
        delete pendings[pendingsIndex[i]];
      }
    }
    delete pendingsIndex;
  }

}

 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
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

 

contract BTH is StandardToken, Shareable {
  using SafeMath for uint256;

   
  string public constant name = "Bether";
  string public constant symbol = "BTH";
  uint256 public constant decimals = 18;
  string public version = "1.0";

  uint256 public constant INITIAL_SUBSIDY = 50 * 10**decimals;
  uint256 public constant HASH_RATE_MULTIPLIER = 1;

   
  event LogContribution(address indexed _miner, uint256 _value, uint256 _hashRate, uint256 _block, uint256 _halving);
  event LogClaimHalvingSubsidy(address indexed _miner, uint256 _block, uint256 _halving, uint256 _value);
  event LogRemainingHalvingSubsidy(uint256 _halving, uint256 _value);
  event LogPause(bytes32 indexed _hash);
  event LogUnPause(bytes32 indexed _hash);
  event LogBTHFoundationWalletChanged(address indexed _wallet);
  event LogPollCreated(bytes32 indexed _hash);
  event LogPollDeleted(bytes32 indexed _hash);
  event LogPollVoted(bytes32 indexed _hash, address indexed _miner, uint256 _hashRate);
  event LogPollApproved(bytes32 indexed _hash);

   
  mapping (uint256 => HalvingHashRate) halvingsHashRate;  
  mapping (uint256 => Subsidy) halvingsSubsidies;  
  mapping (address => Miner) miners;  
  mapping (bytes32 => Poll) polls;  

  address public bthFoundationWallet;
  uint256 public subsidyHalvingInterval;
  uint256 public maxHalvings;
  uint256 public genesis;
  uint256 public totalHashRate;
  bool public paused;

  struct HalvingHashRate {
    bool carried;  
    uint256 rate;  
  }

  struct Miner {
    uint256 block;  
    uint256 totalHashRate;  
    mapping (uint256 => MinerHashRate) hashRate;
  }

  struct MinerHashRate {
    bool carried;
    uint256 rate;
  }

  struct Subsidy {
    bool claimed;   
                    
    uint256 value;  
  }

  struct Poll {
    bool exists;   
    string title;  
    mapping (address => bool) votes;  
    uint8 percentage;  
    uint256 hashRate;  
    bool approved;  
    uint256 approvalBlock;  
    uint256 approvalHashRate;  
    uint256 approvalTotalHashRate;  
  }

   
  modifier notBeforeGenesis() {
    require(block.number >= genesis);
    _;
  }

  modifier nonZero(uint256 _value) {
    require(_value > 0);
    _;
  }

  modifier nonZeroAddress(address _address) {
    require(_address != address(0));
    _;
  }

  modifier nonZeroValued() {
    require(msg.value != 0);
    _;
  }

  modifier nonZeroLength(address[] array) {
    require(array.length != 0);
    _;
  }

  modifier notPaused() {
    require(!paused);
    _;
  }

  modifier notGreaterThanCurrentBlock(uint256 _block) {
    require(_block <= currentBlock());
    _;
  }

  modifier isMiner(address _address) {
    require(miners[_address].block != 0);
    _;
  }

  modifier pollApproved(bytes32 _hash) {
    require(polls[_hash].approved);
    _;
  }

   

   
  function BTH(
    address[] _bthFoundationMembers,
    uint256 _required,
    address _bthFoundationWallet,
    uint256 _genesis,
    uint256 _subsidyHalvingInterval,
    uint256 _maxHalvings
  ) Shareable( _bthFoundationMembers, _required)
    nonZeroLength(_bthFoundationMembers)
    nonZero(_required)
    nonZeroAddress(_bthFoundationWallet)
    nonZero(_genesis)
    nonZero(_subsidyHalvingInterval)
    nonZero(_maxHalvings)
  {
     
    if (_genesis < block.number) throw;

    bthFoundationWallet = _bthFoundationWallet;
    subsidyHalvingInterval = _subsidyHalvingInterval;
    maxHalvings = _maxHalvings;

    genesis = _genesis;
    totalSupply = 0;
    totalHashRate = 0;
    paused = false;
  }

   
  function kill(bytes32 _hash)
    external
    pollApproved(_hash)
    onlymanyowners(sha3(msg.data))
  {
    selfdestruct(bthFoundationWallet);
  }

   
  function killTo(address _to, bytes32 _hash)
    external
    nonZeroAddress(_to)
    pollApproved(_hash)
    onlymanyowners(sha3(msg.data))
  {
    selfdestruct(_to);
  }

   
  function pause(bytes32 _hash)
    external
    pollApproved(_hash)
    onlymanyowners(sha3(msg.data))
    notBeforeGenesis
  {
    if (!paused) {
      paused = true;
      LogPause(_hash);
    }
  }

   
  function unPause(bytes32 _hash)
    external
    pollApproved(_hash)
    onlymanyowners(sha3(msg.data))
    notBeforeGenesis
  {
    if (paused) {
      paused = false;
      LogUnPause(_hash);
    }
  }

   
  function setBTHFoundationWallet(address _wallet)
    external
    onlymanyowners(sha3(msg.data))
    nonZeroAddress(_wallet)
  {
    bthFoundationWallet = _wallet;
    LogBTHFoundationWalletChanged(_wallet);
  }

   
  function currentBlock()
    public
    constant
    notBeforeGenesis
    returns(uint256)
  {
    return block.number.sub(genesis);
  }

    
  function blockHalving(uint256 _block)
    public
    constant
    notBeforeGenesis
    returns(uint256)
  {
    return _block.div(subsidyHalvingInterval);
  }

   
  function blockOffset(uint256 _block)
    public
    constant
    notBeforeGenesis
    returns(uint256)
  {
    return _block % subsidyHalvingInterval;
  }

   
  function currentHalving()
    public
    constant
    notBeforeGenesis
    returns(uint256)
  {
    return blockHalving(currentBlock());
  }

   
  function halvingStartBlock(uint256 _halving)
    public
    constant
    notBeforeGenesis
    returns(uint256)
  {
    return _halving.mul(subsidyHalvingInterval);
  }

   
  function blockSubsidy(uint256 _block)
    public
    constant
    notBeforeGenesis
    returns(uint256)
  {
    uint256 halvings = _block.div(subsidyHalvingInterval);

    if (halvings >= maxHalvings) return 0;

    uint256 subsidy = INITIAL_SUBSIDY >> halvings;

    return subsidy;
  }

   
  function halvingSubsidy(uint256 _halving)
    public
    constant
    notBeforeGenesis
    returns(uint256)
  {
    uint256 startBlock = halvingStartBlock(_halving);

    return blockSubsidy(startBlock).mul(subsidyHalvingInterval);
  }

   
  function()
    payable
  {
    contribute(msg.sender);
  }

   
  function proxiedContribution(address _miner)
    public
    payable
    returns (bool)
  {
    if (_miner == address(0)) {
       
       
      return contribute(msg.sender);
    } else {
      return contribute(_miner);
    }
  }

   
  function contribute(address _miner)
    internal
    notBeforeGenesis
    nonZeroValued
    notPaused
    returns (bool)
  {
    uint256 block = currentBlock();
    uint256 halving = currentHalving();
    uint256 hashRate = HASH_RATE_MULTIPLIER.mul(msg.value);
    Miner miner = miners[_miner];

     
    if (halving != 0 && halving < maxHalvings) {
      uint256 I;
      uint256 n = 0;
      for (I = halving - 1; I > 0; I--) {
        if (!halvingsHashRate[I].carried) {
          n = n.add(1);
        } else {
          break;
        }
      }

      for (I = halving - n; I < halving; I++) {
        if (!halvingsHashRate[I].carried) {
          halvingsHashRate[I].carried = true;
          halvingsHashRate[I].rate = halvingsHashRate[I].rate.add(halvingsHashRate[I - 1].rate);
        }
      }
    }

     
    if (halving < maxHalvings) {
      halvingsHashRate[halving].rate = halvingsHashRate[halving].rate.add(hashRate);
    }

     

     
     
     
     
    if (miner.block == 0) {
      miner.block = block;
    }

     
    miner.hashRate[halving].rate = miner.hashRate[halving].rate.add(hashRate);
    miner.totalHashRate = miner.totalHashRate.add(hashRate);

     
    totalHashRate = totalHashRate.add(hashRate);

     
    if (!bthFoundationWallet.send(msg.value)) {
      throw;
    }

     
    LogContribution(_miner, msg.value, hashRate, block, halving);

    return true;
  }

   
  function claimHalvingsSubsidies(uint256 _n)
    public
    notBeforeGenesis
    notPaused
    isMiner(msg.sender)
    returns(uint256)
  {
    Miner miner = miners[msg.sender];
    uint256 start = blockHalving(miner.block);
    uint256 end = start.add(_n);

    if (end > currentHalving()) {
      return 0;
    }

    uint256 subsidy = 0;
    uint256 totalSubsidy = 0;
    uint256 unclaimed = 0;
    uint256 hashRate = 0;
    uint256 K;

     
    for(K = start; K < end && K < maxHalvings; K++) {
       
       
      HalvingHashRate halvingHashRate = halvingsHashRate[K];

      if (!halvingHashRate.carried) {
        halvingHashRate.carried = true;
        halvingHashRate.rate = halvingHashRate.rate.add(halvingsHashRate[K-1].rate);
      }

       
       
      MinerHashRate minerHashRate = miner.hashRate[K];
      if (!minerHashRate.carried) {
        minerHashRate.carried = true;
        minerHashRate.rate = minerHashRate.rate.add(miner.hashRate[K-1].rate);
      }

      hashRate = minerHashRate.rate;

      if (hashRate != 0){
         
        if (K == currentHalving().sub(1)) {
          if (currentBlock() % subsidyHalvingInterval < miner.block % subsidyHalvingInterval) {
             
            continue;
          }
        }

        Subsidy sub = halvingsSubsidies[K];

        if (!sub.claimed) {
          sub.claimed = true;
          sub.value = halvingSubsidy(K);
        }

        unclaimed = sub.value;
        subsidy = halvingSubsidy(K).mul(hashRate).div(halvingHashRate.rate);

        if (subsidy > unclaimed) {
          subsidy = unclaimed;
        }

        totalSubsidy = totalSubsidy.add(subsidy);
        sub.value = sub.value.sub(subsidy);

        LogClaimHalvingSubsidy(msg.sender, miner.block, K, subsidy);
        LogRemainingHalvingSubsidy(K, sub.value);
      }

       
      miner.block = miner.block.add(subsidyHalvingInterval);
    }

     
     
    if (K < end) {
      miner.block = miner.block.add(subsidyHalvingInterval.mul(end.sub(K)));
    }

    if (totalSubsidy != 0){
      balances[msg.sender] = balances[msg.sender].add(totalSubsidy);
      totalSupply = totalSupply.add(totalSubsidy);
    }

    return totalSubsidy;
  }

   
  function claimableHalvings()
    public
    constant
    returns(uint256)
  {
    return claimableHalvingsOf(msg.sender);
  }


   
  function claimableHalvingsOf(address _miner)
    public
    constant
    notBeforeGenesis
    isMiner(_miner)
    returns(uint256)
  {
    Miner miner = miners[_miner];
    uint256 halving = currentHalving();
    uint256 minerHalving = blockHalving(miner.block);

     
    if (minerHalving == halving) {
      return 0;
    } else {
       
      if (currentBlock() % subsidyHalvingInterval < miner.block % subsidyHalvingInterval) {
         
         
        return halving.sub(minerHalving).sub(1);
      } else {
        return halving.sub(minerHalving);
      }
    }
  }

   
  function claim()
    public
    notBeforeGenesis
    notPaused
    isMiner(msg.sender)
    returns(uint256)
  {
    return claimHalvingsSubsidies(claimableHalvings());
  }

   
  function transfer(address _to, uint _value)
    public
    notPaused
  {
    super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint _value)
    public
    notPaused
  {
    super.transferFrom(_from, _to, _value);
  }

   

   
  function createPoll(string _title, uint8 _percentage)
    external
    onlymanyowners(sha3(msg.data))
  {
    bytes32 hash = sha3(_title);
    Poll poll = polls[hash];

    if (poll.exists) {
      throw;
    }

    if (_percentage < 1 || _percentage > 100) {
      throw;
    }

    poll.exists = true;
    poll.title = _title;
    poll.percentage = _percentage;
    poll.hashRate = 0;
    poll.approved = false;
    poll.approvalBlock = 0;
    poll.approvalHashRate = 0;
    poll.approvalTotalHashRate = 0;

    LogPollCreated(hash);
  }

   
  function deletePoll(bytes32 _hash)
    external
    onlymanyowners(sha3(msg.data))
  {
    Poll poll = polls[_hash];

    if (poll.exists) {
      delete polls[_hash];

      LogPollDeleted(_hash);
    }
  }

   
  function getPoll(bytes32 _hash)
    external
    constant
    returns(bool, string, uint8, uint256, uint256, bool, uint256, uint256, uint256)
  {
    Poll poll = polls[_hash];

    return (poll.exists, poll.title, poll.percentage, poll.hashRate, totalHashRate,
      poll.approved, poll.approvalBlock, poll.approvalHashRate, poll.approvalTotalHashRate);
  }

  function vote(bytes32 _hash)
    external
    isMiner(msg.sender)
  {
    Poll poll = polls[_hash];

    if (poll.exists) {
      if (!poll.votes[msg.sender]) {
         
        Miner miner = miners[msg.sender];

        poll.votes[msg.sender] = true;
        poll.hashRate = poll.hashRate.add(miner.totalHashRate);

         
        LogPollVoted(_hash, msg.sender, miner.totalHashRate);

         
        if (!poll.approved) {
          if (poll.hashRate.mul(100).div(totalHashRate) >= poll.percentage) {
            poll.approved = true;

            poll.approvalBlock = block.number;
            poll.approvalHashRate = poll.hashRate;
            poll.approvalTotalHashRate = totalHashRate;

            LogPollApproved(_hash);
          }
        }
      }
    }
  }

   


   

   
  function getHalvingBlocks()
    public
    constant
    notBeforeGenesis
    returns(uint256)
  {
    return subsidyHalvingInterval;
  }

   
  function getMinerBlock()
    public
    constant
    returns(uint256)
  {
    return getBlockOf(msg.sender);
  }

   
  function getBlockOf(address _miner)
    public
    constant
    notBeforeGenesis
    isMiner(_miner)
    returns(uint256)
  {
    return miners[_miner].block;
  }

   
  function getHalvingOf(address _miner)
    public
    constant
    notBeforeGenesis
    isMiner(_miner)
    returns(uint256)
  {
    return blockHalving(miners[_miner].block);
  }

   
  function getMinerHalving()
    public
    constant
    returns(uint256)
  {
    return getHalvingOf(msg.sender);
  }

   
  function getMinerHalvingHashRateOf(address _miner)
    public
    constant
    notBeforeGenesis
    isMiner(_miner)
    returns(uint256)
  {
    Miner miner = miners[_miner];
    uint256 halving = getMinerHalving();
    MinerHashRate hashRate = miner.hashRate[halving];

    if (halving == 0) {
      return  hashRate.rate;
    } else {
      if (!hashRate.carried) {
        return hashRate.rate.add(miner.hashRate[halving - 1].rate);
      } else {
        return hashRate.rate;
      }
    }
  }

   
  function getMinerHalvingHashRate()
    public
    constant
    returns(uint256)
  {
    return getMinerHalvingHashRateOf(msg.sender);
  }

   
  function getMinerOffsetOf(address _miner)
    public
    constant
    notBeforeGenesis
    isMiner(_miner)
    returns(uint256)
  {
    return blockOffset(miners[_miner].block);
  }

   
  function getMinerOffset()
    public
    constant
    returns(uint256)
  {
    return getMinerOffsetOf(msg.sender);
  }

   
  function getHashRateOf(address _miner, uint256 _halving)
    public
    constant
    notBeforeGenesis
    isMiner(_miner)
    returns(bool, uint256)
  {
    require(_halving <= currentHalving());

    Miner miner = miners[_miner];
    MinerHashRate hashRate = miner.hashRate[_halving];

    return (hashRate.carried, hashRate.rate);
  }

   
  function getHashRateOfCurrentHalving(address _miner)
    public
    constant
    returns(bool, uint256)
  {
    return getHashRateOf(_miner, currentHalving());
  }

   
  function getMinerHashRate(uint256 _halving)
    public
    constant
    returns(bool, uint256)
  {
    return getHashRateOf(msg.sender, _halving);
  }

   
  function getMinerHashRateCurrentHalving()
    public
    constant
    returns(bool, uint256)
  {
    return getHashRateOf(msg.sender, currentHalving());
  }

   
  function getTotalHashRateOf(address _miner)
    public
    constant
    notBeforeGenesis
    isMiner(_miner)
    returns(uint256)
  {
    return miners[_miner].totalHashRate;
  }

   
  function getTotalHashRate()
    public
    constant
    returns(uint256)
  {
    return getTotalHashRateOf(msg.sender);
  }

   
  function getUnclaimedHalvingSubsidy(uint256 _halving)
    public
    constant
    notBeforeGenesis
    returns(uint256)
  {
    require(_halving < currentHalving());

    if (!halvingsSubsidies[_halving].claimed) {
       
       
      return halvingSubsidy(_halving);
    } else {
       
      halvingsSubsidies[_halving].value;
    }
  }
}