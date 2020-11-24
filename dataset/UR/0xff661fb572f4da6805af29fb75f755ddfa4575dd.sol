 

pragma solidity ^0.4.23;

contract LotteryFactory {

	 
	uint public commissionSum;
	 
	Params public defaultParams;
	 
	Lottery[] public lotteries;
	 
	uint public lotteryCount;
	 
	address public owner;

	struct Lottery {
		mapping(address => uint) ownerTokenCount;
		mapping(address => uint) ownerTokenCountToSell;
		mapping(address => uint) sellerId;
		address[] sellingAddresses;
		uint[] sellingAmounts;
		uint createdAt;
		uint tokenCount;
		uint tokenCountToSell;
		uint winnerSum;
		bool prizeRedeemed;
		address winner;
		address[] participants;
		Params params;
	}

	 
	struct Params {
		uint gameDuration;
		uint initialTokenPrice; 
		uint durationToTokenPriceUp; 
		uint tokenPriceIncreasePercent; 
		uint tradeCommission; 
		uint winnerCommission;
	}

	 
	event PurchaseError(address oldOwner, uint amount);

	 
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	 
	constructor() public {
		 
		owner = msg.sender;
		 
		updateParams(4 hours, 0.01 ether, 15 minutes, 10, 1, 10);
		 
		_createNewLottery();
	}

	 
	function approveToSell(uint _tokenCount) public {
		Lottery storage lottery = lotteries[lotteryCount - 1];
		 
		require(lottery.ownerTokenCount[msg.sender] - lottery.ownerTokenCountToSell[msg.sender] >= _tokenCount);
		 
		if(lottery.sellingAddresses.length == 0 || lottery.sellerId[msg.sender] == 0 && lottery.sellingAddresses[0] != msg.sender) {
			uint sellingAddressesCount = lottery.sellingAddresses.push(msg.sender);
			uint sellingAmountsCount = lottery.sellingAmounts.push(_tokenCount);
			assert(sellingAddressesCount == sellingAmountsCount);
			lottery.sellerId[msg.sender] = sellingAddressesCount - 1;
		} else {
			 
			uint sellerIndex = lottery.sellerId[msg.sender];
			lottery.sellingAmounts[sellerIndex] += _tokenCount;
		}
		 
		lottery.ownerTokenCountToSell[msg.sender] += _tokenCount;
		lottery.tokenCountToSell += _tokenCount;
	}

	 
	function balanceOf(address _user) public view returns(uint) {
		Lottery storage lottery = lotteries[lotteryCount - 1];
		return lottery.ownerTokenCount[_user];
	}

	 
	function balanceSellingOf(address _user) public view returns(uint) {
		Lottery storage lottery = lotteries[lotteryCount - 1];
		return lottery.ownerTokenCountToSell[_user];
	}

	 
	function buyTokens() public payable {
		if(_isNeededNewLottery()) _createNewLottery();
		 
		Lottery storage lottery = lotteries[lotteryCount - 1];
		 
		uint price = _getCurrentTokenPrice();
		uint tokenCountToBuy = msg.value / price;
		 
		uint rest = msg.value - tokenCountToBuy * price;
		if( rest > 0 ){
		    lottery.winnerSum = lottery.winnerSum + rest;
		}
		 
		require(tokenCountToBuy > 0);
		 
		uint tokenCountToBuyFromSeller = _getTokenCountToBuyFromSeller(tokenCountToBuy);
		if(tokenCountToBuyFromSeller > 0) {
		 	_buyTokensFromSeller(tokenCountToBuyFromSeller);
		}
		 
		uint tokenCountToBuyFromSystem = tokenCountToBuy - tokenCountToBuyFromSeller;
		if(tokenCountToBuyFromSystem > 0) {
			_buyTokensFromSystem(tokenCountToBuyFromSystem);
		}
		 
		_addToParticipants(msg.sender);
		 
		lottery.winnerSum += tokenCountToBuyFromSystem * price;
		lottery.winner = _getWinner();
	}

	 
	function disapproveToSell(uint _tokenCount) public {
		Lottery storage lottery = lotteries[lotteryCount - 1];
		 
		require(lottery.ownerTokenCountToSell[msg.sender] >= _tokenCount);
		 
		uint sellerIndex = lottery.sellerId[msg.sender];
		lottery.sellingAmounts[sellerIndex] -= _tokenCount;
		 
		lottery.ownerTokenCountToSell[msg.sender] -= _tokenCount;
		lottery.tokenCountToSell -= _tokenCount;
	}

	 
	function getLotteryAtIndex(uint _index) public view returns(
		uint createdAt,
		uint tokenCount,
		uint tokenCountToSell,
		uint winnerSum,
		address winner,
		bool prizeRedeemed,
		address[] participants,
		uint paramGameDuration,
		uint paramInitialTokenPrice,
		uint paramDurationToTokenPriceUp,
		uint paramTokenPriceIncreasePercent,
		uint paramTradeCommission,
		uint paramWinnerCommission
	) {
		 
		require(_index < lotteryCount);
		 
		Lottery memory lottery = lotteries[_index];
		createdAt = lottery.createdAt;
		tokenCount = lottery.tokenCount;
		tokenCountToSell = lottery.tokenCountToSell;
		winnerSum = lottery.winnerSum;
		winner = lottery.winner;
		prizeRedeemed = lottery.prizeRedeemed;
		participants = lottery.participants;
		paramGameDuration = lottery.params.gameDuration;
		paramInitialTokenPrice = lottery.params.initialTokenPrice;
		paramDurationToTokenPriceUp = lottery.params.durationToTokenPriceUp;
		paramTokenPriceIncreasePercent = lottery.params.tokenPriceIncreasePercent;
		paramTradeCommission = lottery.params.tradeCommission;
		paramWinnerCommission = lottery.params.winnerCommission;
	}

	 
	function getSales() public view returns(address[], uint[]) {
		 
		Lottery memory lottery = lotteries[lotteryCount - 1];
		 
		return (lottery.sellingAddresses, lottery.sellingAmounts);
	}

	 
	function getTop(uint _n) public view returns(address[], uint[]) {
		 
		require(_n > 0);
		 
		Lottery memory lottery = lotteries[lotteryCount - 1];
		 
		address[] memory resultAddresses = new address[](_n);
		uint[] memory resultBalances = new uint[](_n);
		for(uint i = 0; i < _n; i++) {
			 
			if(i > lottery.participants.length - 1) continue;
			 
			uint prevMaxBalance = i == 0 ? 0 : resultBalances[i-1];
			address prevAddressWithMax = i == 0 ? address(0) : resultAddresses[i-1];
			uint currentMaxBalance = 0;
			address currentAddressWithMax = address(0);
			for(uint j = 0; j < lottery.participants.length; j++) {
				uint balance = balanceOf(lottery.participants[j]);
				 
				if(i == 0) {
					if(balance > currentMaxBalance) {
						currentMaxBalance = balance;
						currentAddressWithMax = lottery.participants[j];
					}
				} else {
					 
					if(prevMaxBalance >= balance && balance > currentMaxBalance && lottery.participants[j] != prevAddressWithMax) {
						currentMaxBalance = balance;
						currentAddressWithMax = lottery.participants[j];
					}
				}
			}
			resultAddresses[i] = currentAddressWithMax;
			resultBalances[i] = currentMaxBalance;
		}
		return(resultAddresses, resultBalances);
	}

	 
	function sellerIdOf(address _user) public view returns(uint) {
		Lottery storage lottery = lotteries[lotteryCount - 1];
		return lottery.sellerId[_user];
	}

	 
	function updateParams(
		uint _gameDuration,
		uint _initialTokenPrice,
		uint _durationToTokenPriceUp,
		uint _tokenPriceIncreasePercent,
		uint _tradeCommission,
		uint _winnerCommission
	) public onlyOwner {
		Params memory params;
		params.gameDuration = _gameDuration;
		params.initialTokenPrice = _initialTokenPrice;
		params.durationToTokenPriceUp = _durationToTokenPriceUp;
		params.tokenPriceIncreasePercent = _tokenPriceIncreasePercent;
		params.tradeCommission = _tradeCommission;
		params.winnerCommission = _winnerCommission;
		defaultParams = params;
	}

	 
	function withdraw() public onlyOwner {
		 
		require(commissionSum > 0);
		 
		uint commissionSumToTransfer = commissionSum;
		commissionSum = 0;
		 
		owner.transfer(commissionSumToTransfer);
	}

	 
	function withdrawForWinner(uint _lotteryIndex) public {
		 
		require(lotteries.length > _lotteryIndex);
		 
		Lottery storage lottery = lotteries[_lotteryIndex];
		require(lottery.winner == msg.sender);
		 
		require(now > lottery.createdAt + lottery.params.gameDuration);
		 
		require(!lottery.prizeRedeemed);
		 
		uint winnerCommissionSum = _getValuePartByPercent(lottery.winnerSum, lottery.params.winnerCommission);
		commissionSum += winnerCommissionSum;
		uint winnerSum = lottery.winnerSum - winnerCommissionSum;
		 
		lottery.prizeRedeemed = true;
		 
		lottery.winner.transfer(winnerSum);
	}

	 
	function() public payable {
		revert();
	}

	 
	function _addToParticipants(address _user) internal {
		 
		Lottery storage lottery = lotteries[lotteryCount - 1];
		bool isParticipant = false;
		for(uint i = 0; i < lottery.participants.length; i++) {
			if(lottery.participants[i] == _user) {
				isParticipant = true;
				break;
			}
		}
		if(!isParticipant) {
			lottery.participants.push(_user);
		}
	}

	 
	function _buyTokensFromSeller(uint _tokenCountToBuy) internal {
		 
		require(_tokenCountToBuy > 0);
		 
		Lottery storage lottery = lotteries[lotteryCount - 1];
		 
		uint currentTokenPrice = _getCurrentTokenPrice();
		uint currentCommissionSum = _getValuePartByPercent(currentTokenPrice, lottery.params.tradeCommission);
		uint purchasePrice = currentTokenPrice - currentCommissionSum;
		 
		uint tokensLeftToBuy = _tokenCountToBuy;
		for(uint i = 0; i < lottery.sellingAmounts.length; i++) {
			 
			if(lottery.sellingAmounts[i] != 0 && lottery.sellingAddresses[i] != msg.sender) {
				address oldOwner = lottery.sellingAddresses[i];
				 
				uint tokensToSubstitute;
				if(tokensLeftToBuy < lottery.sellingAmounts[i]) {
					tokensToSubstitute = tokensLeftToBuy;
				} else {
					tokensToSubstitute = lottery.sellingAmounts[i];
				}
				 
				lottery.sellingAmounts[i] -= tokensToSubstitute;
				lottery.ownerTokenCount[oldOwner] -= tokensToSubstitute;
				lottery.ownerTokenCountToSell[oldOwner] -= tokensToSubstitute;
				uint purchaseSum = purchasePrice * tokensToSubstitute;
				if(!oldOwner.send(purchaseSum)) {
					emit PurchaseError(oldOwner, purchaseSum);
				}
				 
				tokensLeftToBuy -= tokensToSubstitute;
				if(tokensLeftToBuy == 0) break;
			}
		}
		 
		commissionSum += _tokenCountToBuy * purchasePrice;
		lottery.ownerTokenCount[msg.sender] += _tokenCountToBuy;
		lottery.tokenCountToSell -= _tokenCountToBuy;
	}

	 
	function _buyTokensFromSystem(uint _tokenCountToBuy) internal {
		 
		require(_tokenCountToBuy > 0);
		 
		Lottery storage lottery = lotteries[lotteryCount - 1];
		 
		lottery.ownerTokenCount[msg.sender] += _tokenCountToBuy;
		 
		lottery.tokenCount += _tokenCountToBuy;
	}

	 
	function _createNewLottery() internal {
		Lottery memory lottery;
		lottery.createdAt = _getNewLotteryCreatedAt();
		lottery.params = defaultParams;
		lotteryCount = lotteries.push(lottery);
	}

	 
	function _getCurrentTokenPrice() internal view returns(uint) {
		Lottery memory lottery = lotteries[lotteryCount - 1];
		uint diffInSec = now - lottery.createdAt;
		uint stageCount = diffInSec / lottery.params.durationToTokenPriceUp;
		uint price = lottery.params.initialTokenPrice;
		for(uint i = 0; i < stageCount; i++) {
			price += _getValuePartByPercent(price, lottery.params.tokenPriceIncreasePercent);
		}
		return price;
	}

	 
	function _getNewLotteryCreatedAt() internal view returns(uint) {
		 
		if(lotteries.length == 0) return now;
		 
		 
		uint latestEndAt = lotteries[lotteryCount - 1].createdAt + lotteries[lotteryCount - 1].params.gameDuration;
		 
		uint nextEndAt = latestEndAt + defaultParams.gameDuration;
		while(now > nextEndAt) {
			nextEndAt += defaultParams.gameDuration;
		}
		return nextEndAt - defaultParams.gameDuration;
	}

	 
	function _getTokenCountToBuyFromSeller(uint _tokenCountToBuy) internal view returns(uint) {
		 
		require(_tokenCountToBuy > 0);
		 
		Lottery storage lottery = lotteries[lotteryCount - 1];
		 
		require(lottery.tokenCountToSell >= lottery.ownerTokenCountToSell[msg.sender]);
		 
		uint tokenCountToSell = lottery.tokenCountToSell - lottery.ownerTokenCountToSell[msg.sender];
		 
		if(tokenCountToSell == 0) return 0;
		 
		if(tokenCountToSell < _tokenCountToBuy) {
			return tokenCountToSell;
		} else {
			 
			return _tokenCountToBuy;
		}
	}

	 
	function _getValuePartByPercent(uint _initialValue, uint _percent) internal pure returns(uint) {
		uint onePercentValue = _initialValue / 100;
		return onePercentValue * _percent;
	}

	 
	function _getWinner() internal view returns(address) {
		Lottery storage lottery = lotteries[lotteryCount - 1];
		 
		if(lottery.participants.length == 0) return address(0);
		 
		address winner = lottery.participants[0];
		uint maxTokenCount = 0;
		 
		for(uint i = 0; i < lottery.participants.length; i++) {
			uint currentTokenCount = lottery.ownerTokenCount[lottery.participants[i]];
			if(currentTokenCount > maxTokenCount) {
				winner = lottery.participants[i];
				maxTokenCount = currentTokenCount; 
			}
		}
		return winner;
	}

	 
	function _isNeededNewLottery() internal view returns(bool) {
		 
		if(lotteries.length == 0) return true;
		 
		Lottery memory lottery = lotteries[lotteries.length - 1];
		return now > lottery.createdAt + defaultParams.gameDuration;
	}

}