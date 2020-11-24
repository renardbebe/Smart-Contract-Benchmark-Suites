 

pragma solidity ^0.5.0;

library SafeMath {
	function mul(uint a, uint b) internal pure returns (uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint a, uint b) internal pure returns (uint) {
		 
		uint c = a / b;
		 
		return c;
	}

	function sub(uint a, uint b) internal pure returns (uint) {
		assert(b <= a);
		return a - b;
	}

	function add(uint a, uint b) internal pure returns (uint) {
		uint c = a + b;
		assert(c >= a);
		return c;
	}

	function diff(uint a, uint b) internal pure returns (uint) {
		return a > b ? sub(a, b) : sub(b, a);
	}

	function gt(uint a, uint b) internal pure returns(bytes1) {
		bytes1 c;
		c = 0x00;
		if (a > b) {
			c = 0x01;
		}
		return c;
	}
}

interface IMultiSigManager {
	function provideAddress(address origin, uint poolIndex) external returns (address payable);
	function passedContract(address) external returns (bool);
	function moderator() external returns(address);
}

contract Managed {
	IMultiSigManager roleManager;
	address public roleManagerAddress;
	address public operator;
	uint public lastOperationTime;
	uint public operationCoolDown;
	uint constant BP_DENOMINATOR = 10000;

	event UpdateRoleManager(address newManagerAddress);
	event UpdateOperator(address updater, address newOperator);

	modifier only(address addr) {
		require(msg.sender == addr);
		_;
	}

	modifier inUpdateWindow() {
		uint currentTime = getNowTimestamp();
		require(currentTime - lastOperationTime >= operationCoolDown);
		_;
		lastOperationTime = currentTime;
	}

	constructor(
		address roleManagerAddr,
		address opt, 
		uint optCoolDown
	) public {
		roleManagerAddress = roleManagerAddr;
		roleManager = IMultiSigManager(roleManagerAddr);
		operator = opt;
		operationCoolDown = optCoolDown;
	}

	function updateRoleManager(address newManagerAddr) 
		inUpdateWindow() 
		public 
	returns (bool) {
		require(roleManager.passedContract(newManagerAddr));
		roleManagerAddress = newManagerAddr;
		roleManager = IMultiSigManager(roleManagerAddress);
		require(roleManager.moderator() != address(0));
		emit UpdateRoleManager(newManagerAddr);
		return true;
	}

	function updateOperator() public inUpdateWindow() returns (bool) {	
		address updater = msg.sender;	
		operator = roleManager.provideAddress(updater, 0);
		emit UpdateOperator(updater, operator);	
		return true;
	}

	function getNowTimestamp() internal view returns (uint) {
		return now;
	}
}

 
 
