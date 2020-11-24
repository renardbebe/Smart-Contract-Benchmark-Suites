 

 

pragma solidity ^0.4.15;

contract token {
	function transferFrom(address sender, address receiver, uint amount) returns(bool success) {}

	function burn() {}
	
	function setStart(uint newStart) {}
}

contract SafeMath {
	 

	function safeMul(uint a, uint b) internal returns(uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function safeSub(uint a, uint b) internal returns(uint) {
		assert(b <= a);
		return a - b;
	}

	function safeAdd(uint a, uint b) internal returns(uint) {
		uint c = a + b;
		assert(c >= a && c >= b);
		return c;
	}

}


contract Crowdsale is SafeMath {
	 
	address public tokenOwner;
	 
	uint constant public fundingGoal = 672000000000;
	 
	uint constant public softCap = 6720000000000;
	 
	uint constant public maxGoal = 20120000000000;
	 
	uint public amountRaised;
	 
	uint public start;
	 
	uint public end;
	 
	uint public timeAfterSoftCap;
	 
	uint public tokensSold = 0;
	 
	uint constant public rateSoft = 24;
	uint constant public rateHard = 20;

	uint constant public rateCoefficient = 100000000000;
	 
	token public tokenReward;
	 
	mapping(address => uint) public balanceOf;
	 
	bool public crowdsaleClosed = false;
	 
	address msWallet;
	 
	event GoalReached(address _tokenOwner, uint _amountRaised);
	event FundTransfer(address backer, uint amount, bool isContribution, uint _amountRaised);



	 
	function Crowdsale(
		address _tokenAddr, 
		address _walletAddr, 
		address _tokenOwner, 
		uint _start, 
		uint _end,
		uint _timeAfterSoftCap) {
		tokenReward = token(_tokenAddr);
		msWallet = _walletAddr;
		tokenOwner = _tokenOwner;

		require(_start < _end);
		start = _start;
		end = _end;
		timeAfterSoftCap = _timeAfterSoftCap;
	}

	 
	function() payable {
		if (msg.sender != msWallet)  
			invest(msg.sender);
	}

	 
	function invest(address _receiver) payable {
		uint amount = msg.value;
		var (numTokens, reachedSoftCap) = getNumTokens(amount);
		require(numTokens>0);
		require(!crowdsaleClosed && now >= start && now <= end && safeAdd(tokensSold, numTokens) <= maxGoal);
		msWallet.transfer(amount);
		balanceOf[_receiver] = safeAdd(balanceOf[_receiver], amount);
		amountRaised = safeAdd(amountRaised, amount);
		tokensSold += numTokens;
		assert(tokenReward.transferFrom(tokenOwner, _receiver, numTokens));
		FundTransfer(_receiver, amount, true, amountRaised);
		if (reachedSoftCap) {
			uint newEnd = now + timeAfterSoftCap;
			if (newEnd < end) {
				end = newEnd;
				tokenReward.setStart(newEnd);
			} 
		}
	}
	
	function getNumTokens(uint _value) constant returns(uint numTokens, bool reachedSoftCap) {
		if (tokensSold < softCap) {
			numTokens = safeMul(_value,rateSoft)/rateCoefficient;
			if (safeAdd(tokensSold,numTokens) < softCap) 
				return (numTokens, false);
			else if (safeAdd(tokensSold,numTokens) == softCap) 
				return (numTokens, true);
			else {
				numTokens = safeSub(softCap, tokensSold);
				uint missing = safeSub(_value, safeMul(numTokens,rateCoefficient)/rateSoft);
				return (safeAdd(numTokens, safeMul(missing,rateHard)/rateCoefficient), true);
			}
		} 
		else 
			return (safeMul(_value,rateHard)/rateCoefficient, false);
	}

	modifier afterDeadline() {
		if (now > end) 
			_;
	}

	 
	function checkGoalReached() afterDeadline {
		require(msg.sender == tokenOwner);

		if (tokensSold >= fundingGoal) {
			tokenReward.burn();  
			GoalReached(tokenOwner, amountRaised);
		}
		crowdsaleClosed = true;
	}

	 
	function safeWithdrawal() afterDeadline {
		uint amount = balanceOf[msg.sender];
		if (address(this).balance >= amount) {
			balanceOf[msg.sender] = 0;
			if (amount > 0) {
				msg.sender.transfer(amount);
				FundTransfer(msg.sender, amount, false, amountRaised);
			}
		}
	}

}