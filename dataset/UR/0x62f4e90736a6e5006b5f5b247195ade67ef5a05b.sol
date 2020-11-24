 

pragma solidity ^0.5.0;
 

 

interface ERC20interface {
	function transfer(address to, uint value) external returns(bool success);
	function approve(address spender, uint tokens) external returns(bool success);
	function transferFrom(address from, address to, uint tokens) external returns(bool success);

	function allowance(address tokenOwner, address spender) external view returns(uint remaining);
	function balanceOf(address tokenOwner) external view returns(uint balance);
}

interface ERC223interface {
	function transfer(address to, uint value) external returns(bool ok);
	function transfer(address to, uint value, bytes calldata data) external returns(bool ok);
	function transfer(address to, uint value, bytes calldata data, string calldata customFallback) external returns(bool ok);

	function balanceOf(address who) external view returns(uint);
}

 
interface ERC223Handler {
	function tokenFallback(address _from, uint _value, bytes calldata _data) external;
}

 
interface ExternalGauntletInterface {
	function gauntletRequirement(address wearer, uint256 oldAmount, uint256 newAmount) external returns(bool);
	function gauntletRemovable(address wearer) external view returns(bool);
}

 
interface Hourglass {
	function decimals() external view returns(uint8);
	function stakingRequirement() external view returns(uint256);
	function balanceOf(address tokenOwner) external view returns(uint);
	function dividendsOf(address tokenOwner) external view returns(uint);
	function calculateTokensReceived(uint256 _ethereumToSpend) external view returns(uint256);
	function calculateEthereumReceived(uint256 _tokensToSell) external view returns(uint256);
	function myTokens() external view returns(uint256);
	function myDividends(bool _includeReferralBonus) external view returns(uint256);
	function totalSupply() external view returns(uint256);

	function transfer(address to, uint value) external returns(bool);
	function buy(address referrer) external payable returns(uint256);
	function sell(uint256 amount) external;
	function withdraw() external;
}

 
interface TeamJustPlayerBook {
	function pIDxName_(bytes32 name) external view returns(uint256);
	function pIDxAddr_(address addr) external view returns(uint256);
	function getPlayerAddr(uint256 pID) external view returns(address);
}

 
 
 
 

 

contract HourglassXReferralHandler {
	using SafeMath for uint256;
	using SafeMath for uint;
	address internal parent;
	Hourglass internal hourglass;

	constructor(Hourglass h) public {
		hourglass = h;
		parent = msg.sender;
	}

	 
	modifier onlyParent {
		require(msg.sender == parent, "Can only be executed by parent process");
		_;
	}

	 
	function totalBalance() public view returns(uint256) {
		return address(this).balance + hourglass.myDividends(true);
	}

	 
	function buyTokens(address referrer) public payable onlyParent {
		hourglass.buy.value(msg.value)(referrer);
	}

	 
	function buyTokensFromBalance(address referrer, uint256 amount) public onlyParent {
		if (address(this).balance < amount) {
			hourglass.withdraw();
		}
		hourglass.buy.value(amount)(referrer);
	}

	 
	function sellTokens(uint256 amount) public onlyParent {
		if (amount > 0) {
			hourglass.sell(amount);
		}
	}

	 
	function withdrawDivs() public onlyParent {
		hourglass.withdraw();
	}

	 
	function sendETH(address payable to, uint256 amount) public onlyParent {
		if (address(this).balance < amount) {
			hourglass.withdraw();
		}
		to.transfer(amount);
	}

	 
	function() payable external {
		require(msg.sender == address(hourglass) || msg.sender == parent, "No, I don't accept donations");
	}

	 
	function tokenFallback(address from, uint value, bytes memory data) public pure {
		revert("I don't want your shitcoins!");
	}

	 
	function takeShitcoin(address shitCoin) public {
		require(shitCoin != address(hourglass), "P3D isn't a shitcoin");
		ERC20interface s = ERC20interface(shitCoin);
		s.transfer(msg.sender, s.balanceOf(address(this)));
	}
}