contract Magi is Managed {
	using SafeMath for uint;

	 
	struct Price {
		uint priceInWei;
		uint timeInSecond;
		address source;
	}
	Price public firstPrice;
	Price public secondPrice;
	Price public lastPrice;
	address public priceFeed1; 
	address public priceFeed2; 
	address public priceFeed3;
	uint public priceTolInBP = 500; 
	uint public priceFeedTolInBP = 100;
	uint public priceFeedTimeTol = 1 minutes;
	uint public priceUpdateCoolDown;
	uint public numOfPrices = 0;
	bool public started = false;

	 
	modifier isPriceFeed() {
		require(msg.sender == priceFeed1 || msg.sender == priceFeed2 || msg.sender == priceFeed3);
		_;
	}

	 
	event CommitPrice(uint indexed priceInWei, uint indexed timeInSecond, address sender, uint index);
	event AcceptPrice(uint indexed priceInWei, uint indexed timeInSecond, address sender);
	event SetValue(uint index, uint oldValue, uint newValue);
	event UpdatePriceFeed(address updater, address newPriceFeed);

	 
	constructor(
		address opt,
		address pf1,
		address pf2,
		address pf3,
		address roleManagerAddr,
		uint pxCoolDown,
		uint optCoolDown
		) 
		public
		Managed(roleManagerAddr, opt, optCoolDown) 
	{
		priceFeed1 = pf1;
		priceFeed2 = pf2;
		priceFeed3 = pf3;
		priceUpdateCoolDown = pxCoolDown;
		roleManagerAddress = roleManagerAddr;
		roleManager = IMultiSigManager(roleManagerAddr);
		emit UpdateRoleManager(roleManagerAddress);
	}


	 
	function startOracle(
		uint priceInWei, 
		uint timeInSecond
	)
		public 
		isPriceFeed() 
		returns (bool success) 
	{
		require(!started && timeInSecond <= getNowTimestamp());
		lastPrice.timeInSecond = timeInSecond;
		lastPrice.priceInWei = priceInWei;
		lastPrice.source = msg.sender;
		started = true;
		emit AcceptPrice(priceInWei, timeInSecond, msg.sender);
		return true;
	}


	function getLastPrice() public view returns(uint, uint) {
		return (lastPrice.priceInWei, lastPrice.timeInSecond);
	}

	 
	function commitPrice(uint priceInWei, uint timeInSecond) 
		public 
		isPriceFeed()
		returns (bool success)
	{	
		require(started && timeInSecond <= getNowTimestamp() && timeInSecond >= lastPrice.timeInSecond.add(priceUpdateCoolDown));
		uint priceDiff;
		if (numOfPrices == 0) {
			priceDiff = priceInWei.diff(lastPrice.priceInWei);
			if (priceDiff.mul(BP_DENOMINATOR).div(lastPrice.priceInWei) <= priceTolInBP) {
				acceptPrice(priceInWei, timeInSecond, msg.sender);
			} else {
				 
				firstPrice = Price(priceInWei, timeInSecond, msg.sender);
				emit CommitPrice(priceInWei, timeInSecond, msg.sender, 0);
				numOfPrices++;
			}
		} else if (numOfPrices == 1) {
			if (timeInSecond > firstPrice.timeInSecond.add(priceUpdateCoolDown)) {
				if (firstPrice.source == msg.sender)
					acceptPrice(priceInWei, timeInSecond, msg.sender);
				else
					acceptPrice(firstPrice.priceInWei, timeInSecond, firstPrice.source);
			} else {
				require(firstPrice.source != msg.sender);
				 
				if (firstPrice.timeInSecond.add(priceFeedTimeTol) < timeInSecond || 
					firstPrice.timeInSecond.sub(priceFeedTimeTol) > timeInSecond) {
					acceptPrice(firstPrice.priceInWei, firstPrice.timeInSecond, firstPrice.source);
				} else {
					priceDiff = priceInWei.diff(firstPrice.priceInWei);
					if (priceDiff.mul(BP_DENOMINATOR).div(firstPrice.priceInWei) <= priceTolInBP) {
						acceptPrice(firstPrice.priceInWei, firstPrice.timeInSecond, firstPrice.source);
					} else {
						 
						secondPrice = Price(priceInWei, timeInSecond, msg.sender);
						emit CommitPrice(priceInWei, timeInSecond, msg.sender, 1);
						numOfPrices++;
					} 
				}
			}
		} else if (numOfPrices == 2) {
			if (timeInSecond > firstPrice.timeInSecond + priceUpdateCoolDown) {
				if ((firstPrice.source == msg.sender || secondPrice.source == msg.sender))
					acceptPrice(priceInWei, timeInSecond, msg.sender);
				else
					acceptPrice(secondPrice.priceInWei, timeInSecond, secondPrice.source);
			} else {
				require(firstPrice.source != msg.sender && secondPrice.source != msg.sender);
				uint acceptedPriceInWei;
				 
				if (firstPrice.timeInSecond.add(priceFeedTimeTol) < timeInSecond || 
					firstPrice.timeInSecond.sub(priceFeedTimeTol) > timeInSecond) {
					acceptedPriceInWei = firstPrice.priceInWei;
				} else {
					 
					 
					 
					if (secondPrice.priceInWei == priceInWei) {
						acceptedPriceInWei = priceInWei;
					} else {
						acceptedPriceInWei = getMedian(firstPrice.priceInWei, secondPrice.priceInWei, priceInWei);
					}
				}
				acceptPrice(acceptedPriceInWei, firstPrice.timeInSecond, firstPrice.source);
			}
		} else {
			return false;
		}

		return true;
	}

	 
	function acceptPrice(uint priceInWei, uint timeInSecond, address source) internal {
		lastPrice.priceInWei = priceInWei;
		lastPrice.timeInSecond = timeInSecond;
		lastPrice.source = source;
		numOfPrices = 0;
		emit AcceptPrice(priceInWei, timeInSecond, source);
	}

	function getMedian(uint a, uint b, uint c) internal pure returns (uint) {
		if (a.gt(b) ^ c.gt(a) == 0x0) {
			return a;
		} else if(b.gt(a) ^ c.gt(b) == 0x0) {
			return b;
		} else {
			return c;
		}
	}
	 

	 
	function updatePriceFeed(uint index) 
		inUpdateWindow() 
		public 
	returns (bool) {
		require(index < 3);
		address updater = msg.sender;
		address newAddr = roleManager.provideAddress(updater, 1);
		if(index == 0) 
			priceFeed1 = newAddr;
		else if (index == 1)
			priceFeed2 = newAddr;
		else  
			priceFeed3 = newAddr;
		
		emit UpdatePriceFeed(updater, newAddr);
		return true;
	}

	function setValue(
		uint idx, 
		uint newValue
	) 
		public 
		only(operator) 
		inUpdateWindow() 
	returns (bool success) {
		uint oldValue;
		if (idx == 0) {
			oldValue = priceTolInBP;
			priceTolInBP = newValue;
		} else if (idx == 1) {
			oldValue = priceFeedTolInBP;
			priceFeedTolInBP = newValue;
		} else if (idx == 2) {
			oldValue = priceFeedTimeTol;
			priceFeedTimeTol = newValue;
		} else if (idx == 3) {
			oldValue = priceUpdateCoolDown;
			priceUpdateCoolDown = newValue;
		} else {
			revert();
		}

		emit SetValue(idx, oldValue, newValue);
		return true;
	}
	 

}