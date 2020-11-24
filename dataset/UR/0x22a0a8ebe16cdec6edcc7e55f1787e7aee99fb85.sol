 

pragma solidity ^0.4.25;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract SuperTrust {
	 
	address public admin = msg.sender;
	uint256 public round = 0;
	uint256 public payoutFee;
	uint256 public goldBonus;
	uint256 public referralBonus;
	uint256 public investorGain;
	uint256 public bonusInterval;
	uint256 public bonusThreshold;
	uint256 public advPrice;
	uint256 public investorCount;
	uint256 public avgMinedPerDay;
	uint256 public collectedFee = 0;
	bool public lastRound = false; 
     
	mapping(uint256 => mapping(address => Investor)) private investors;
	mapping(uint256 => mapping(address => address)) private referrals;
	address[2] private board;
	uint256 private roulett;

	struct Investor {
		uint256 deposit;
		uint256 block;
		uint256 refBalance;
		bool banned;
	}

	function globalReinitialization() private {
		payoutFee = 3;
		goldBonus = 3;
		referralBonus = 3;
		investorGain = 4;
		bonusInterval = 5;
		bonusThreshold = 0.05 ether;
		advPrice = 0.15 ether;
		investorCount = 0;
		avgMinedPerDay = 5900;
		board = [admin, admin];
		roulett = bonusInterval * board.length;
	}

	constructor () public {
		globalReinitialization();
	}

	 
	 
	 

	event LogAdminRetired(address, address, address);
	event LogPayoutFeeChanged(address, uint256, uint256);
	event LogGoldBonusChanged(address, uint256, uint256);
	event LogReferralBonusChanged(address, uint256, uint256);
	event LogInvestorGainChanged(address, uint256, uint256);
	event LogBonusIntervalChanged(address, uint256, uint256);
	event LogBonusThresholdChanged(address, uint256, uint256);
	event LogAdvPriceChanged(address, uint256, uint256);
	event LogAvgMinedPerDayChanged(address, uint256, uint256);
	event LogReferrerBanned(address, address, string);

	modifier asAdmin {
		require(msg.sender == admin, "unauthorized function call");
		_;
	}

	function retireAdmin(address newAdmin) public asAdmin {
		emit LogAdminRetired(msg.sender, admin, newAdmin);
		admin = newAdmin;
	}

	function setPayoutFee(uint256 newValue) public asAdmin {
		 
		require((newValue > 0) && (newValue <= 10));
		emit LogPayoutFeeChanged(msg.sender, payoutFee, newValue);
		payoutFee = newValue;
	}

	function setGoldBonus(uint256 newValue) public asAdmin {
		require((newValue > 0) && (newValue <= 10));
		emit LogGoldBonusChanged(msg.sender, goldBonus, newValue);
		goldBonus = newValue;
	}

	function setReferralBonus(uint256 newValue) public asAdmin {
		require((newValue > 0) && (newValue <= 10));
		emit LogReferralBonusChanged(msg.sender, referralBonus, newValue);
		referralBonus = newValue;
	}

	function setInvestorGain(uint256 newValue) public asAdmin {
		require((newValue > 0) && (newValue <= 5));
		emit LogInvestorGainChanged(msg.sender, investorGain, newValue);
		investorGain = newValue;
	}

	function setBonusInterval(uint256 newValue) public asAdmin {
		require(newValue > 0);
		emit LogBonusIntervalChanged(msg.sender, bonusInterval, newValue);
		bonusInterval = newValue;
		roulett = bonusInterval * board.length;
	}

	function setBonusThreshold(uint256 newValue) public asAdmin {
		emit LogBonusThresholdChanged(msg.sender, bonusThreshold, newValue);
		bonusThreshold = newValue;
	}

	function setAdvPrice(uint256 newValue) public asAdmin {
		emit LogAdvPriceChanged(msg.sender, advPrice, newValue);
		advPrice = newValue;
	}

	function setAvgMinedPerDay(uint256 newValue) public asAdmin {
		require(newValue >= 4000);
		emit LogAvgMinedPerDayChanged(msg.sender, avgMinedPerDay, newValue);
		avgMinedPerDay = newValue;
	}

	function collectFee(uint256 percent) public asAdmin {
		require(percent <= 100);
		uint256 amount = (collectedFee * percent) / 100;
		require(amount <= collectedFee);
		collectedFee -= amount;
		admin.transfer(amount);
	}

	function banReferrer(address target) public asAdmin {
		require(target != admin);
		emit LogReferrerBanned(msg.sender, target, "Violating referrer banned");
		investors[round][target].banned = true;
		board[1] = admin;  
	}

	function unbanReferrer(address target) public asAdmin {
		require(target != admin);
		emit LogReferrerBanned(msg.sender, target, "Referrer unbanned");
		investors[round][target].banned = false;
	}

	 
	 
	 

	event LogGoldBonus(address, address, uint256);
	event LogReferralBonus(address, address, uint256);
	event LogAdvertisement(address, address, uint256);
	event LogNewInvestor(address, uint256);
	event LogRoundEnd(address, uint256, uint256, uint256);
	event LogBoardChange(address, uint256, string);

	function payoutBonuses() private {
		 
		roulett--;
		if (roulett % bonusInterval == 0) {
			uint256 bonusAmount = (msg.value * goldBonus) / 100;
			uint256 winnIdx = roulett / bonusInterval;
			if ((board[winnIdx] != msg.sender) && (board[winnIdx] != admin)) {
				 
				emit LogGoldBonus(msg.sender, board[winnIdx], bonusAmount);
				payoutBalanceCheck(board[winnIdx], bonusAmount);
			}
		}
		if (roulett == 0)
			roulett = bonusInterval * board.length;
	}

	function payoutReferrer() private {
		uint256 bonusAmount = (msg.value * referralBonus) / 100;
		address referrer = referrals[round][msg.sender];
		if (!investors[round][referrer].banned) {
			if (referrer != admin)
				investors[round][referrer].refBalance += bonusAmount;
			emit LogReferralBonus(msg.sender, referrer, bonusAmount);
			updateGoldReferrer(referrer);
			payoutBalanceCheck(referrer, bonusAmount);
		}
	}

	function payoutBalanceCheck(address to, uint256 value) private {
		if (to == admin) {
			collectedFee += value;
			return;
		}
		if (value > (address(this).balance - 0.01 ether)) {
			if (lastRound)
				selfdestruct(admin);
			emit LogRoundEnd(msg.sender, value, address(this).balance, round);
			globalReinitialization();
			round++;
			return;
		}
		to.transfer(value);
	}

	function processDividends() private {
		if (investors[round][msg.sender].deposit != 0) {
			 
			uint256 deposit = investors[round][msg.sender].deposit;
			uint256 previousBlock = investors[round][msg.sender].block;
			uint256 minedBlocks = block.number - previousBlock;
			uint256 dailyIncome = (deposit * investorGain) / 100;
			uint256 divsAmount = (dailyIncome * minedBlocks) / avgMinedPerDay;
			collectedFee += (divsAmount * payoutFee) / 100;
			payoutBalanceCheck(msg.sender, divsAmount);	
		}
		else if (msg.value != 0) {
			emit LogNewInvestor(msg.sender, ++investorCount);
		}
		investors[round][msg.sender].block = block.number;
		investors[round][msg.sender].deposit += msg.value;
	}

	function updateGoldInvestor(address candidate) private {
		uint256 candidateDeposit = investors[round][candidate].deposit;
		if (candidateDeposit > investors[round][board[0]].deposit) {
			board[0] = candidate;
			emit LogBoardChange(candidate, candidateDeposit,
				"Congrats! New Gold Investor!");
		}
	}

	function updateGoldReferrer(address candidate) private {
		 
		if ((candidate != admin) && (!investors[round][candidate].banned)) {
			uint256 candidateRefBalance = investors[round][candidate].refBalance;
			uint256 goldReferrerBalance = investors[round][board[1]].refBalance;
			if (candidateRefBalance > goldReferrerBalance) {
				board[1] = candidate;
				emit LogBoardChange(candidate, candidateRefBalance,
					"Congrats! New Gold Referrer!");
			}
		}
	}

	function regularPayment() private {
		if (msg.value >= bonusThreshold) {
			payoutBonuses();
			if (referrals[round][msg.sender] != 0)
				payoutReferrer();
		}
		processDividends();
		updateGoldInvestor(msg.sender);
	}

	function advertise(address targetAddress) external payable {
		 
		if (investors[round][msg.sender].banned)
			revert("You are violating the rules and banned");
		if ((msg.sender != admin) && (msg.value < advPrice))
			revert("Need more ETH to make an advertiement");
		if (investors[round][targetAddress].deposit != 0)
			revert("Advertising address is already an investor");
		if (referrals[round][targetAddress] != 0)
			revert("Address already advertised");

		emit LogAdvertisement(msg.sender, targetAddress, msg.value);
		referrals[round][targetAddress] = msg.sender;
		targetAddress.transfer(1 wei);
		regularPayment();
	}

	function () external payable {
		regularPayment();
	} 
}