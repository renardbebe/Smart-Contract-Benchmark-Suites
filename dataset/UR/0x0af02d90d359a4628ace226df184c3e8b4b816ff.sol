 

 
 

pragma solidity ^0.4.21;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract EOSBetGameInterface {
	uint256 public DEVELOPERSFUND;
	uint256 public LIABILITIES;
	function payDevelopersFund(address developer) public;
	function receivePaymentForOraclize() payable public;
	function getMaxWin() public view returns(uint256);
}

contract EOSBetBankrollInterface {
	function payEtherToWinner(uint256 amtEther, address winner) public;
	function receiveEtherFromGameAddress() payable public;
	function payOraclize(uint256 amountToPay) public;
	function getBankroll() public view returns(uint256);
}

contract ERC20 {
	function totalSupply() constant public returns (uint supply);
	function balanceOf(address _owner) constant public returns (uint balance);
	function transfer(address _to, uint _value) public returns (bool success);
	function transferFrom(address _from, address _to, uint _value) public returns (bool success);
	function approve(address _spender, uint _value) public returns (bool success);
	function allowance(address _owner, address _spender) constant public returns (uint remaining);
	event Transfer(address indexed _from, address indexed _to, uint _value);
	event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract EOSBetBankroll is ERC20, EOSBetBankrollInterface {

	using SafeMath for *;

	 

	address public OWNER;
	uint256 public MAXIMUMINVESTMENTSALLOWED;
	uint256 public WAITTIMEUNTILWITHDRAWORTRANSFER;
	uint256 public DEVELOPERSFUND;

	 
	 
	 
	 
	mapping(address => bool) public TRUSTEDADDRESSES;

	address public DICE;
	address public SLOTS;

	 
	mapping(address => uint256) contributionTime;

	 
	string public constant name = "EOSBet Stake Tokens";
	string public constant symbol = "EOSBETST";
	uint8 public constant decimals = 18;
	 
	uint256 public totalSupply;

	 
	mapping(address => uint256) public balances;
	mapping(address => mapping(address => uint256)) public allowed;

	 
	event FundBankroll(address contributor, uint256 etherContributed, uint256 tokensReceived);
	event CashOut(address contributor, uint256 etherWithdrawn, uint256 tokensCashedIn);
	event FailedSend(address sendTo, uint256 amt);

	 
	modifier addressInTrustedAddresses(address thisAddress){

		require(TRUSTEDADDRESSES[thisAddress]);
		_;
	}

	 
	function EOSBetBankroll(address dice, address slots) public payable {
		 
		 
		require (msg.value > 0);

		OWNER = msg.sender;

		 
		uint256 initialTokens = msg.value * 100;
		balances[msg.sender] = initialTokens;
		totalSupply = initialTokens;

		 
		emit Transfer(0x0, msg.sender, initialTokens);

		 
		TRUSTEDADDRESSES[dice] = true;
		TRUSTEDADDRESSES[slots] = true;

		DICE = dice;
		SLOTS = slots;

		 
		 
		 
		WAITTIMEUNTILWITHDRAWORTRANSFER = 0 seconds;
		MAXIMUMINVESTMENTSALLOWED = 500 ether;
	}

	 
	 
	 

	function checkWhenContributorCanTransferOrWithdraw(address bankrollerAddress) view public returns(uint256){
		return contributionTime[bankrollerAddress];
	}

	function getBankroll() view public returns(uint256){
		 
		return SafeMath.sub(address(this).balance, DEVELOPERSFUND);
	}

	 
	 
	 

	function payEtherToWinner(uint256 amtEther, address winner) public addressInTrustedAddresses(msg.sender){
		 
		 
		 
		 
		 
		 
		 

		if (! winner.send(amtEther)){

			emit FailedSend(winner, amtEther);

			if (! OWNER.send(amtEther)){

				emit FailedSend(OWNER, amtEther);
			}
		}
	}

	function receiveEtherFromGameAddress() payable public addressInTrustedAddresses(msg.sender){
		 
	}

	function payOraclize(uint256 amountToPay) public addressInTrustedAddresses(msg.sender){
		 
		EOSBetGameInterface(msg.sender).receivePaymentForOraclize.value(amountToPay)();
	}

	 
	 
	 


	 
	 
	 
	 
	function () public payable {

		 
		 
		uint256 currentTotalBankroll = SafeMath.sub(getBankroll(), msg.value);
		uint256 maxInvestmentsAllowed = MAXIMUMINVESTMENTSALLOWED;

		require(currentTotalBankroll < maxInvestmentsAllowed && msg.value != 0);

		uint256 currentSupplyOfTokens = totalSupply;
		uint256 contributedEther;

		bool contributionTakesBankrollOverLimit;
		uint256 ifContributionTakesBankrollOverLimit_Refund;

		uint256 creditedTokens;

		if (SafeMath.add(currentTotalBankroll, msg.value) > maxInvestmentsAllowed){
			 
			contributionTakesBankrollOverLimit = true;
			 
			contributedEther = SafeMath.sub(maxInvestmentsAllowed, currentTotalBankroll);
			 
			ifContributionTakesBankrollOverLimit_Refund = SafeMath.sub(msg.value, contributedEther);
		}
		else {
			contributedEther = msg.value;
		}
        
		if (currentSupplyOfTokens != 0){
			 
			creditedTokens = SafeMath.mul(contributedEther, currentSupplyOfTokens) / currentTotalBankroll;
		}
		else {
			 
			 
			 
			 
			creditedTokens = SafeMath.mul(contributedEther, 100);
		}
		
		 
		totalSupply = SafeMath.add(currentSupplyOfTokens, creditedTokens);

		 
		balances[msg.sender] = SafeMath.add(balances[msg.sender], creditedTokens);

		 
		contributionTime[msg.sender] = block.timestamp;

		 
		 
		if (contributionTakesBankrollOverLimit){
			msg.sender.transfer(ifContributionTakesBankrollOverLimit_Refund);
		}

		 
		emit FundBankroll(msg.sender, contributedEther, creditedTokens);

		 
		emit Transfer(0x0, msg.sender, creditedTokens);
	}

	function cashoutEOSBetStakeTokens(uint256 _amountTokens) public {
		 
		 
		 
		 
		 
		 

		 
		uint256 tokenBalance = balances[msg.sender];
		 
		require(_amountTokens <= tokenBalance 
			&& contributionTime[msg.sender] + WAITTIMEUNTILWITHDRAWORTRANSFER <= block.timestamp
			&& _amountTokens > 0);

		 
		 
		uint256 currentTotalBankroll = getBankroll();
		uint256 currentSupplyOfTokens = totalSupply;

		 
		uint256 withdrawEther = SafeMath.mul(_amountTokens, currentTotalBankroll) / currentSupplyOfTokens;

		 
		uint256 developersCut = withdrawEther / 100;
		uint256 contributorAmount = SafeMath.sub(withdrawEther, developersCut);

		 
		totalSupply = SafeMath.sub(currentSupplyOfTokens, _amountTokens);

		 
		balances[msg.sender] = SafeMath.sub(tokenBalance, _amountTokens);

		 
		DEVELOPERSFUND = SafeMath.add(DEVELOPERSFUND, developersCut);

		 
		msg.sender.transfer(contributorAmount);

		 
		emit CashOut(msg.sender, contributorAmount, _amountTokens);

		 
		emit Transfer(msg.sender, 0x0, _amountTokens);
	}

	 
	function cashoutEOSBetStakeTokens_ALL() public {

		 
		cashoutEOSBetStakeTokens(balances[msg.sender]);
	}

	 
	 
	 
	 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 

	function transferOwnership(address newOwner) public {
		require(msg.sender == OWNER);

		OWNER = newOwner;
	}

	function changeWaitTimeUntilWithdrawOrTransfer(uint256 waitTime) public {
		 
		require (msg.sender == OWNER && waitTime <= 6048000);

		WAITTIMEUNTILWITHDRAWORTRANSFER = waitTime;
	}

	function changeMaximumInvestmentsAllowed(uint256 maxAmount) public {
		require(msg.sender == OWNER);

		MAXIMUMINVESTMENTSALLOWED = maxAmount;
	}


	function withdrawDevelopersFund(address receiver) public {
		require(msg.sender == OWNER);

		 
        EOSBetGameInterface(DICE).payDevelopersFund(receiver);
		EOSBetGameInterface(SLOTS).payDevelopersFund(receiver);

		 
		uint256 developersFund = DEVELOPERSFUND;

		 
		DEVELOPERSFUND = 0;

		 
		receiver.transfer(developersFund);
	}

	 
	function emergencySelfDestruct() public {
		require(msg.sender == OWNER);

		selfdestruct(msg.sender);
	}

	 
	 
	 

	function totalSupply() constant public returns(uint){
		return totalSupply;
	}

	function balanceOf(address _owner) constant public returns(uint){
		return balances[_owner];
	}

	 
	 
	function transfer(address _to, uint256 _value) public returns (bool success){
		if (balances[msg.sender] >= _value 
			&& _value > 0 
			&& contributionTime[msg.sender] + WAITTIMEUNTILWITHDRAWORTRANSFER <= block.timestamp
			&& _to != address(this)){

			 
			balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
			balances[_to] = SafeMath.add(balances[_to], _value);

			 
			emit Transfer(msg.sender, _to, _value);
			return true;
		}
		else {
			return false;
		}
	}

	 
	 
	function transferFrom(address _from, address _to, uint _value) public returns(bool){
		if (allowed[_from][msg.sender] >= _value 
			&& balances[_from] >= _value 
			&& _value > 0 
			&& contributionTime[_from] + WAITTIMEUNTILWITHDRAWORTRANSFER <= block.timestamp
			&& _to != address(this)){

			 
			balances[_to] = SafeMath.add(balances[_to], _value);
	   		balances[_from] = SafeMath.sub(balances[_from], _value);
	  		allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);

	  		 
    		emit Transfer(_from, _to, _value);
    		return true;
   		} 
    	else { 
    		return false;
    	}
	}
	
	function approve(address _spender, uint _value) public returns(bool){
		if(_value > 0){

			allowed[msg.sender][_spender] = _value;
			emit Approval(msg.sender, _spender, _value);
			 
			return true;
		}
		else {
			return false;
		}
	}
	
	function allowance(address _owner, address _spender) constant public returns(uint){
		return allowed[_owner][_spender];
	}
}