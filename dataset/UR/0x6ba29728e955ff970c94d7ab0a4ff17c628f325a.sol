 

 

pragma solidity ^0.4.19;

contract SafeMath {

	function safeSub(uint a, uint b) pure internal returns(uint) {
		assert(b <= a);
		return a - b;
	}
	
	function safeSub(int a, int b) pure internal returns(int) {
		if(b < 0) assert(a - b > a);
		else assert(a - b <= a);
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

contract Token {
	function transferFrom(address sender, address receiver, uint amount) public returns(bool success) {}

	function transfer(address receiver, uint amount) public returns(bool success) {}

	function balanceOf(address holder) public constant returns(uint) {}
}

contract owned {
  address public owner;
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function owned() public{
    owner = msg.sender;
  }

}

 
contract mortal is owned {
	 
	uint public closeAt;
	 
	Token edg;
	
	function mortal(address tokenContract) internal{
		edg = Token(tokenContract);
	}
	 
  function closeContract(uint playerBalance) internal{
		if(closeAt == 0) closeAt = now + 30 days;
		if(closeAt < now || playerBalance == 0){
			edg.transfer(owner, edg.balanceOf(address(this)));
			selfdestruct(owner);
		} 
  }

	 
	function open() onlyOwner public{
		closeAt = 0;
	}

	 
	modifier isAlive {
		require(closeAt == 0);
		_;
	}

	 
	modifier keepAlive {
		if(closeAt > 0) closeAt = now + 30 days;
		_;
	}
}


contract requiringAuthorization is mortal {
	 
	mapping(address => bool) public authorized;
	 
	mapping(address => bool) public allowedReceiver;

	modifier onlyAuthorized {
		require(authorized[msg.sender]);
		_;
	}

	 
	function requiringAuthorization() internal {
		authorized[msg.sender] = true;
		allowedReceiver[msg.sender] = true;
	}

	 
	function authorize(address addr) public onlyOwner {
		authorized[addr] = true;
	}

	 
	function deauthorize(address addr) public onlyOwner {
		authorized[addr] = false;
	}

	 
	function allowReceiver(address receiver) public onlyOwner {
		allowedReceiver[receiver] = true;
	}

	 
	function disallowReceiver(address receiver) public onlyOwner {
		allowedReceiver[receiver] = false;
	}

	 
	function changeOwner(address newOwner) public onlyOwner {
		deauthorize(owner);
		authorize(newOwner);
		disallowReceiver(owner);
		allowReceiver(newOwner);
		owner = newOwner;
	}
}


contract chargingGas is requiringAuthorization, SafeMath {
	 
	uint public constant oneEDG = 100000;
	 
	uint public gasPrice;
	 
	mapping(bytes4 => uint) public gasPerTx;
	 
	uint public gasPayback;
	
	function chargingGas(uint kGasPrice) internal{
		 
	    bytes4[5] memory signatures = [bytes4(0x3edd1128),0x9607610a, 0xde48ff52, 0xc97b6d1f, 0x6bf06fde];
	     
	    uint[5] memory gasUsage = [uint(146), 100, 65, 50, 85];
	    setGasUsage(signatures, gasUsage);
	    setGasPrice(kGasPrice);
	}
	 
	function setGasUsage(bytes4[5] signatures, uint[5] gasNeeded) public onlyOwner {
		require(signatures.length == gasNeeded.length);
		for (uint8 i = 0; i < signatures.length; i++)
			gasPerTx[signatures[i]] = gasNeeded[i];
	}

	 
	function setGasPrice(uint price) public onlyAuthorized {
		require(price < oneEDG/10);
		gasPrice = price;
	}

	 
	function getGasCost() internal view returns(uint) {
		return safeMul(safeMul(gasPerTx[msg.sig], gasPrice), tx.gasprice) / 1000000000;
	}

}


contract CasinoBank is chargingGas {
	 
	uint public playerBalance;
	 
	mapping(address => uint) public balanceOf;
	 
	mapping(address => uint) public withdrawAfter;
	 
	mapping(address => uint) public withdrawCount;
	 
	uint public maxDeposit;
	 
	uint public maxWithdrawal;
	 
	uint public waitingTime;
	 
	address public predecessor;

	 
	event Deposit(address _player, uint _numTokens, uint _gasCost);
	 
	event Withdrawal(address _player, address _receiver, uint _numTokens, uint _gasCost);
	
	
	 
	function CasinoBank(uint depositLimit, address predecessorAddr) internal {
		maxDeposit = depositLimit * oneEDG;
		maxWithdrawal = maxDeposit;
		waitingTime = 24 hours;
		predecessor = predecessorAddr;
	}

	 
	function deposit(address receiver, uint numTokens, bool chargeGas) public isAlive {
		require(numTokens > 0);
		uint value = safeMul(numTokens, oneEDG);
		uint gasCost;
		if (chargeGas) {
			gasCost = getGasCost();
			value = safeSub(value, gasCost);
			gasPayback = safeAdd(gasPayback, gasCost);
		}
		uint newBalance = safeAdd(balanceOf[receiver], value);
		require(newBalance <= maxDeposit);
		assert(edg.transferFrom(msg.sender, address(this), numTokens));
		balanceOf[receiver] = newBalance;
		playerBalance = safeAdd(playerBalance, value);
		Deposit(receiver, numTokens, gasCost);
	}

	 
	function requestWithdrawal() public {
		withdrawAfter[msg.sender] = now + waitingTime;
	}

	 
	function cancelWithdrawalRequest() public {
		withdrawAfter[msg.sender] = 0;
	}

	 
	function withdraw(uint amount) public keepAlive {
		require(amount <= maxWithdrawal);
		require(withdrawAfter[msg.sender] > 0 && now > withdrawAfter[msg.sender]);
		withdrawAfter[msg.sender] = 0;
		uint value = safeMul(amount, oneEDG);
		balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], value);
		playerBalance = safeSub(playerBalance, value);
		assert(edg.transfer(msg.sender, amount));
		Withdrawal(msg.sender, msg.sender, amount, 0);
	}

	 
	function withdrawBankroll(address receiver, uint numTokens) public onlyAuthorized {
		require(numTokens <= bankroll());
		require(allowedReceiver[receiver]);
		assert(edg.transfer(receiver, numTokens));
	}

	 
	function withdrawGasPayback() public onlyAuthorized {
		uint payback = gasPayback / oneEDG;
		assert(payback > 0);
		gasPayback = safeSub(gasPayback, payback * oneEDG);
		assert(edg.transfer(owner, payback));
	}

	 
	function bankroll() constant public returns(uint) {
		return safeSub(edg.balanceOf(address(this)), safeAdd(playerBalance, gasPayback) / oneEDG);
	}


	 
	function setMaxDeposit(uint newMax) public onlyAuthorized {
		maxDeposit = newMax * oneEDG;
	}
	
	 
	function setMaxWithdrawal(uint newMax) public onlyAuthorized {
		maxWithdrawal = newMax * oneEDG;
	}

	 
	function setWaitingTime(uint newWaitingTime) public onlyAuthorized  {
		require(newWaitingTime <= 24 hours);
		waitingTime = newWaitingTime;
	}

	 
	function withdrawFor(address receiver, uint amount, uint8 v, bytes32 r, bytes32 s) public onlyAuthorized keepAlive {
		address player = ecrecover(keccak256(receiver, amount, withdrawCount[receiver]), v, r, s);
		withdrawCount[receiver]++;
		uint gasCost = getGasCost();
		uint value = safeAdd(safeMul(amount, oneEDG), gasCost);
		gasPayback = safeAdd(gasPayback, gasCost);
		balanceOf[player] = safeSub(balanceOf[player], value);
		playerBalance = safeSub(playerBalance, value);
		assert(edg.transfer(receiver, amount));
		Withdrawal(player, receiver, amount, gasCost);
	}
	
	 
	function transferToNewContract(address newCasino, uint8 v, bytes32 r, bytes32 s, bool chargeGas) public onlyAuthorized keepAlive {
		address player = ecrecover(keccak256(address(this), newCasino), v, r, s);
		uint gasCost = 0;
		if(chargeGas) gasCost = getGasCost();
		uint value = safeSub(balanceOf[player], gasCost);
		require(value > oneEDG);
		 
		value /= oneEDG;
		playerBalance = safeSub(playerBalance, balanceOf[player]);
		balanceOf[player] = 0;
		assert(edg.transfer(newCasino, value));
		Withdrawal(player, newCasino, value, gasCost);
		CasinoBank cb = CasinoBank(newCasino);
		assert(cb.credit(player, value));
	}
	
	 
	function credit(address player, uint value) public returns(bool) {
		require(msg.sender == predecessor);
		uint valueWithDecimals = safeMul(value, oneEDG);
		balanceOf[player] = safeAdd(balanceOf[player], valueWithDecimals);
		playerBalance = safeAdd(playerBalance, valueWithDecimals);
		Deposit(player, value, 0);
		return true;
	}

	 
	function close() public onlyOwner {
		closeContract(playerBalance);
	}
}