contract HourglassX {
	using SafeMath for uint256;
	using SafeMath for uint;
	using SafeMath for int256;

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	modifier playerBookEnabled {
		require(address(playerBook) != NULL_ADDRESS, "named referrals not enabled");
		_;
	}

	 
	constructor(address h, address p) public {
		 
		name = "PoWH3D Extended";
		symbol = "P3X";
		decimals = 18;
		totalSupply = 0;

		 
		hourglass = Hourglass(h);
		playerBook = TeamJustPlayerBook(p);

		 
		referralRequirement = hourglass.stakingRequirement();

		 
		refHandler = new HourglassXReferralHandler(hourglass);

		 
		ignoreTokenFallbackEnable = false;
		owner = msg.sender;
	}
	 
	address owner;
	address newOwner;

	uint256 referralRequirement;
	uint256 internal profitPerShare = 0;
	uint256 public lastTotalBalance = 0;
	uint256 constant internal ROUNDING_MAGNITUDE = 2**64;
	address constant internal NULL_ADDRESS = 0x0000000000000000000000000000000000000000;

	 
	uint8 constant internal HOURGLASS_FEE = 10;
	uint8 constant internal HOURGLASS_BONUS = 3;

	 
	Hourglass internal hourglass;
	HourglassXReferralHandler internal refHandler;
	TeamJustPlayerBook internal playerBook;

	 
	mapping(address => int256) internal payouts;
	mapping(address => uint256) internal bonuses;
	mapping(address => address) public savedReferral;

	 
	mapping(address => mapping (address => bool)) internal ignoreTokenFallbackList;
	bool internal ignoreTokenFallbackEnable;

	 
	mapping(address => uint256) internal gauntletBalance;
	mapping(address => uint256) internal gauntletEnd;
	mapping(address => uint8) internal gauntletType;  

	 
	mapping(address => uint256) internal balances;
	mapping(address => mapping (address => uint256)) internal allowances;
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;

	 
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
	event Transfer(address indexed from, address indexed to, uint value);
	event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
	 
	 
	 


	event onTokenPurchase(
		address indexed accountHolder,
		uint256 ethereumSpent,
		uint256 tokensCreated,
		 
		uint256 tokensGiven,
		address indexed referrer,
		uint8 indexed bitFlags  
	);
	event onTokenSell(
		address indexed accountHolder,
		uint256 tokensDestroyed,
		uint256 ethereumEarned
	);
	event onWithdraw(
		address indexed accountHolder,
		uint256 earningsWithdrawn,
		uint256 refBonusWithdrawn,
		bool indexed reinvestment
	);
	event onDonatedDividends(
		address indexed donator,
		uint256 ethereumDonated
	);
	event onGauntletAcquired(
		address indexed strongHands,
		uint256 stakeAmount,
		uint8 indexed gauntletType,
		uint256 end
	);
	event onExternalGauntletAcquired(
		address indexed strongHands,
		uint256 stakeAmount,
		address indexed extGauntlet
	);
	 

	 
	function setNewOwner(address o) public onlyOwner {
		newOwner = o;
	}

	function acceptNewOwner() public {
		require(msg.sender == newOwner);
		owner = msg.sender;
	}

	 
	function rebrand(string memory n, string memory s) public onlyOwner {
		name = n;
		symbol = s;
	}

	 
	function setReferralRequirement(uint256 r) public onlyOwner {
		referralRequirement = r;
	}

	 
	function allowIgnoreTokenFallback() public onlyOwner {
		ignoreTokenFallbackEnable = true;
	}
	 

	 

	 
	 
	 
	 
	function ignoreTokenFallback(address to, bool ignore) public {
		require(ignoreTokenFallbackEnable, "This function is disabled");
		ignoreTokenFallbackList[msg.sender][to] = ignore;
	}

	 
	function transfer(address payable to, uint value, bytes memory data, string memory func) public returns(bool) {
		actualTransfer(msg.sender, to, value, data, func, true);
		return true;
	}

	 
	function transfer(address payable to, uint value, bytes memory data) public returns(bool) {
		actualTransfer(msg.sender, to, value, data, "", true);
		return true;
	}

	 
	function transfer(address payable to, uint value) public returns(bool) {
		actualTransfer(msg.sender, to, value, "", "", !ignoreTokenFallbackList[msg.sender][to]);
		return true;
	}

	 
	function approve(address spender, uint value) public returns(bool) {
		require(updateUsableBalanceOf(msg.sender) >= value, "Insufficient balance to approve");
		allowances[msg.sender][spender] = value;
		emit Approval(msg.sender, spender, value);
		return true;
	}

	 
	function transferFrom(address payable from, address payable to, uint value) public returns(bool success) {
		uint256 allowance = allowances[from][msg.sender];
		require(allowance > 0, "Not approved");
		require(allowance >= value, "Over spending limit");
		allowances[from][msg.sender] = allowance.sub(value);
		actualTransfer(from, to, value, "", "", false);
		return true;
	}

	 
	function() payable external{
		 
		if (msg.sender != address(hourglass) && msg.sender != address(refHandler)) {
			 
			 
			if (msg.value > 0) {
				lastTotalBalance += msg.value;
				distributeDividends(0, NULL_ADDRESS);
				lastTotalBalance -= msg.value;
			}
			createTokens(msg.sender, msg.value, NULL_ADDRESS, false);
		}
	}

	 
	 
	function acquireGauntlet(uint256 amount, uint8 gType, uint256 end) public{
		require(amount <= balances[msg.sender], "Insufficient balance");

		 
		 
		uint256 oldGauntletType = gauntletType[msg.sender];
		uint256 oldGauntletBalance = gauntletBalance[msg.sender];
		uint256 oldGauntletEnd = gauntletEnd[msg.sender];

		gauntletType[msg.sender] = gType;
		gauntletEnd[msg.sender] = end;
		gauntletBalance[msg.sender] = amount;

		if (oldGauntletType == 0) {
			if (gType == 1) {
				require(end >= (block.timestamp + 97200), "Gauntlet time must be >= 4 weeks");  
				emit onGauntletAcquired(msg.sender, amount, gType, end);
			} else if (gType == 2) {
				uint256 P3DSupply = hourglass.totalSupply();
				require(end >= (P3DSupply + (P3DSupply / 5)), "Gauntlet must make a profit");  
				emit onGauntletAcquired(msg.sender, amount, gType, end);
			} else if (gType == 3) {
				require(end <= 0x00ffffffffffffffffffffffffffffffffffffffff, "Invalid address");
				require(ExternalGauntletInterface(address(end)).gauntletRequirement(msg.sender, 0, amount), "External gauntlet check failed");
				emit onExternalGauntletAcquired(msg.sender, amount, address(end));
			} else {
				revert("Invalid gauntlet type");
			}
		} else if (oldGauntletType == 3) {
			require(gType == 3, "New gauntlet must be same type");
			require(end == gauntletEnd[msg.sender], "Must be same external gauntlet");
			require(ExternalGauntletInterface(address(end)).gauntletRequirement(msg.sender, oldGauntletBalance, amount), "External gauntlet check failed");
			emit onExternalGauntletAcquired(msg.sender, amount, address(end));
		} else {
			require(gType == oldGauntletType, "New gauntlet must be same type");
			require(end > oldGauntletEnd, "Gauntlet must be an upgrade");
			require(amount >= oldGauntletBalance, "New gauntlet must hold more tokens");
			emit onGauntletAcquired(msg.sender, amount, gType, end);
		}
	}

	function acquireExternalGauntlet(uint256 amount, address extGauntlet) public{
		acquireGauntlet(amount, 3, uint256(extGauntlet));
	}

	 
	 
	function buy(address referrerAddress) payable public returns(uint256) {
		 
		 
		if (msg.value > 0) {
			lastTotalBalance += msg.value;
			distributeDividends(0, NULL_ADDRESS);
			lastTotalBalance -= msg.value;
		}
		return createTokens(msg.sender, msg.value, referrerAddress, false);
	}

	 
	 
	 
	function buy(string memory referrerName) payable public playerBookEnabled returns(uint256) {
		address referrerAddress = getAddressFromReferralName(referrerName);
		 
		if (msg.value > 0) {
			lastTotalBalance += msg.value;
			distributeDividends(0, NULL_ADDRESS);
			lastTotalBalance -= msg.value;
		}
		return createTokens(msg.sender, msg.value, referrerAddress, false);
	}

	 
	 
	function reinvest() public returns(uint256) {
		address accountHolder = msg.sender;
		distributeDividends(0, NULL_ADDRESS);  
		uint256 payout;
		uint256 bonusPayout;
		(payout, bonusPayout) = clearDividends(accountHolder);
		emit onWithdraw(accountHolder, payout, bonusPayout, true);
		return createTokens(accountHolder, payout + bonusPayout, NULL_ADDRESS, true);
	}

	 
	 
	 
	function reinvestPartial(uint256 ethToReinvest, bool withdrawAfter) public returns(uint256 tokensCreated) {
		address payable accountHolder = msg.sender;
		distributeDividends(0, NULL_ADDRESS);  

		uint256 payout = dividendsOf(accountHolder, false);
		uint256 bonusPayout = bonuses[accountHolder];

		uint256 payoutReinvested = 0;
		uint256 bonusReinvested;

		require((payout + bonusPayout) >= ethToReinvest, "Insufficient balance for reinvestment");
		 
		if (ethToReinvest > bonusPayout){
			payoutReinvested = ethToReinvest - bonusPayout;
			bonusReinvested = bonusPayout;
			 
			payouts[accountHolder] += int256(payoutReinvested * ROUNDING_MAGNITUDE);
		}else{
			bonusReinvested = ethToReinvest;
		}
		 
		bonuses[accountHolder] -= bonusReinvested;

		emit onWithdraw(accountHolder, payoutReinvested, bonusReinvested, true);
		 
		tokensCreated = createTokens(accountHolder, ethToReinvest, NULL_ADDRESS, true);

		if (withdrawAfter && dividendsOf(msg.sender, true) > 0) {
			withdrawDividends(msg.sender);
		}
		return tokensCreated;
	}

	 
	function reinvestPartial(uint256 ethToReinvest) public returns(uint256) {
		return reinvestPartial(ethToReinvest, true);
	}

	 
	function sell(uint256 amount, bool withdrawAfter) public returns(uint256) {
		require(amount > 0, "You have to sell something");
		uint256 sellAmount = destroyTokens(msg.sender, amount);
		if (withdrawAfter && dividendsOf(msg.sender, true) > 0) {
			withdrawDividends(msg.sender);
		}
		return sellAmount;
	}

	 
	function sell(uint256 amount) public returns(uint256) {
		require(amount > 0, "You have to sell something");
		return destroyTokens(msg.sender, amount);
	}

	 
	function withdraw() public{
		require(dividendsOf(msg.sender, true) > 0, "No dividends to withdraw");
		withdrawDividends(msg.sender);
	}

	 
	function exit() public{
		address payable accountHolder = msg.sender;
		uint256 balance = balances[accountHolder];
		if (balance > 0) {
			destroyTokens(accountHolder, balance);
		}
		if (dividendsOf(accountHolder, true) > 0) {
			withdrawDividends(accountHolder);
		}
	}

	 
	function setReferrer(address ref) public{
		savedReferral[msg.sender] = ref;
	}

	 
	function setReferrer(string memory refName) public{
		savedReferral[msg.sender] = getAddressFromReferralName(refName);
	}

	 
	function donateDividends() payable public{
		distributeDividends(0, NULL_ADDRESS);
		emit onDonatedDividends(msg.sender, msg.value);
	}

	 

	 

	 
	function baseHourglass() external view returns(address) {
		return address(hourglass);
	}

	 
	function refHandlerAddress() external view returns(address) {
		return address(refHandler);
	}

	 
	function getAddressFromReferralName(string memory refName) public view returns (address){
		return playerBook.getPlayerAddr(playerBook.pIDxName_(stringToBytes32(refName)));
	}

	 
	function gauntletTypeOf(address accountHolder) public view returns(uint stakeAmount, uint gType, uint end) {
		if (isGauntletExpired(accountHolder)) {
			return (0, 0, gauntletEnd[accountHolder]);
		} else {
			return (gauntletBalance[accountHolder], gauntletType[accountHolder], gauntletEnd[accountHolder]);
		}
	}

	 
	function myGauntletType() public view returns(uint stakeAmount, uint gType, uint end) {
		return gauntletTypeOf(msg.sender);
	}

	 
	function usableBalanceOf(address accountHolder) public view returns(uint balance) {
		if (isGauntletExpired(accountHolder)) {
			return balances[accountHolder];
		} else {
			return balances[accountHolder].sub(gauntletBalance[accountHolder]);
		}
	}

	 
	function myUsableBalance() public view returns(uint balance) {
		return usableBalanceOf(msg.sender);
	}

	 
	function balanceOf(address accountHolder) external view returns(uint balance) {
		return balances[accountHolder];
	}

	 
	function myBalance() public view returns(uint256) {
		return balances[msg.sender];
	}

	 
	function allowance(address sugardaddy, address spender) external view returns(uint remaining) {
		return allowances[sugardaddy][spender];
	}

	 
	function totalBalance() public view returns(uint256) {
		return address(this).balance + hourglass.myDividends(true) + refHandler.totalBalance();
	}

	 
	function dividendsOf(address customerAddress, bool includeReferralBonus) public view returns(uint256) {
		uint256 divs = uint256(int256(profitPerShare * balances[customerAddress]) - payouts[customerAddress]) / ROUNDING_MAGNITUDE;
		if (includeReferralBonus) {
			divs += bonuses[customerAddress];
		}
		return divs;
	}

	 
	function dividendsOf(address customerAddress) public view returns(uint256) {
		return dividendsOf(customerAddress, true);
	}

	 
	function myDividends() public view returns(uint256) {
		return dividendsOf(msg.sender, true);
	}

	 
	function myDividends(bool includeReferralBonus) public view returns(uint256) {
		return dividendsOf(msg.sender, includeReferralBonus);
	}

	 
	function refBonusOf(address customerAddress) external view returns(uint256) {
		return bonuses[customerAddress];
	}

	 
	function myRefBonus() external view returns(uint256) {
		return bonuses[msg.sender];
	}

	 
	function stakingRequirement() external view returns(uint256) {
		return referralRequirement;
	}

	 
	function calculateTokensReceived(uint256 ethereumToSpend) public view returns(uint256) {
		return hourglass.calculateTokensReceived(ethereumToSpend);
	}

	 
	function calculateEthereumReceived(uint256 tokensToSell) public view returns(uint256) {
		return hourglass.calculateEthereumReceived(tokensToSell);
	}
	 

	 

	 
	function isGauntletExpired(address holder) internal view returns(bool) {
		if (gauntletType[holder] != 0) {
			if (gauntletType[holder] == 1) {
				return (block.timestamp >= gauntletEnd[holder]);
			} else if (gauntletType[holder] == 2) {
				return (hourglass.totalSupply() >= gauntletEnd[holder]);
			} else if (gauntletType[holder] == 3) {
				return ExternalGauntletInterface(gauntletEnd[holder]).gauntletRemovable(holder);
			}
		}
		return false;
	}

	 
	function updateUsableBalanceOf(address holder) internal returns(uint256) {
		 
		 
		if (isGauntletExpired(holder)) {
			if (gauntletType[holder] == 3){
				emit onExternalGauntletAcquired(holder, 0, NULL_ADDRESS);
			}else{
				emit onGauntletAcquired(holder, 0, 0, 0);
			}
			gauntletType[holder] = 0;
			gauntletBalance[holder] = 0;

			return balances[holder];
		}
		return balances[holder] - gauntletBalance[holder];
	}

	 
	function createTokens(address creator, uint256 eth, address referrer, bool reinvestment) internal returns(uint256) {
		 
		uint256 parentReferralRequirement = hourglass.stakingRequirement();
		 
		uint256 referralBonus = eth / HOURGLASS_FEE / HOURGLASS_BONUS;

		bool usedHourglassMasternode = false;
		bool invalidMasternode = false;
		if (referrer == NULL_ADDRESS) {
			referrer = savedReferral[creator];
		}

		 
		 
		uint256 tmp = hourglass.balanceOf(address(refHandler));

		 
		if (creator == referrer) {
			 
			invalidMasternode = true;
		} else if (referrer == NULL_ADDRESS) {
			usedHourglassMasternode = true;
		 
		} else if (balances[referrer] >= referralRequirement && (tmp >= parentReferralRequirement || hourglass.balanceOf(address(this)) >= parentReferralRequirement)) {
			 
		} else if (hourglass.balanceOf(referrer) >= parentReferralRequirement) {
			usedHourglassMasternode = true;
		} else {
			 
			invalidMasternode = true;
		}

		 
		 
		uint256 createdTokens = hourglass.totalSupply();

		 
		 
		 

		 
		if (tmp < parentReferralRequirement) {
			if (reinvestment) {
				 
				 
				tmp = refHandler.totalBalance();
				if (tmp < eth) {
					 
					tmp = eth - tmp;  
					if (address(this).balance < tmp) {
						 
						hourglass.withdraw();
					}
					address(refHandler).transfer(tmp);
				}
				tmp = hourglass.balanceOf(address(refHandler));

				 
				refHandler.buyTokensFromBalance(NULL_ADDRESS, eth);
			} else {
				 
				 
				refHandler.buyTokens.value(eth)(invalidMasternode ? NULL_ADDRESS : (usedHourglassMasternode ? referrer : address(this)));
			}
		} else {
			if (reinvestment) {
				 
				if (address(this).balance < eth && hourglass.myDividends(true) > 0) {
					hourglass.withdraw();
				}
				 
				if (address(this).balance < eth) {
					refHandler.sendETH(address(this), eth - address(this).balance);
				}
			}
			hourglass.buy.value(eth)(invalidMasternode ? NULL_ADDRESS : (usedHourglassMasternode ? referrer : address(refHandler)));
		}

		 
		createdTokens = hourglass.totalSupply() - createdTokens;
		totalSupply += createdTokens;

		 
		uint256 bonusTokens = hourglass.myTokens() + tmp - totalSupply;

		 
		tmp = 0;
		if (invalidMasternode)			{ tmp |= 1; }
		if (usedHourglassMasternode)	{ tmp |= 2; }
		if (reinvestment)				{ tmp |= 4; }

		emit onTokenPurchase(creator, eth, createdTokens, bonusTokens, referrer, uint8(tmp));
		createdTokens += bonusTokens;
		 
		balances[creator] += createdTokens;
		totalSupply += bonusTokens;

		 
		emit Transfer(address(this), creator, createdTokens, "");
		emit Transfer(address(this), creator, createdTokens);

		 
		payouts[creator] += int256(profitPerShare * createdTokens);  

		if (reinvestment) {
			 
			 
			lastTotalBalance = lastTotalBalance.sub(eth);
		}
		distributeDividends((usedHourglassMasternode || invalidMasternode) ? 0 : referralBonus, referrer);
		if (referrer != NULL_ADDRESS) {
			 
			savedReferral[creator] = referrer;
		}
		return createdTokens;
	}

	 
	function destroyTokens(address weakHand, uint256 bags) internal returns(uint256) {
		require(updateUsableBalanceOf(weakHand) >= bags, "Insufficient balance");

		 
		 
		distributeDividends(0, NULL_ADDRESS);
		uint256 tokenBalance = hourglass.myTokens();

		 
		uint256 ethReceived = hourglass.calculateEthereumReceived(bags);
		lastTotalBalance += ethReceived;
		if (tokenBalance >= bags) {
			hourglass.sell(bags);
		} else {
			 
			if (tokenBalance > 0) {
				hourglass.sell(tokenBalance);
			}
			refHandler.sellTokens(bags - tokenBalance);
		}

		 
		int256 updatedPayouts = int256(profitPerShare * bags + (ethReceived * ROUNDING_MAGNITUDE));
		payouts[weakHand] = payouts[weakHand].sub(updatedPayouts);

		 
		balances[weakHand] -= bags;
		totalSupply -= bags;

		emit onTokenSell(weakHand, bags, ethReceived);

		 
		emit Transfer(weakHand, address(this), bags, "");
		emit Transfer(weakHand, address(this), bags);
		return ethReceived;
	}

	 
	function sendETH(address payable to, uint256 amount) internal {
		uint256 childTotalBalance = refHandler.totalBalance();
		uint256 thisBalance = address(this).balance;
		uint256 thisTotalBalance = thisBalance + hourglass.myDividends(true);
		if (childTotalBalance >= amount) {
			 
			refHandler.sendETH(to, amount);
		} else if (thisTotalBalance >= amount) {
			 
			if (thisBalance < amount) {
				hourglass.withdraw();
			}
			to.transfer(amount);
		} else {
			 
			refHandler.sendETH(to, childTotalBalance);
			if (hourglass.myDividends(true) > 0) {
				hourglass.withdraw();
			}
			to.transfer(amount - childTotalBalance);
		}
		 
		lastTotalBalance = lastTotalBalance.sub(amount);
	}

	 
	function distributeDividends(uint256 bonus, address bonuser) internal{
		 
		if (totalSupply > 0) {
			uint256 tb = totalBalance();
			uint256 delta = tb - lastTotalBalance;
			if (delta > 0) {
				 
				if (bonus != 0) {
					bonuses[bonuser] += bonus;
				}
				profitPerShare = profitPerShare.add(((delta - bonus) * ROUNDING_MAGNITUDE) / totalSupply);
				lastTotalBalance += delta;
			}
		}
	}

	 
	function clearDividends(address accountHolder) internal returns(uint256, uint256) {
		uint256 payout = dividendsOf(accountHolder, false);
		uint256 bonusPayout = bonuses[accountHolder];

		payouts[accountHolder] += int256(payout * ROUNDING_MAGNITUDE);
		bonuses[accountHolder] = 0;

		 
		return (payout, bonusPayout);
	}

	 
	function withdrawDividends(address payable accountHolder) internal {
		distributeDividends(0, NULL_ADDRESS);  
		uint256 payout;
		uint256 bonusPayout;
		(payout, bonusPayout) = clearDividends(accountHolder);
		emit onWithdraw(accountHolder, payout, bonusPayout, false);
		sendETH(accountHolder, payout + bonusPayout);
	}

	 
	function actualTransfer (address payable from, address payable to, uint value, bytes memory data, string memory func, bool careAboutHumanity) internal{
		require(updateUsableBalanceOf(from) >= value, "Insufficient balance");
		require(to != address(refHandler), "My slave doesn't get paid");  
		require(to != address(hourglass), "P3D has no need for these");  

		if (to == address(this)) {
			 
			if (value == 0) {
				 
				emit Transfer(from, to, value, data);
				emit Transfer(from, to, value);
			} else {
				destroyTokens(from, value);
			}
			withdrawDividends(from);
		} else {
			distributeDividends(0, NULL_ADDRESS);  
			 

			 
			balances[from] = balances[from].sub(value);
			balances[to] = balances[to].add(value);

			 
			payouts[from] -= int256(profitPerShare * value);
			 
			payouts[to] += int256(profitPerShare * value);

			if (careAboutHumanity && isContract(to)) {
				if (bytes(func).length == 0) {
					ERC223Handler receiver = ERC223Handler(to);
					receiver.tokenFallback(from, value, data);
				} else {
					bool success;
					bytes memory returnData;
					(success, returnData) = to.call.value(0)(abi.encodeWithSignature(func, from, value, data));
					assert(success);
				}
			}
			emit Transfer(from, to, value, data);
			emit Transfer(from, to, value);
		}
	}

	 
	function bytesToBytes32(bytes memory data) internal pure returns(bytes32){
		uint256 result = 0;
		uint256 len = data.length;
		uint256 singleByte;
		for (uint256 i = 0; i<len; i+=1){
			singleByte = uint256(uint8(data[i])) << ( (31 - i) * 8);
			require(singleByte != 0, "bytes cannot contain a null byte");
			result |= singleByte;
		}
		return bytes32(result);
	}

	 
	function stringToBytes32(string memory data) internal pure returns(bytes32){
		return bytesToBytes32(bytes(data));
	}

	 
	function isContract(address _addr) internal view returns(bool) {
		uint length;
		assembly {
			 
			length := extcodesize(_addr)
		}
		return (length>0);
	}

	 
	function tokenFallback(address from, uint value, bytes memory data) public pure{
		revert("I don't want your shitcoins!");
	}

	 
	function takeShitcoin(address shitCoin) public{
		 
		require(shitCoin != address(hourglass), "P3D isn't a shitcoin");
		ERC20interface s = ERC20interface(shitCoin);
		s.transfer(msg.sender, s.balanceOf(address(this)));
	}
}


 
library SafeMath {

	 
	function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
		if (a == 0 || b == 0) {
		   return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}

	 
	function div(uint256 a, uint256 b) internal pure returns(uint256) {
		 
		 
		 
		return a / b;
	}

	 
	function sub(uint256 a, uint256 b) internal pure returns(uint256) {
		assert(b <= a);
		return a - b;
	}

	 
	function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}

	 
	function sub(int256 a, int256 b) internal pure returns(int256 c) {
		c = a - b;
		assert(c <= a);
		return c;
	}

	 
	function add(int256 a, int256 b) internal pure returns(int256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}