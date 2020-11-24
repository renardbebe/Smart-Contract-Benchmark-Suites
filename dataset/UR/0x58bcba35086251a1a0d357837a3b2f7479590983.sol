 

 

pragma solidity ^0.5.10;

contract Token {
  function transfer(address receiver, uint amount) public returns(bool);
  function transferFrom(address sender, address receiver, uint amount) public returns(bool);
  function balanceOf(address holder) public view returns(uint);
}

contract Casino {
  mapping(address => bool) public authorized;
}

contract Owned {
  address public owner;
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  constructor() public {
    owner = msg.sender;
  }

  function changeOwner(address newOwner) onlyOwner public {
    owner = newOwner;
  }
}

contract SafeMath {

	function safeSub(uint a, uint b) pure internal returns(uint) {
		assert(b <= a);
		return a - b;
	}

	function safeAdd(uint a, uint b) pure internal returns(uint) {
		uint c = a + b;
		assert(c >= a && c >= b);
		return c;
	}

	function safeMul(uint a, uint b) pure internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
}

contract BankrollLending is Owned, SafeMath {
  struct CycleData {
       
      uint numHolders;
       
      uint initialStakes;
       
      uint finalStakes;
       
      uint totalStakes;
       
      uint lastUpdateIndex;
       
      uint returnToBankroll;
       
      bool sharesDistributed;
       
      mapping(address => Staker) addressToStaker;
       
      mapping(address => uint) addressToBalance;
       
      address[] indexToAddress;
  }
  struct Staker {
     
    uint stakeIndex;
     
    StakingRank rank;
     
    uint staked;
     
    uint payout;
  }
   
  enum StakingPhases { deposit, bankroll }
   
  enum StakingRank { vip, gold, silver }
   
  uint public cycle;
   
  mapping(uint => CycleData) public cycleToData;
   
  StakingPhases public phase; 
   
  Casino public casino;
   
  Token public token;
   
  address public predecessor;
   
  address public returnBankrollTo;
   
  uint public minStakingAmount;
   
  uint public maxUpdates; 
   
  bool public paused;
   
  uint vipRankShare;
   
  uint goldRankShare;
   
  uint silverRankShare;
  
   
  event StakeUpdate(address holder, uint stake);

   
  constructor(address tokenAddr, address casinoAddr, address predecessorAdr) public {
    token = Token(tokenAddr);
    casino = Casino(casinoAddr);
    predecessor = predecessorAdr;
    returnBankrollTo = casinoAddr;
    maxUpdates = 5;
    cycle = 90;
    
    vipRankShare = 1000;
    goldRankShare = 500;
    silverRankShare = 125;
  }
  
   
  function setStakingRankShare(StakingRank _rank, uint _share) public onlyOwner {
    if (_rank == StakingRank.vip) {
        vipRankShare = _share;
    } else if (_rank == StakingRank.gold) {
        goldRankShare = _share;
    } else if (_rank == StakingRank.silver) {
        silverRankShare = _share;
    }
  }
  
   
  function getStakingRankShare(StakingRank _rank) public view returns (uint) {
   if (_rank == StakingRank.vip) {
       return vipRankShare;
    } else if (_rank == StakingRank.gold) {
       return goldRankShare;
    } else if (_rank == StakingRank.silver) {
       return silverRankShare;
    }
    return 0;
  }
  
   
  function setStakerRank(address _address, StakingRank _rank) public onlyAuthorized {
      Staker storage _staker = cycleToData[cycle].addressToStaker[_address];
      require(_staker.staked > 0, "Staker not staked.");
      _staker.rank = _rank;
  }
  
   
  function setReturnBankrollTo(address _address) public onlyOwner {
      returnBankrollTo = _address;
  }
  
   
  function setPaused() public onlyOwner onlyActive {
      paused = true;
  }
  
    
  function setActive() public onlyOwner onlyPaused {
      paused = false;
  }
  
   
  function withdraw(address _receiver) public {
      makeWithdrawal(msg.sender, _receiver, safeSub(cycle, 1));
  }
  
   
  function withdraw(address _receiver, uint _cycle) public {
      makeWithdrawal(msg.sender, _receiver, _cycle);
  }
  
   
  function withdrawFor(address _address, uint _cycle) public onlyAuthorized {
      makeWithdrawal(_address, _address, _cycle);
  }
  
   
  function useAsBankroll() public onlyAuthorized depositPhase {
      CycleData storage _cycle = cycleToData[cycle];
      _cycle.initialStakes = _cycle.totalStakes;
      _cycle.totalStakes = 0;
      assert(token.transfer(address(casino), _cycle.initialStakes));
      phase = StakingPhases.bankroll;
  }
  
   
  function closeCycle(uint _finalStakes) public onlyAuthorized bankrollPhase {
      CycleData storage _cycle = cycleToData[cycle];
      _cycle.finalStakes = _finalStakes;
      cycle = safeAdd(cycle, 1);
      phase = StakingPhases.deposit;
  }
  
   
  function updateUserShares() public onlyAuthorized {
      _updateUserShares(cycle - 1);
  }

   
  function updateUserShares(uint _cycleIndex) public onlyAuthorized {
      _updateUserShares(_cycleIndex);
  }
  
   
  function deposit(uint _value, StakingRank _rank, uint _allowedMax, uint8 v, bytes32 r, bytes32 s) public depositPhase onlyActive {
      require(verifySignature(msg.sender, _allowedMax, _rank, v, r, s));
      makeDeposit(msg.sender, _value, _rank, _allowedMax);
  }
  
   
  function depositFor(address _address, uint _value, StakingRank _rank, uint _allowedMax) public depositPhase onlyActive onlyAuthorized {
      makeDeposit(_address, _value, _rank, _allowedMax);
  }
  
   
  function numHolders() public view returns (uint) {
      return cycleToData[cycle].numHolders;
  }
  
    
  function stakeholders(uint _index) public view returns (address) {
      return stakeholders(cycle, _index);
  }
  
    
  function stakes(address _address) public view returns (uint) {
      return stakes(cycle, _address);
  }
  
    
  function staker(address _address) public view returns (uint stakeIndex, StakingRank rank, uint staked, uint payout) {
      return staker(cycle, _address);
  }
  
   
  function totalStakes() public view returns (uint) {
      return totalStakes(cycle);
  }
  
   
  function initialStakes() public view returns (uint) {
      return initialStakes(cycle);
  }
  
     
  function stakeholders(uint _cycle, uint _index) public view returns (address) {
      return cycleToData[_cycle].indexToAddress[_index];
  }
  
   
  function stakes(uint _cycle, address _address) public view returns (uint) {
      return cycleToData[_cycle].addressToBalance[_address];
  }

   
  function staker(uint _cycle, address _address) public view returns (uint stakeIndex, StakingRank rank, uint staked, uint payout ) {
      Staker memory _s = cycleToData[_cycle].addressToStaker[_address];
      return (_s.stakeIndex, _s.rank, _s.staked, _s.payout);
  }
  
   
  function totalStakes(uint _cycle) public view returns (uint) {
      return cycleToData[_cycle].totalStakes;
  }
  
   
  function initialStakes(uint _cycle) public view returns (uint) {
      return cycleToData[_cycle].initialStakes;
  }
  
   
  function finalStakes(uint _cycle) public view returns (uint) {
      return cycleToData[_cycle].finalStakes;
  }

   
  function setCasinoAddress(address casinoAddr) public onlyOwner {
    casino = Casino(casinoAddr);
  }
  
   
  function setMaxUpdates(uint newMax) public onlyAuthorized {
    maxUpdates = newMax;
  }
  
   
  function setMinStakingAmount(uint amount) public onlyAuthorized {
    minStakingAmount = amount;
  }

   
  function kill() public onlyOwner {
    assert(token.transfer(owner, tokenBalance()));
    selfdestruct(address(uint160(owner)));
  }

   
  function tokenBalance() public view returns(uint) {
    return token.balanceOf(address(this));
  }
  
   
  function makeWithdrawal(address _address, address _receiver, uint _cycle) internal {
      require(_cycle < cycle, "Withdrawal possible only for finished rounds.");
      CycleData storage _cycleData = cycleToData[_cycle];
      require(_cycleData.sharesDistributed == true, "All user shares must be distributed to stakeholders first.");
      uint _balance = _cycleData.addressToBalance[_address];
      require(_balance > 0, "Staker doesn't have balance.");
      _cycleData.addressToBalance[_address] = 0;
      _cycleData.totalStakes = safeSub(_cycleData.totalStakes, _balance);
      emit StakeUpdate(_address, 0);
      assert(token.transfer(_receiver, _balance));
  }
  
  
   
  function _updateUserShares(uint _cycleIndex) internal {
      require(cycle > 0 && cycle > _cycleIndex, "You can't distribute shares of previous cycle when there isn't any.");
      CycleData storage _cycle = cycleToData[_cycleIndex];
      require(_cycle.sharesDistributed == false, "Shares already distributed.");
      uint limit = safeAdd(_cycle.lastUpdateIndex, maxUpdates);
      if (limit >= _cycle.numHolders) {
          limit = _cycle.numHolders;
      }
      address _address;
      uint _payout;
      uint _totalStakes = _cycle.totalStakes;
      for (uint i = _cycle.lastUpdateIndex; i < limit; i++) {
          _address = _cycle.indexToAddress[i];
          Staker storage _staker = _cycle.addressToStaker[_address];
          _payout = computeFinalStake(_staker.staked, _staker.rank, _cycle);
          _staker.payout = _payout;
          _cycle.addressToBalance[_address] = _payout;
          _totalStakes = safeAdd(_totalStakes, _payout);
          emit StakeUpdate(_address, _payout);
      }
      _cycle.totalStakes = _totalStakes;
      _cycle.lastUpdateIndex = limit;
      if (limit >= _cycle.numHolders) {
          if (_cycle.finalStakes > _cycle.totalStakes) {
            _cycle.returnToBankroll = safeSub(_cycle.finalStakes, _cycle.totalStakes);
            if (_cycle.returnToBankroll > 0) {
                assert(token.transfer(returnBankrollTo, _cycle.returnToBankroll));
            }
          }
          _cycle.sharesDistributed = true;
      }
  }
  
    
   function computeFinalStake(uint _initialStake, StakingRank _vipRank, CycleData storage _cycleData) internal view returns(uint) {
       if (_cycleData.finalStakes >= _cycleData.initialStakes) {
        uint profit = ((_initialStake * _cycleData.finalStakes / _cycleData.initialStakes) - _initialStake) * getStakingRankShare(_vipRank) / 1000;
        return _initialStake + profit;
      } else {
        uint loss = (_initialStake - (_initialStake * _cycleData.finalStakes / _cycleData.initialStakes));
        return _initialStake - loss;
      }
    }
    
    
   function makeDeposit(address _address, uint _value, StakingRank _rank, uint _allowedMax) internal {
       require(_value > 0);
       CycleData storage _cycle = cycleToData[cycle];
       uint _balance = _cycle.addressToBalance[_address];
       uint newStake = safeAdd(_balance, _value);
       require(newStake >= minStakingAmount);
       if(_allowedMax > 0){  
           require(newStake <= _allowedMax);
           assert(token.transferFrom(_address, address(this), _value));
       }
       Staker storage _staker = _cycle.addressToStaker[_address];
       
       if (_cycle.addressToBalance[_address] == 0) {
           uint _numHolders = _cycle.indexToAddress.push(_address);
           _cycle.numHolders = _numHolders;
           _staker.stakeIndex = safeSub(_numHolders, 1);
       }
       
       _cycle.addressToBalance[_address] = newStake;
       _staker.staked = newStake;
       _staker.rank = _rank;
       
       _cycle.totalStakes = safeAdd(_cycle.totalStakes, _value);
       
       emit StakeUpdate(_address, newStake);
   }

   
  function verifySignature(address to, uint value, StakingRank rank, uint8 v, bytes32 r, bytes32 s) internal view returns(bool) {
    address signer = ecrecover(keccak256(abi.encodePacked(to, value, rank, cycle)), v, r, s);
    return casino.authorized(signer);
  }
  
   
  modifier onlyAuthorized {
    require(casino.authorized(msg.sender), "Only authorized wallet can request this method.");
    _;
  }

  modifier depositPhase {
    require(phase == StakingPhases.deposit, "Method can be run only in deposit phase.");
    _;
  }

  modifier bankrollPhase {
    require(phase == StakingPhases.bankroll, "Method can be run only in bankroll phase.");
    _;
  }
  
  modifier onlyActive() {
    require(paused == false, "Contract is paused.");
    _;
  }
  
  modifier onlyPaused() {
    require(paused == true, "Contract is not paused.");
    _;
  }

}