contract EdgelessCasino is CasinoBank{
	 
	mapping(address => State) public lastState;
	 
	event StateUpdate(address player, uint128 count, int128 winBalance, int difference, uint gasCost);
   
  event GameData(address player, bytes32[] serverSeeds, bytes32[] clientSeeds, int[] results, uint gasCost);
  
	struct State{
		uint128 count;
		int128 winBalance;
	}


   
  function EdgelessCasino(address predecessorAddress, address tokenContract, uint depositLimit, uint kGasPrice) CasinoBank(depositLimit, predecessorAddress) mortal(tokenContract) chargingGas(kGasPrice) public{

  }
  
   
  function updateBatch(int128[] winBalances,  uint128[] gameCounts, uint8[] v, bytes32[] r, bytes32[] s, bool chargeGas) public onlyAuthorized{
    require(winBalances.length == gameCounts.length);
    require(winBalances.length == v.length);
    require(winBalances.length == r.length);
    require(winBalances.length == s.length);
    require(winBalances.length <= 50);
    address player;
    uint gasCost = 0;
    if(chargeGas) 
      gasCost = getGasCost();
    gasPayback = safeAdd(gasPayback, safeMul(gasCost, winBalances.length));
    for(uint8 i = 0; i < winBalances.length; i++){
      player = ecrecover(keccak256(winBalances[i], gameCounts[i]), v[i], r[i], s[i]);
      _updateState(player, winBalances[i], gameCounts[i], gasCost);
    }
  }

   
  function updateState(int128 winBalance,  uint128 gameCount, uint8 v, bytes32 r, bytes32 s, bool chargeGas) public{
  	address player = determinePlayer(winBalance, gameCount, v, r, s);
  	uint gasCost = 0;
  	if(player == msg.sender) 
  		require(authorized[ecrecover(keccak256(player, winBalance, gameCount), v, r, s)]);
  	else if (chargeGas){ 
  		gasCost = getGasCost();
  		gasPayback = safeAdd(gasPayback, gasCost);
  	}
  	_updateState(player, winBalance, gameCount, gasCost);
  }
  
   
  function _updateState(address player, int128 winBalance,  uint128 gameCount, uint gasCost) internal {
    State storage last = lastState[player];
  	require(gameCount > last.count);
  	int difference = updatePlayerBalance(player, winBalance, last.winBalance, gasCost);
  	lastState[player] = State(gameCount, winBalance);
  	StateUpdate(player, gameCount, winBalance, difference, gasCost);
  }

   
  function determinePlayer(int128 winBalance, uint128 gameCount, uint8 v, bytes32 r, bytes32 s) constant internal returns(address){
  	if (authorized[msg.sender]) 
  		return ecrecover(keccak256(winBalance, gameCount), v, r, s);
  	else
  		return msg.sender;
  }

	 
  function updatePlayerBalance(address player, int128 winBalance, int128 lastWinBalance, uint gasCost) internal returns(int difference){
  	difference = safeSub(winBalance, lastWinBalance);
  	int outstanding = safeSub(difference, int(gasCost));
  	uint outs;
  	if(outstanding < 0){
  		outs = uint256(outstanding * (-1));
  		playerBalance = safeSub(playerBalance, outs);
  		balanceOf[player] = safeSub(balanceOf[player], outs);
  	}
  	else{
  		outs = uint256(outstanding);
  		assert(bankroll() * oneEDG > outs);
  	  playerBalance = safeAdd(playerBalance, outs);
  	  balanceOf[player] = safeAdd(balanceOf[player], outs);
  	}
  }
  
   
  function logGameData(bytes32[] serverSeeds, bytes32[] clientSeeds, int[] results, uint8 v, bytes32 r, bytes32 s) public{
    address player = determinePlayer(serverSeeds, clientSeeds, results, v, r, s);
    uint gasCost;
     
    if(player != msg.sender){
      gasCost = (57 + 768 * serverSeeds.length / 1000)*gasPrice;
      balanceOf[player] = safeSub(balanceOf[player], gasCost);
      playerBalance = safeSub(playerBalance, gasCost);
      gasPayback = safeAdd(gasPayback, gasCost);
    }
    GameData(player, serverSeeds, clientSeeds, results, gasCost);
  }
  
   
  function determinePlayer(bytes32[] serverSeeds, bytes32[] clientSeeds, int[] results, uint8 v, bytes32 r, bytes32 s) constant internal returns(address){
  	address signer = ecrecover(keccak256(serverSeeds, clientSeeds, results), v, r, s);
  	if (authorized[msg.sender]) 
  		return signer;
  	else if (authorized[signer])
  		return msg.sender;
  	else 
  	  revert();
  }

}