 

pragma solidity 0.4.25;

 

contract Contractum {
	using SafeMath for uint256;

	mapping (address => uint256) public userInvested;
	mapping (address => uint256) public userWithdrawn;
	mapping (address => uint256) public userLastOperationTime;
	mapping (address => uint256) public userLastWithdrawTime;

	uint256 constant public INVEST_MIN_AMOUNT = 10 finney;       
	uint256 constant public BASE_PERCENT = 40;                   
	uint256 constant public REFERRAL_PERCENT = 50;               
	uint256 constant public MARKETING_FEE = 70;                  
	uint256 constant public PROJECT_FEE = 50;                    
	uint256 constant public PERCENTS_DIVIDER = 1000;             
	uint256 constant public CONTRACT_BALANCE_STEP = 100 ether;   
	uint256 constant public TIME_STEP = 1 days;                  

	uint256 public totalInvested = 0;
	uint256 public totalWithdrawn = 0;

	address public marketingAddress = 0x9631Be3F285441Eb4d52480AAA227Fa9CdC75153;
	address public projectAddress = 0x53b9f206EabC211f1e60b3d98d532b819e182725;

	event addedInvest(address indexed user, uint256 amount);
	event payedDividends(address indexed user, uint256 dividend);
	event payedFees(address indexed user, uint256 amount);
	event payedReferrals(address indexed user, address indexed referrer, uint256 amount, uint256 refAmount);

	 
	function getContractBalanceRate() public view returns (uint256) {
		uint256 contractBalance = address(this).balance;
		uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP);
		return BASE_PERCENT.add(contractBalancePercent);
	}

	 
	function getUserPercentRate(address userAddress) public view returns (uint256) {
		uint256 contractBalanceRate = getContractBalanceRate();
		if (userInvested[userAddress] != 0) {
			uint256 timeMultiplier = now.sub(userLastWithdrawTime[userAddress]).div(TIME_STEP);
			return contractBalanceRate.add(timeMultiplier);
		} else {
			return contractBalanceRate;
		}
	}

	 
	function getUserDividends(address userAddress) public view returns (uint256) {
		uint256 userPercentRate = getUserPercentRate(userAddress);
		uint256 userPercents = userInvested[userAddress].mul(userPercentRate).div(PERCENTS_DIVIDER);
		uint256 timeDiff = now.sub(userLastOperationTime[userAddress]);
		uint256 userDividends = userPercents.mul(timeDiff).div(TIME_STEP);
		return userDividends;
	}

	 
	function addInvest() private {
		 
		if (userInvested[msg.sender] == 0) {
			userLastOperationTime[msg.sender] = now;
			userLastWithdrawTime[msg.sender] = now;
		 
		} else {
			payDividends();
		}

		 
		userInvested[msg.sender] += msg.value;
		emit addedInvest(msg.sender, msg.value);
		totalInvested = totalInvested.add(msg.value);

		 
		uint256 marketingFee = msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
		uint256 projectFee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		uint256 feeAmount = marketingFee.add(projectFee);
		marketingAddress.transfer(marketingFee);
		projectAddress.transfer(projectFee);
		emit payedFees(msg.sender, feeAmount);

		 
		address referrer = bytesToAddress(msg.data);
		if (referrer > 0x0 && referrer != msg.sender) {
			uint256 refAmount = msg.value.mul(REFERRAL_PERCENT).div(PERCENTS_DIVIDER);
			referrer.transfer(refAmount);
			emit payedReferrals(msg.sender, referrer, msg.value, refAmount);
		}
	}

	 
	function payDividends() private {
		require(userInvested[msg.sender] != 0);

		uint256 contractBalance = address(this).balance;
		uint256 percentsAmount = getUserDividends(msg.sender);

		 
		if (contractBalance >= percentsAmount) {
			msg.sender.transfer(percentsAmount);
			userWithdrawn[msg.sender] += percentsAmount;
			emit payedDividends(msg.sender, percentsAmount);
			totalWithdrawn = totalWithdrawn.add(percentsAmount);
		 
		} else {
			msg.sender.transfer(contractBalance);
			userWithdrawn[msg.sender] += contractBalance;
			emit payedDividends(msg.sender, contractBalance);
			totalWithdrawn = totalWithdrawn.add(contractBalance);
		}

		userLastOperationTime[msg.sender] = now;
	}

	function() external payable {
		if (msg.value >= INVEST_MIN_AMOUNT) {
			addInvest();
		} else {
			payDividends();

			 
			userLastWithdrawTime[msg.sender] = now;
		}
	}

	function bytesToAddress(bytes data) private pure returns (address addr) {
		assembly {
			addr := mload(add(data, 20))
		}
	}
}

 
library SafeMath {

	 
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		 
		 
		 
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b);

		return c;
	}

	 
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0);  
		uint256 c = a / b;
		 

		return c;
	}

	 
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a);
		uint256 c = a - b;

		return c;
	}

	 
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a);

		return c;
	}
}