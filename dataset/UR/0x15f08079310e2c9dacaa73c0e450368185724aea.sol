 

 

pragma solidity ^0.4.17;

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

contract owned {
  address public owner;
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function owned() public{
    owner = msg.sender;
  }

  function changeOwner(address newOwner) onlyOwner public{
    owner = newOwner;
  }
}

 
contract mortal is owned {
	 
	uint public closeAt;
	 
  function closeContract(uint playerBalance) internal{
		if(playerBalance == 0) selfdestruct(owner);
		if(closeAt == 0) closeAt = now + 30 days;
		else if(closeAt < now) selfdestruct(owner);
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


contract chargingGas is mortal, SafeMath{
   
	uint public gasPrice;
	 
	mapping(bytes4 => uint) public gasPerTx;
	
	 
	function setGasUsage(bytes4[3] signatures, uint[3] gasNeeded) internal{
	  require(signatures.length == gasNeeded.length);
	  for(uint8 i = 0; i < signatures.length; i++)
	    gasPerTx[signatures[i]] = gasNeeded[i];
	}
	
	 
	function addGas(uint value) internal constant returns(uint){
  	return safeAdd(value,getGasCost());
	}
	
	 
	function subtractGas(uint value) internal constant returns(uint){
  	return safeSub(value,getGasCost());
	}
	
	
	 
	function setGasPrice(uint8 price) public onlyOwner{
		gasPrice = price;
	}
	
	 
	function getGasCost() internal constant returns(uint){
	  return safeMul(safeMul(gasPerTx[msg.sig], gasPrice), tx.gasprice)/1000000000;
	}

}

contract Token {
	function transferFrom(address sender, address receiver, uint amount) public returns(bool success) {}

	function transfer(address receiver, uint amount) public returns(bool success) {}

	function balanceOf(address holder) public constant returns(uint) {}
}

contract CasinoBank is chargingGas{
	 
	uint public playerBalance;
	 
	mapping(address=>uint) public balanceOf;
	 
	mapping(address=>uint) public withdrawAfter;
	 
	Token edg;
	 
	uint public maxDeposit;
	 
	uint public waitingTime;
	
	 
	event Deposit(address _player, uint _numTokens, bool _chargeGas);
	 
	event Withdrawal(address _player, address _receiver, uint _numTokens);

	function CasinoBank(address tokenContract, uint depositLimit) public{
		edg = Token(tokenContract);
		maxDeposit = depositLimit;
		waitingTime = 90 minutes;
	}

	 
	function deposit(address receiver, uint numTokens, bool chargeGas) public isAlive{
		require(numTokens > 0);
		uint value = safeMul(numTokens,100000);
		if(chargeGas) value = subtractGas(value);
		uint newBalance = safeAdd(balanceOf[receiver], value);
		require(newBalance <= maxDeposit);
		assert(edg.transferFrom(msg.sender, address(this), numTokens));
		balanceOf[receiver] = newBalance;
		playerBalance = safeAdd(playerBalance, value);
		Deposit(receiver, numTokens, chargeGas);
  }

	 
	function requestWithdrawal() public{
		withdrawAfter[msg.sender] = now + waitingTime;
	}

	 
	function cancelWithdrawalRequest() public{
		withdrawAfter[msg.sender] = 0;
	}

	 
	function withdraw(uint amount) public keepAlive{
		require(withdrawAfter[msg.sender]>0 && now>withdrawAfter[msg.sender]);
		withdrawAfter[msg.sender] = 0;
		uint value = safeMul(amount,100000);
		balanceOf[msg.sender]=safeSub(balanceOf[msg.sender],value);
		playerBalance = safeSub(playerBalance, value);
		assert(edg.transfer(msg.sender, amount));
		Withdrawal(msg.sender, msg.sender, amount);
	}

	 
	function withdrawBankroll(uint numTokens) public onlyOwner {
		require(numTokens <= bankroll());
		assert(edg.transfer(owner, numTokens));
	}

	 
	function bankroll() constant public returns(uint){
		return safeSub(edg.balanceOf(address(this)), playerBalance/100000);
	}
	
	
	 
	function setMaxDeposit(uint newMax) public onlyOwner{
		maxDeposit = newMax;
	}
	
	 
	function setWaitingTime(uint newWaitingTime) public onlyOwner{
		require(newWaitingTime <= 24 hours);
		waitingTime = newWaitingTime;
	}

	 
	function close() public onlyOwner{
		closeContract(playerBalance);
	}
}

contract EdgelessCasino is CasinoBank{
	 
    mapping(address => bool) public authorized;
	 
	mapping(address => uint) public withdrawCount;
	 
	mapping(address => State) public lastState;
     
    event StateUpdate(uint128 count, int128 winBalance, int difference, uint gasCost, address player, uint128 lcount);
     
    event GameData(address player, bytes32[] serverSeeds, bytes32[] clientSeeds, int[] results);
  
	struct State{
		uint128 count;
		int128 winBalance;
	}

    modifier onlyAuthorized {
        require(authorized[msg.sender]);
        _;
    }


   
  function EdgelessCasino(address authorizedAddress, address tokenContract, uint depositLimit, uint8 kGasPrice) CasinoBank(tokenContract, depositLimit) public{
    authorized[authorizedAddress] = true;
     
    bytes4[3] memory signatures = [bytes4(0x3edd1128),0x9607610a, 0x713d30c6];
     
    uint[3] memory gasUsage = [uint(141),95,60];
    setGasUsage(signatures, gasUsage);
    setGasPrice(kGasPrice);
  }


   
  function withdrawFor(address receiver, uint amount, uint8 v, bytes32 r, bytes32 s) public onlyAuthorized keepAlive{
	var player = ecrecover(keccak256(receiver, amount, withdrawCount[receiver]), v, r, s);
	withdrawCount[receiver]++;
	uint value = addGas(safeMul(amount,100000));
    balanceOf[player] = safeSub(balanceOf[player], value);
	playerBalance = safeSub(playerBalance, value);
    assert(edg.transfer(receiver, amount));
	Withdrawal(player, receiver, amount);
  }

   
  function authorize(address addr) public onlyOwner{
    authorized[addr] = true;
  }

   
  function deauthorize(address addr) public onlyOwner{
    authorized[addr] = false;
  }

   
  function updateState(int128 winBalance,  uint128 gameCount, uint8 v, bytes32 r, bytes32 s) public{
  	address player = determinePlayer(winBalance, gameCount, v, r, s);
  	uint gasCost = 0;
  	if(player == msg.sender) 
  		require(authorized[ecrecover(keccak256(player, winBalance, gameCount), v, r, s)]);
  	else 
  		gasCost = getGasCost();
  	State storage last = lastState[player];
  	require(gameCount > last.count);
  	int difference = updatePlayerBalance(player, winBalance, last.winBalance, gasCost);
  	lastState[player] = State(gameCount, winBalance);
  	StateUpdate(gameCount, winBalance, difference, gasCost, player, last.count);
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
  	  playerBalance = safeAdd(playerBalance, outs);
  	  balanceOf[player] = safeAdd(balanceOf[player], outs);
  	}
  }
  
   
  function logGameData(bytes32[] serverSeeds, bytes32[] clientSeeds, int[] results, uint8 v, bytes32 r, bytes32 s) public{
    address player = determinePlayer(serverSeeds, clientSeeds, results, v, r, s);
    GameData(player, serverSeeds, clientSeeds, results);
     
    if(player != msg.sender){
      uint gasCost = (57 + 768 * serverSeeds.length / 1000)*gasPrice;
      balanceOf[player] = safeSub(balanceOf[player], gasCost);
      playerBalance = safeSub(playerBalance, gasCost);
    }
  }
  
   
  function determinePlayer(bytes32[] serverSeeds, bytes32[] clientSeeds, int[] results, uint8 v, bytes32 r, bytes32 s) constant internal returns(address){
  	if (authorized[msg.sender]) 
  		return ecrecover(keccak256(serverSeeds, clientSeeds, results), v, r, s);
  	else
  		return msg.sender;
  }

}