 

 

pragma solidity ^0.4.15;

 
library SafeMath {
	function mul(uint256 a, uint256 b) internal returns(uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}
	
	function div(uint256 a, uint256 b) internal returns(uint256) {
		uint256 c = a / b;
		return c;
	}

	function sub(uint256 a, uint256 b) internal returns(uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal returns(uint256) {
		uint256 c = a + b;
		assert(c >= a && c >= b);
		return c;
	}
}

 
contract XmasToken {
    
    using SafeMath for uint256; 
	
	 
	string constant public standard = "ERC20";
	string constant public symbol = "xmas";
	string constant public name = "XmasToken";
	uint8 constant public decimals = 18;
	
	 
	uint256 constant public initialSupply = 4000000 * 1 ether;
	uint256 constant public tokensForIco = 3000000 * 1 ether;
	uint256 constant public tokensForBonus = 1000000 * 1 ether;
	
	 
	uint256 constant public startAirdropTime = 1514073600;
	
	 
	uint256 public startTransferTime;
	
	 
	uint256 public tokensSold;

	 
	bool public burned;

	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;
	
	 
	
	 
	uint256 constant public start = 1510401600;
	
	 
	uint256 constant public end = 1512863999;

	 
	uint256 constant public tokenExchangeRate = 1000;
	
	 
	uint256 public amountRaised;

	 
	bool public crowdsaleClosed = false;

	 
	address public xmasFundWallet;
	
	 
	address ethFundWallet;
	
	 
	
	 
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed _owner, address indexed spender, uint256 value);
	event FundTransfer(address backer, uint amount, bool isContribution, uint _amountRaised);
	event Burn(uint256 amount);

	 
	function XmasToken(address _ethFundWallet) {
		ethFundWallet = _ethFundWallet;
		xmasFundWallet = msg.sender;
		balanceOf[xmasFundWallet] = initialSupply;
		startTransferTime = end;
	}
		
	 
	function() payable {
		uint256 amount = msg.value;
		uint256 numTokens = amount.mul(tokenExchangeRate); 
		require(numTokens >= 100 * 1 ether);
		require(!crowdsaleClosed && now >= start && now <= end && tokensSold.add(numTokens) <= tokensForIco);

		ethFundWallet.transfer(amount);
		
		balanceOf[xmasFundWallet] = balanceOf[xmasFundWallet].sub(numTokens); 
		balanceOf[msg.sender] = balanceOf[msg.sender].add(numTokens);

		Transfer(xmasFundWallet, msg.sender, numTokens);

		 
		amountRaised = amountRaised.add(amount);
		tokensSold += numTokens;

		FundTransfer(msg.sender, amount, true, amountRaised);
	}
	
	 
	function transfer(address _to, uint256 _value) returns(bool success) {
		require(now >= startTransferTime); 

		balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value); 
		balanceOf[_to] = balanceOf[_to].add(_value); 

		Transfer(msg.sender, _to, _value); 

		return true;
	}

	 
	function approve(address _spender, uint256 _value) returns(bool success) {
		require((_value == 0) || (allowance[msg.sender][_spender] == 0));

		allowance[msg.sender][_spender] = _value;

		Approval(msg.sender, _spender, _value);

		return true;
	}

	 
	function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
		if (now < startTransferTime) 
			require(_from == xmasFundWallet);
		var _allowance = allowance[_from][msg.sender];
		require(_value <= _allowance);
		
		balanceOf[_from] = balanceOf[_from].sub(_value); 
		balanceOf[_to] = balanceOf[_to].add(_value); 
		allowance[_from][msg.sender] = _allowance.sub(_value);

		Transfer(_from, _to, _value);

		return true;
	}
	
	 
	function burn() internal {
		require(now > startTransferTime);
		require(burned == false);
			
		uint256 difference = balanceOf[xmasFundWallet].sub(tokensForBonus);
		tokensSold = tokensForIco.sub(difference);
		balanceOf[xmasFundWallet] = tokensForBonus;
			
		burned = true;

		Burn(difference);
	}

	 
	function markCrowdsaleEnding() {
		require(now > end);

		burn(); 
		crowdsaleClosed = true;
	}
	
	 
	function sendGifts(address[] santaGiftList) returns(bool success)  {
		require(msg.sender == xmasFundWallet);
		require(now >= startAirdropTime);
	
		for(uint i = 0; i < santaGiftList.length; i++) {
		    uint256 tokensHold = balanceOf[santaGiftList[i]];
			if (tokensHold >= 100 * 1 ether) { 
				uint256 bonus = tokensForBonus.div(1 ether);
				uint256 giftTokens = ((tokensHold.mul(bonus)).div(tokensSold)) * 1 ether;
				transferFrom(xmasFundWallet, santaGiftList[i], giftTokens);
			}
		}
		
		return true;
	}
}