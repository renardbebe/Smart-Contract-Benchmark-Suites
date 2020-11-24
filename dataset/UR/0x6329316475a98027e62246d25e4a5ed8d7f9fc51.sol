 

contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
   
   
   
  modifier onlyPayloadSize(uint numWords) {
     assert(msg.data.length >= numWords * 32 + 4);
     _;
  }
}
contract Token {  
		function balanceOf(address _owner) public  view returns (uint256 balance);
		function transfer(address _to, uint256 _value) public  returns (bool success);
		function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);
		function approve(address _spender, uint256 _value)  returns (bool success);
		function allowance(address _owner, address _spender) public  view returns (uint256 remaining);
		event Transfer(address indexed _from, address indexed _to, uint256 _value);
		event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	}	
contract STC is Token{
	Price public currentPrice;
	uint256 public fundingEndTime;
	address public fundWallet;
	function() payable {
			require(tx.origin == msg.sender);
			buyTo(msg.sender);
	}
	function buyTo(address participant) public payable; 
	function icoDenominatorPrice() public view returns (uint256);
	struct Price {  
			uint256 numerator;
			uint256 denominator;
	}
}	
contract STCDR is Token{
	 
}	
contract OwnerControl is SafeMath {
	bool public halted = false;
	address public controlWallet;	
	 
	event AddLiquidity(uint256 ethAmount);
	event RemoveLiquidity(uint256 ethAmount);
	 
	modifier onlyControlWallet {
			require(msg.sender == controlWallet);
			_;
	}
	 
	function addLiquidity() external onlyControlWallet payable {
			require(msg.value > 0);
			AddLiquidity(msg.value);
	}
	 
	function removeLiquidity(uint256 amount) external onlyControlWallet {
			require(amount <= this.balance);
			controlWallet.transfer(amount);
			RemoveLiquidity(amount);
	}
	function changeControlWallet(address newControlWallet) external onlyControlWallet {
			require(newControlWallet != address(0));
			controlWallet = newControlWallet;
	}
	function halt() external onlyControlWallet {
			halted = true;
	}
	function unhalt() external onlyControlWallet {
			halted = false;
	}
	function claimTokens(address _token) external onlyControlWallet {
			require(_token != address(0));
			Token token = Token(_token);
			uint256 balance = token.balanceOf(this);
			token.transfer(controlWallet, balance);
	}
	
}
contract SWAP is OwnerControl {
	string public name = "SWAP STCDR-STC";	
	STC public STCToken;
	STCDR public STCDRToken;
	uint256 public discount = 5;
	uint256 public stcdr2stc_Ratio = 40;
	 
	 event TokenSwaped(address indexed _from,  uint256 _stcBuy, uint256 _stcBonus, uint256 _stcdrBurn, uint256 _ethPrice, uint256 _stcPrice);
	 
	 
	function SWAP(address _STCToken,address _STCDRToken) public  {
			controlWallet = msg.sender;
			STCToken = STC(_STCToken);
			STCDRToken = STCDR(_STCDRToken);
	}	
	function() payable {
			require(tx.origin == msg.sender);
			buyTo(msg.sender);
	}
	function transferTokensAfterEndTime(address participant, uint256 _tokens ,uint256 _tokenBonus , uint256 _tokensToBurn) private
	{
		require(this.balance>=msg.value);
		 
		require(availableSTCTokens() > safeAdd(_tokens,_tokenBonus));
		 
		STCDRToken.transferFrom(participant,this,_tokensToBurn);
		STCDRToken.transfer(controlWallet, _tokensToBurn);
		 
		STCToken.transferFrom(controlWallet,this,safeAdd(_tokens,_tokenBonus));
		STCToken.transfer(participant, _tokens);
		STCToken.transfer(participant, _tokenBonus);
		 
		STCToken.fundWallet().transfer(msg.value);
	}
	function addEthBonusToBuy(address participant, uint256 _ethBonus , uint256 _tokensToBurn ) private {
		 
		require(this.balance>=safeAdd(msg.value, _ethBonus));	
	     
		STCDRToken.transferFrom(participant,this,_tokensToBurn);
		STCDRToken.transfer(controlWallet, _tokensToBurn);
		 
		STCToken.buyTo.value(safeAdd(msg.value, _ethBonus))(participant);
	}
	function buyTo(address participant) public payable {
		require(!halted);		
		require(msg.value > 0);
		
		 
		uint256 availableTokenSTCDR = availableSTCDRTokensOF(participant);
		require(availableTokenSTCDR > 0);
		 
		uint256 _numerator = currentETHPrice();
		require(_numerator > 0);
		 
		uint256 _fundingEndTime = STCToken.fundingEndTime();
		 
		uint256 _denominator = currentSTCPrice();	
		require(_denominator > 0);	
		 
		uint256 _stcMaxBonus = safeMul(availableTokenSTCDR,10000000000) / stcdr2stc_Ratio;  
		require(_stcMaxBonus > 0);
		 
		uint256 _stcOrginalBuy = safeMul(msg.value,_numerator) / _denominator;  
		require(_stcOrginalBuy > 0);
		
		uint256 _tokensToBurn =0 ;
		uint256 _tokensBonus =0 ;
		if (_stcOrginalBuy >= _stcMaxBonus){
			_tokensToBurn =  availableTokenSTCDR;
			_tokensBonus= safeSub(safeMul((_stcMaxBonus / safeSub(100,discount)),100),_stcMaxBonus);  
		} else {
			_tokensToBurn = safeMul(_stcOrginalBuy,stcdr2stc_Ratio)/10000000000;	
			_tokensBonus =  safeSub(safeMul((_stcOrginalBuy / safeSub(100,discount)),100),_stcOrginalBuy);   
		} 
		require(_tokensToBurn > 0);
		require(_tokensBonus > 0);
		require(_tokensBonus < _stcOrginalBuy);
		
		if (now < _fundingEndTime) {
			 
			 
			uint256 _ethBonus=safeMul(_tokensBonus, _denominator) / _numerator ;
			addEthBonusToBuy(participant,_ethBonus,_tokensToBurn);
		 
		} else {
			 
			transferTokensAfterEndTime(participant,_stcOrginalBuy,_tokensBonus ,_tokensToBurn);
			 
		}

	TokenSwaped(participant,  _stcOrginalBuy , _tokensBonus,_tokensToBurn, _numerator ,_denominator);
	}	
	function currentETHPrice() public view returns (uint256 numerator)
	{
		var (a, b) = STCToken.currentPrice();
		return STC.Price(a, b).numerator;
	}	
	function currentSTCPrice() public view returns (uint256 numerator)
	{
		return STCToken.icoDenominatorPrice();
	}
	 
	function tokenSTCDRforBurnInControlWallett() view returns (uint256 numerator) {
		return  STCDRToken.balanceOf(controlWallet);
	}
	 
	function availableSTCDRTokensOF(address _owner) view returns (uint256 numerator) {
		uint256 alowedTokenSTCDR = STCDRToken.allowance(_owner, this);
		uint256 balanceTokenSTCDR = STCDRToken.balanceOf(_owner);
		if (alowedTokenSTCDR>balanceTokenSTCDR) {
			return balanceTokenSTCDR;	
		} else {
			return alowedTokenSTCDR;
		}
	}
	 
	function availableSTCTokens() view returns (uint256 numerator) {
		uint256 alowedTokenSTC = STCToken.allowance(controlWallet, this);
		uint256 balanceTokenSTC = STCToken.balanceOf(controlWallet);
		if (alowedTokenSTC>balanceTokenSTC) {
			return balanceTokenSTC;	
		} else {
			return alowedTokenSTC;
		}
	}

}