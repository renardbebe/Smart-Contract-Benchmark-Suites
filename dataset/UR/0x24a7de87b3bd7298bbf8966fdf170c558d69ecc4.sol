 

pragma solidity ^0.4.18;
 
 
 
 
 
 
  
  
 
   
   contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
    
 contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Owned{
	address public owner;
	address constant supervisor  = 0x318B0f768f5c6c567227AA50B51B5b3078902f8C;
	
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
 

contract METADOLLAR is ERC20Interface, Owned, SafeMath {
    
    

	string public constant name = "METADOLLAR";
	string public constant symbol = "DOL";
	uint public constant decimals = 18;
	uint256 public _totalSupply = 1000000000000000000000000000000;
	uint256 public icoMin = 1000000000000000;					
	uint256 public icoLimit = 1000000000000000000000000000000;			
	uint256 public countHolders = 0;				 
	uint256 public amountOfInvestments = 0;	 
	
	
	uint256 public icoPrice;	
	uint256 public dolRate = 1000;
	uint256 public ethRate = 1;
	uint256 public sellRate = 900;
	uint256 public commissionRate = 1000;
	uint256 public sellPrice;
	uint256 public currentTokenPrice;				
	uint256 public commission;	
	
	
	bool public icoIsRunning;
	bool public minimalGoalReached;
	bool public icoIsClosed;

	 
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
		icoIsRunning = true;
		minimalGoalReached = false;
		icoIsClosed = false;
		tokenBalanceOf[this] += _totalSupply;
		allowed[this][owner] = _totalSupply;
		allowed[this][supervisor] = _totalSupply;
		currentTokenPrice = 1 * 1;	 
		icoPrice = ethRate * dolRate;		
		sellPrice = sellRate * ethRate;
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
		commission = msg.value/commissionRate;  
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
		require(this.balance >= revenue);
		commission = msg.value/commissionRate;  
        require(address(this).send(commission));
		msg.sender.transfer(revenue);                		 
	}
	
   

    function sell2(address _tokenAddress) public payable{
        METADOLLAR token = METADOLLAR(_tokenAddress);
        uint tokens = msg.value * sellPrice;
        require(token.balanceOf(this) >= tokens);
        commission = msg.value/commissionRate;  
       require(address(this).send(commission));
        token.transfer(msg.sender, tokens);
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
		orderToTransfer(msg.sender, _from, _to, _value, "Order to transfer tokens from allowed account");
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

	 
	function checkIcoStatus() internal {
		if(tokenBalanceOf[this] <= _totalSupply - icoLimit) {
			icoIsRunning = false;
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
		uint256 moneyBack = value - (amount * sellPrice);
		require(tokenBalanceOf[this] >= amount);              		 
		amountOfInvestments = amountOfInvestments + (value - moneyBack);
		updatePrices();
		_transfer(this, sender, amount);
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
		if(icoIsRunning) {
			checkIcoStatus();
		}
		if(icoIsRunning) {
			currentTokenPrice = icoPrice;
		}else{
			currentTokenPrice = icoPrice;
		}
		
		if(oldPrice != currentTokenPrice) {
			priceUpdated(oldPrice, currentTokenPrice, "Token price updated!");
		}
	}

	 
	 
	function setICOPrice(uint256 priceForIcoInWei) isOwner {
		require(priceForIcoInWei > 0);
		require(icoPrice != priceForIcoInWei);
		icoPrice = priceForIcoInWei;
		updatePrices();
	}

	

	 
	 
	function setSellRate(uint256 priceInWei) isOwner {
		require(priceInWei >= 0);
		sellRate = priceInWei;
	}
	
	 
	 
	function setCommissionRate(uint256 commissionRateInWei) isOwner {
		require(commissionRateInWei >= 0);
		commissionRate = commissionRateInWei;
	}
	
	 
	 
	function setDolRate(uint256 dolInWei) isOwner {
		require(dolInWei >= 0);
		dolRate = dolInWei;
	}
	
	 
	 
	function setEthRate(uint256 ethInWei) isOwner {
		require(ethInWei >= 0);
		ethRate = ethInWei;
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
		tokenCreated(msg.sender, amount, "Additional tokens created!");
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
		tokenDestroyed(msg.sender, amount, "An amount of tokens destroyed!");
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