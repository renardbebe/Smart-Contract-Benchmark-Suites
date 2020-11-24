 

 

pragma solidity ^0.4.17;


contract token {
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

  function changeOwner(address newOwner) onlyOwner public{
    owner = newOwner;
  }
}

contract safeMath {
	 
	function safeSub(uint a, uint b) constant internal returns(uint) {
		assert(b <= a);
		return a - b;
	}

	function safeAdd(uint a, uint b) constant internal returns(uint) {
		uint c = a + b;
		assert(c >= a && c >= b);
		return c;
	}
	
	function safeMul(uint a, uint b) constant internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
}

contract casinoBank is owned, safeMath{
	 
	uint public playerBalance;
	 
  mapping(address=>uint) public balanceOf;
	 
	mapping(address=>uint) public withdrawAfter;
	 
	uint public gasPrice = 20;
	 
	token edg;
	 
	uint public closeAt;
	 
	event Deposit(address _player, uint _numTokens, bool _chargeGas);
	 
	event Withdrawal(address _player, address _receiver, uint _numTokens);
	
	function casinoBank(address tokenContract) public{
		edg = token(tokenContract);
	}
	
	 
	function deposit(address receiver, uint numTokens, bool chargeGas) public isAlive{
		require(numTokens > 0);
		uint value = safeMul(numTokens,10000); 
		if(chargeGas) value = safeSub(value, msg.gas/1000 * gasPrice);
		assert(edg.transferFrom(msg.sender, address(this), numTokens));
		balanceOf[receiver] = safeAdd(balanceOf[receiver], value);
		playerBalance = safeAdd(playerBalance, value);
		Deposit(receiver, numTokens, chargeGas);
  }
	
	 
	function requestWithdrawal() public{
		withdrawAfter[msg.sender] = now + 7 minutes;
	}
	
	 
	function cancelWithdrawalRequest() public{
		withdrawAfter[msg.sender] = 0;
	}
	
	 
	function withdraw(uint amount) public keepAlive{
		require(withdrawAfter[msg.sender]>0 && now>withdrawAfter[msg.sender]);
		withdrawAfter[msg.sender] = 0;
		uint value = safeMul(amount,10000);
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
		return safeSub(edg.balanceOf(address(this)), playerBalance/10000);
	}
	
	 
  function close() onlyOwner public{
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

contract casinoProxy is casinoBank{
	 
  mapping(address => bool) public authorized;
   
  mapping(address => mapping(address => bool)) public authorizedByUser;
   
  mapping(address => mapping(address => uint8)) public lockedByUser;
	 
  address[] public casinoGames;
	 
	mapping(address => uint) public count;

	modifier onlyAuthorized {
    require(authorized[msg.sender]);
    _;
  }
	
	modifier onlyCasinoGames {
		bool isCasino;
		for (uint i = 0; i < casinoGames.length; i++){
			if(msg.sender == casinoGames[i]){
				isCasino = true;
				break;
			}
		}
		require(isCasino);
		_;
	}
  
   
  function casinoProxy(address authorizedAddress, address blackjackAddress, address tokenContract) casinoBank(tokenContract) public{
    authorized[authorizedAddress] = true;
    casinoGames.push(blackjackAddress);
  }

	 
	function shift(address player, uint numTokens, bool isReceiver) public onlyCasinoGames{
		require(authorizedByUser[player][msg.sender]);
		var gasCost = msg.gas/1000 * gasPrice; 
		if(isReceiver){
			numTokens = safeSub(numTokens, gasCost);
			balanceOf[player] = safeAdd(balanceOf[player], numTokens);
			playerBalance = safeAdd(playerBalance, numTokens);
		}
		else{
			numTokens = safeAdd(numTokens, gasCost);
			balanceOf[player] = safeSub(balanceOf[player], numTokens);
			playerBalance = safeSub(playerBalance, numTokens);
		}
	}
  
   
  function withdrawFor(address receiver, uint amount, uint8 v, bytes32 r, bytes32 s) public onlyAuthorized keepAlive{
		uint gasCost =  msg.gas/1000 * gasPrice;
		var player = ecrecover(keccak256(receiver, amount, count[receiver]), v, r, s);
		count[receiver]++;
		uint value = safeAdd(safeMul(amount,10000), gasCost);
    balanceOf[player] = safeSub(balanceOf[player], value);
		playerBalance = safeSub(playerBalance, value);
    assert(edg.transfer(receiver, amount));
		Withdrawal(player, receiver, amount);
  }
  
   
  function setGameAddress(uint8 game, address newAddress) public onlyOwner{
    if(game<casinoGames.length) casinoGames[game] = newAddress;
    else casinoGames.push(newAddress);
  }
  
   
  function authorize(address addr) public onlyOwner{
    authorized[addr] = true;
  }
  
   
  function deauthorize(address addr) public onlyOwner{
    authorized[addr] = false;
  }
  
   
  function authorizeCasino(address playerAddress, address casinoAddress, uint8 v, bytes32 r, bytes32 s) public{
  	address player = ecrecover(keccak256(casinoAddress,lockedByUser[playerAddress][casinoAddress],true), v, r, s);
  	require(player == playerAddress);
  	authorizedByUser[player][casinoAddress] = true;
  }
 
   
  function deauthorizeCasino(address playerAddress, address casinoAddress, uint8 v, bytes32 r, bytes32 s) public{
  	address player = ecrecover(keccak256(casinoAddress,lockedByUser[playerAddress][casinoAddress],false), v, r, s);
  	require(player == playerAddress);
  	authorizedByUser[player][casinoAddress] = false;
  	lockedByUser[player][casinoAddress]++; 
  }
	
	 
	function setGasPrice(uint8 price) public onlyOwner{
		gasPrice = price;
	}
  
   
  function move(uint8 game, bytes data, uint8 v, bytes32 r, bytes32 s) public onlyAuthorized isAlive{
    require(game < casinoGames.length);
    var player = ecrecover(keccak256(data), v, r, s);
		require(withdrawAfter[player] == 0 || now<withdrawAfter[player]);
		assert(checkAddress(player, data));
    assert(casinoGames[game].call(data));
  }

   
  function checkAddress(address player, bytes data) constant internal returns(bool){
  	bytes memory ba;
  	assembly {
      let m := mload(0x40)
      mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, player))
      mstore(0x40, add(m, 52))
      ba := m
   }
   for(uint8 i = 0; i < 20; i++){
   	if(data[16+i]!=ba[i]) return false;
   }
   return true;
  }
	
	
}