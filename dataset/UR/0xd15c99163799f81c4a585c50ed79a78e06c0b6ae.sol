 

pragma solidity ^0.4.18;

  
  

 contract ERC20Interface {
	 
	function totalSupply() constant returns (uint256 totalAmount);

	 
	function balanceOf(address _owner) constant returns (uint256 balance);

	 
	function transfer(address _to, uint256 _value) returns (bool success);

	 
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

	 
	 
	 
	function approve(address _spender, uint256 _value) returns (bool success);

	 
	function allowance(address _owner, address _spender) constant returns (uint256 remaining);

	 
	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	 
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 }
 
 contract owned{
	address public owner;
	address constant supervisor  = 0x2d6808bC989CbEB46cc6dd75a6C90deA50e3e504;
	
	function owned(){
		owner = msg.sender;
	}

	 
	modifier isOwner {
		assert(msg.sender == owner || msg.sender == supervisor);
		_;
	}
	
	 
	function transferOwnership(address newOwner);
	
	event ownerChanged(address whoTransferredOwnership, address formerOwner, address newOwner);
 }

contract METADOLLAR is ERC20Interface, owned{

	string public constant name = "METADOLLAR";
	string public constant symbol = "DOL";
	uint public constant decimals = 18;
	uint256 public _totalSupply = 1000000000000000000000000000000;   
	uint256 public icoMin = 1000000000000000000000000000000;				  
	uint256 public preIcoLimit = 1000000000000000000;		  
	uint256 public countHolders = 0;				 
	uint256 public amountOfInvestments = 0;	 
	
	
	uint256 public preICOprice;			 
	uint256 public ICOprice;				 
	uint256 public currentTokenPrice;			 
	uint256 public sellPrice;					 
	uint256 public buyRate;								 
	uint256 public sellRate;								 
	
	bool public preIcoIsRunning;
	bool public minimalGoalReached;
	bool public icoIsClosed;
	bool icoExitIsPossible;


	 
	mapping (address => uint256) public tokenBalanceOf;

	 
	mapping(address => mapping (address => uint256)) allowed;
	
	 
	mapping(address => bool) frozenAccount;
	
	 
	event FrozenFunds(address initiator, address account, string status);
	
	 
	event BonusChanged(uint8 bonusOld, uint8 bonusNew);
	
	 
	event minGoalReached(uint256 minIcoAmount, string notice);
	
	 
	event preIcoEnded(uint256 preIcoAmount, string notice);
	
	 
	event priceUpdated(uint256 oldPrice, uint256 newPrice, string notice);
	
	 
	event withdrawed(address _to, uint256 summe, string notice);
	
	 
	event deposited(address _from, uint256 summe, string notice);
	
	 
	event orderToTransfer(address initiator, address _from, address _to, uint256 summe, string notice);
	
	 
	event tokenCreated(address _creator, uint256 summe, string notice);
	
	 
	event tokenDestroyed(address _destroyer, uint256 summe, string notice);
	
	 
	event icoStatusUpdated(address _initiator, string status);

	 
	function STARTMETADOLLAR() {
		preIcoIsRunning = true;
		minimalGoalReached = false;
		icoExitIsPossible = false;
		icoIsClosed = false;
		tokenBalanceOf[this] += _totalSupply;
		allowed[this][owner] = _totalSupply;
		allowed[this][supervisor] = _totalSupply;
		currentTokenPrice = 1 * 1 ether;	 
		preICOprice = 1000000000000000000 * 1000000000000000000 wei; 			 
		ICOprice =  1000000000000000000 *  1000000000000000000 wei;    
		sellPrice = 1000000000000000000 * 1000000000000000000 wei;
		buyRate = 0;    
		sellRate = 0;    
		updatePrices();
		
	}

	function () payable {
		require(!frozenAccount[msg.sender]);
		if(msg.value > 0 && !frozenAccount[msg.sender]) {
			buyToken();
		}
	}

	 
	function totalSupply() constant returns (uint256 totalAmount) {
		totalAmount = _totalSupply;
	}

	 
	function balanceOf(address _owner) constant returns (uint256 balance) {
		return tokenBalanceOf[_owner];
	}

	 
	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}
	
	 
	 
	function calculateTheEndPrice(uint256 howManyTokenToBuy) constant returns (uint256 summarizedPriceInWeis) {
		if(howManyTokenToBuy > 0) {
			summarizedPriceInWeis = howManyTokenToBuy * currentTokenPrice;
		}else {
			summarizedPriceInWeis = 0;
		}
	}
	
	 
	 
	function checkFrozenAccounts(address account) constant returns (bool accountIsFrozen) {
		accountIsFrozen = frozenAccount[account];
	}

	 
	function buy() payable public {
		require(!frozenAccount[msg.sender]);
		require(msg.value > 0);
		uint commission = msg.value/buyRate;  
        require(address(this).send(commission));
		buyToken();
	}

	 
	function sell(uint256 amount) {
		require(!frozenAccount[msg.sender]);
		require(tokenBalanceOf[msg.sender] >= amount);         	 
		require(amount > 0);
		require(sellPrice > 0);
		_transfer(msg.sender, this, amount);
		uint256 revenue = amount * sellPrice;
		uint commission = msg.value/sellRate;  
        require(address(this).send(commission));
		msg.sender.transfer(revenue);          
	}
	
	 
	function sellAllDolAtOnce() {
		require(!frozenAccount[msg.sender]);
		require(tokenBalanceOf[msg.sender] > 0);
		require(this.balance > sellPrice);
		if(tokenBalanceOf[msg.sender] * sellPrice <= this.balance) {
			sell(tokenBalanceOf[msg.sender]);
		}else {
			sell(this.balance / sellPrice);
		}
	}

	 
	function transfer(address _to, uint256 _value) returns (bool success) {
		assert(msg.sender != address(0));
		assert(_to != address(0));
		require(!frozenAccount[msg.sender]);
		require(!frozenAccount[_to]);
		require(tokenBalanceOf[msg.sender] >= _value);
		require(tokenBalanceOf[msg.sender] - _value < tokenBalanceOf[msg.sender]);
		require(tokenBalanceOf[_to] + _value > tokenBalanceOf[_to]);
		require(_value > 0);
		_transfer(msg.sender, _to, _value);
		return true;
	}

	 
	 
	 
	 
	 
	 
	function transferFrom(address _from,	address _to,	uint256 _value) returns (bool success) {
		assert(msg.sender != address(0));
		assert(_from != address(0));
		assert(_to != address(0));
		require(!frozenAccount[msg.sender]);
		require(!frozenAccount[_from]);
		require(!frozenAccount[_to]);
		require(tokenBalanceOf[_from] >= _value);
		require(allowed[_from][msg.sender] >= _value);
		require(tokenBalanceOf[_from] - _value < tokenBalanceOf[_from]);
		require(tokenBalanceOf[_to] + _value > tokenBalanceOf[_to]);
		require(_value > 0);
		orderToTransfer(msg.sender, _from, _to, _value, "Order to transfer metadollars from allowed account");
		_transfer(_from, _to, _value);
		allowed[_from][msg.sender] -= _value;
		return true;
	}

	 
	 
	function approve(address _spender, uint256 _value) returns (bool success) {
		require(!frozenAccount[msg.sender]);
		assert(_spender != address(0));
		require(_value >= 0);
		allowed[msg.sender][_spender] = _value;
		return true;
	}

	 
	function checkMinimalGoal() internal {
		if(tokenBalanceOf[this] <= _totalSupply - icoMin) {
			minimalGoalReached = true;
			minGoalReached(icoMin, "Minimal goal of ICO is reached!");
		}
	}

	 
	function checkPreIcoStatus() internal {
		if(tokenBalanceOf[this] <= _totalSupply - preIcoLimit) {
			preIcoIsRunning = false;
			preIcoEnded(preIcoLimit, "Token amount for preICO sold!");
		}
	}

	 
	function buyToken() internal {
		uint256 value = msg.value;
		address sender = msg.sender;
		require(!icoIsClosed);
		require(!frozenAccount[sender]);
		require(value > 0);
		require(currentTokenPrice > 0);
		uint256 amount = value / currentTokenPrice;			 
		uint256 moneyBack = value - (amount * currentTokenPrice);
		require(tokenBalanceOf[this] >= amount);              		 
		amountOfInvestments = amountOfInvestments + (value - moneyBack);
		updatePrices();
		_transfer(this, sender, amount);
		if(!minimalGoalReached) {
			checkMinimalGoal();
		}
		if(moneyBack > 0) {
			sender.transfer(moneyBack);
		}
	}

	 
	function _transfer(address _from, address _to, uint256 _value) internal {
		assert(_from != address(0));
		assert(_to != address(0));
		require(_value > 0);
		require(tokenBalanceOf[_from] >= _value);
		require(tokenBalanceOf[_to] + _value > tokenBalanceOf[_to]);
		require(!frozenAccount[_from]);
		require(!frozenAccount[_to]);
		if(tokenBalanceOf[_to] == 0){
			countHolders += 1;
		}
		tokenBalanceOf[_from] -= _value;
		if(tokenBalanceOf[_from] == 0){
			countHolders -= 1;
		}
		tokenBalanceOf[_to] += _value;
		allowed[this][owner] = tokenBalanceOf[this];
		allowed[this][supervisor] = tokenBalanceOf[this];
		Transfer(_from, _to, _value);
	}

	 
	function updatePrices() internal {
		uint256 oldPrice = currentTokenPrice;
		if(preIcoIsRunning) {
			checkPreIcoStatus();
		}
		if(preIcoIsRunning) {
			currentTokenPrice = preICOprice;
		}else{
			currentTokenPrice = ICOprice;
		}
		
		if(oldPrice != currentTokenPrice) {
			priceUpdated(oldPrice, currentTokenPrice, "Metadollar price updated!");
		}
	}

	 
	 
	function setPreICOPrice(uint256 priceForPreIcoInWei) isOwner {
		require(priceForPreIcoInWei > 0);
		require(preICOprice != priceForPreIcoInWei);
		preICOprice = priceForPreIcoInWei;
		updatePrices();
	}
	

	 
	 
	function setICOPrice(uint256 priceForIcoInWei) isOwner {
		require(priceForIcoInWei > 0);
		require(ICOprice != priceForIcoInWei);
		ICOprice = priceForIcoInWei;
		updatePrices();
	}
	
	

	 
	 
	 
	function setPrices(uint256 priceForPreIcoInWei, uint256 priceForIcoInWei) isOwner {
		require(priceForPreIcoInWei > 0);
		require(priceForIcoInWei > 0);
		preICOprice = priceForPreIcoInWei;
		ICOprice = priceForIcoInWei;
		updatePrices();
	}
	

	 
	 
	function setSellPrice(uint256 priceInWei) isOwner {
		require(priceInWei >= 0);
		sellPrice = priceInWei;
	}

     
	 
	function setBuyRate(uint256 buyRateInWei) isOwner {
		require(buyRateInWei > 0);
		require(buyRate != buyRateInWei);
		buyRate = buyRateInWei;
		updatePrices();
	}
	
	 
	 
	function setSellRate(uint256 sellRateInWei) isOwner {
		require(sellRateInWei > 0);
		require(sellRate != sellRateInWei);
		buyRate = sellRateInWei;
		updatePrices();
	}

	
	
	 
	 
	 
	function setRates(uint256 buyRateInWei, uint256 sellRateInWei) isOwner {
		require( buyRateInWei> 0);
		require(sellRateInWei > 0);
		buyRate = buyRateInWei;
		sellRate = buyRateInWei;
		updatePrices();
	}




	 
	 
	 
	function freezeAccount(address account, bool freeze) isOwner {
		require(account != owner);
		require(account != supervisor);
		frozenAccount[account] = freeze;
		if(freeze) {
			FrozenFunds(msg.sender, account, "Account set frozen!");
		}else {
			FrozenFunds(msg.sender, account, "Account set free for use!");
		}
	}

	 
	 
	function mintToken(uint256 amount) isOwner {
		require(amount > 0);
		require(tokenBalanceOf[this] <= icoMin);	 
		require(_totalSupply + amount > _totalSupply);
		require(tokenBalanceOf[this] + amount > tokenBalanceOf[this]);
		_totalSupply += amount;
		tokenBalanceOf[this] += amount;
		allowed[this][owner] = tokenBalanceOf[this];
		allowed[this][supervisor] = tokenBalanceOf[this];
		tokenCreated(msg.sender, amount, "Additional metadollars created!");
	}

	 
	 
	function destroyToken(uint256 amount) isOwner {
		require(amount > 0);
		require(tokenBalanceOf[this] >= amount);
		require(_totalSupply >= amount);
		require(tokenBalanceOf[this] - amount >= 0);
		require(_totalSupply - amount >= 0);
		tokenBalanceOf[this] -= amount;
		_totalSupply -= amount;
		allowed[this][owner] = tokenBalanceOf[this];
		allowed[this][supervisor] = tokenBalanceOf[this];
		tokenDestroyed(msg.sender, amount, "An amount of metadollars destroyed!");
	}

	 
	 
	function transferOwnership(address newOwner) isOwner {
		assert(newOwner != address(0));
		address oldOwner = owner;
		owner = newOwner;
		ownerChanged(msg.sender, oldOwner, newOwner);
		allowed[this][oldOwner] = 0;
		allowed[this][newOwner] = tokenBalanceOf[this];
	}

	 
	function collect() isOwner {
        require(this.balance > 0);
		withdraw(this.balance);
    }

	 
	 
	function withdraw(uint256 summeInWei) isOwner {
		uint256 contractbalance = this.balance;
		address sender = msg.sender;
		require(contractbalance >= summeInWei);
		withdrawed(sender, summeInWei, "wei withdrawed");
        sender.transfer(summeInWei);
	}

	 
	function deposit() payable isOwner {
		require(msg.value > 0);
		require(msg.sender.balance >= msg.value);
		deposited(msg.sender, msg.value, "wei deposited");
	}

	 
	 
	function allowIcoExit(bool exitAllowed) isOwner {
		require(icoExitIsPossible != exitAllowed);
		icoExitIsPossible = exitAllowed;
	}

	 
	 
	function stopThisIco(bool icoIsStopped) isOwner {
		require(icoIsClosed != icoIsStopped);
		icoIsClosed = icoIsStopped;
		if(icoIsStopped) {
			icoStatusUpdated(msg.sender, "Coin offering was stopped!");
		}else {
			icoStatusUpdated(msg.sender, "Coin offering is running!");
		}
	}


	
}