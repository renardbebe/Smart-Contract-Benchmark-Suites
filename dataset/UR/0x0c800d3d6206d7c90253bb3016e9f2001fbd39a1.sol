 

 

pragma solidity ^0.4.21;

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

  function Owned() public {
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
   
  enum StatePhases { deposit, bankroll, update, withdraw }
   
  uint public cycle;
   
  Casino public casino;
   
  Token public token;
   
  mapping(uint => uint) public initialStakes;
   
  mapping(uint => uint) public finalStakes;
   
  uint public totalStakes;  
   
  uint public numHolders;
   
  address[] public stakeholders;
   
  mapping(address => uint) public stakes;
   
  uint8 public depositGasCost;
   
  uint8 public withdrawGasCost;
   
  uint public updateGasCost;
   
  uint public minStakingAmount;
   
  uint public maxUpdates; 
   
  uint public maxBatchAssignment;
   
  mapping(uint => uint) lastUpdateIndex;
   
  event StakeUpdate(address holder, uint stake);

   
  function BankrollLending(address tokenAddr, address casinoAddr) public {
    token = Token(tokenAddr);
    casino = Casino(casinoAddr);
    maxUpdates = 200;
    maxBatchAssignment = 200;
    cycle = 9;
  }

   
  function setCasinoAddress(address casinoAddr) public onlyOwner {
    casino = Casino(casinoAddr);
  }

   
  function setDepositGasCost(uint8 gasCost) public onlyAuthorized {
    depositGasCost = gasCost;
  }

   
  function setWithdrawGasCost(uint8 gasCost) public onlyAuthorized {
    withdrawGasCost = gasCost;
  }

   
  function setUpdateGasCost(uint gasCost) public onlyAuthorized {
    updateGasCost = gasCost;
  }
  
   
  function setMaxUpdates(uint newMax) public onlyAuthorized{
    maxUpdates = newMax;
  }
  
   
  function setMinStakingAmount(uint amount) public onlyAuthorized {
    minStakingAmount = amount;
  }
  
   
  function setMaxBatchAssignment(uint newMax) public onlyAuthorized {
    maxBatchAssignment = newMax;
  }
  
   
  function deposit(uint value, uint allowedMax, uint8 v, bytes32 r, bytes32 s) public depositPhase {
    require(verifySignature(msg.sender, allowedMax, v, r, s));
    if (addDeposit(msg.sender, value, numHolders, allowedMax))
      numHolders = safeAdd(numHolders, 1);
    totalStakes = safeSub(safeAdd(totalStakes, value), depositGasCost);
  }

   
  function batchAssignment(address[] to, uint[] value) public onlyAuthorized depositPhase {
    require(to.length == value.length);
    require(to.length <= maxBatchAssignment);
    uint newTotalStakes = totalStakes;
    uint numSH = numHolders;
    for (uint8 i = 0; i < to.length; i++) {
      newTotalStakes = safeSub(safeAdd(newTotalStakes, value[i]), depositGasCost);
      if(addDeposit(to[i], value[i], numSH, 0))
        numSH = safeAdd(numSH, 1); 
    }
    numHolders = numSH;
     
    assert(newTotalStakes < tokenBalance());
    totalStakes = newTotalStakes;
  }
  
   
  function addDeposit(address to, uint value, uint numSH, uint allowedMax) internal returns (bool newHolder) {
    require(value > 0);
    uint newStake = safeSub(safeAdd(stakes[to], value), depositGasCost);
    require(newStake >= minStakingAmount);
    if(allowedMax > 0){ 
      require(newStake <= allowedMax);
      assert(token.transferFrom(to, address(this), value));
    }
    if(stakes[to] == 0){
      addHolder(to, numSH);
      newHolder = true;
    }
    stakes[to] = newStake;
    emit StakeUpdate(to, newStake);
  }

   
  function useAsBankroll() public onlyAuthorized depositPhase {
    initialStakes[cycle] = totalStakes;
    totalStakes = 0;  
    assert(token.transfer(address(casino), initialStakes[cycle]));
  }

   
  function startNextCycle() public onlyAuthorized {
     
    require(finalStakes[cycle] > 0);
    cycle = safeAdd(cycle, 1);
  }

   
  function closeCycle(uint value) public onlyAuthorized bankrollPhase {
    require(tokenBalance() >= value);
    finalStakes[cycle] = safeSub(value, safeMul(updateGasCost, numHolders)/100); 
  }

   
  function updateUserShares() public onlyAuthorized updatePhase {
    uint limit = safeAdd(lastUpdateIndex[cycle], maxUpdates);
    if(limit >= numHolders) {
      limit = numHolders;
      totalStakes = finalStakes[cycle];  
      if (cycle > 1) {
        lastUpdateIndex[cycle - 1] = 0;
      }
    }
    address holder;
    uint newStake;
    for(uint i = lastUpdateIndex[cycle]; i < limit; i++){
      holder = stakeholders[i];
      newStake = computeFinalStake(stakes[holder]);
      stakes[holder] = newStake;
      emit StakeUpdate(holder, newStake);
    }
    lastUpdateIndex[cycle] = limit;
  }

   
  function unlockWithdrawals(uint value) public onlyOwner {
    require(value <= tokenBalance());
    totalStakes = value;
  }

   
  function withdraw(address to, uint value, uint index) public withdrawPhase{
    makeWithdrawal(msg.sender, to, value, index);
  }

   
  function withdrawFor(address to, uint value, uint index, uint8 v, bytes32 r, bytes32 s) public onlyAuthorized withdrawPhase{
    address from = ecrecover(keccak256(to, value, cycle), v, r, s);
    makeWithdrawal(from, to, value, index);
  }
  
   
  function makeWithdrawal(address from, address to, uint value, uint index) internal{
    if(value == stakes[from]){
      stakes[from] = 0;
      removeHolder(from, index);
      emit StakeUpdate(from, 0);
    }
    else{
      uint newStake = safeSub(stakes[from], value);
      require(newStake >= minStakingAmount);
      stakes[from] = newStake;
      emit StakeUpdate(from, newStake);
    }
    totalStakes = safeSub(totalStakes, value);
    assert(token.transfer(to, safeSub(value, withdrawGasCost)));
  }

   
  function withdrawExcess() public onlyAuthorized {
    uint value = safeSub(tokenBalance(), totalStakes);
    token.transfer(owner, value);
  }

   
  function kill() public onlyOwner {
    assert(token.transfer(owner, tokenBalance()));
    selfdestruct(owner);
  }

   
  function tokenBalance() public view returns(uint) {
    return token.balanceOf(address(this));
  }

   
  function addHolder(address holder, uint numSH) internal{
    if(numSH < stakeholders.length)
      stakeholders[numSH] = holder;
    else
      stakeholders.push(holder);
  }
  
   
  function removeHolder(address holder, uint index) internal{
    require(stakeholders[index] == holder);
    numHolders = safeSub(numHolders, 1);
    stakeholders[index] = stakeholders[numHolders];
  }

   
  function computeFinalStake(uint initialStake) internal view returns(uint) {
    return safeMul(initialStake, finalStakes[cycle]) / initialStakes[cycle];
  }

   
  function verifySignature(address to, uint value, uint8 v, bytes32 r, bytes32 s) internal view returns(bool) {
    address signer = ecrecover(keccak256(to, value, cycle), v, r, s);
    return casino.authorized(signer);
  }

   
  function getPhase() internal view returns (StatePhases) {
    if (initialStakes[cycle] == 0) {
      return StatePhases.deposit;
    } else if (finalStakes[cycle] == 0) {
      return StatePhases.bankroll;
    } else if (totalStakes == 0) {
      return StatePhases.update;
    }
    return StatePhases.withdraw;
  }
  
   
  modifier onlyAuthorized {
    require(casino.authorized(msg.sender));
    _;
  }

   
  modifier depositPhase {
    require(getPhase() == StatePhases.deposit);
    _;
  }

   
  modifier bankrollPhase {
    require(getPhase() == StatePhases.bankroll);
    _;
  }

   
  modifier updatePhase {
    require(getPhase() == StatePhases.update);
    _;
  }

   
  modifier withdrawPhase {
    require(getPhase() == StatePhases.withdraw);
    _;
  }

}