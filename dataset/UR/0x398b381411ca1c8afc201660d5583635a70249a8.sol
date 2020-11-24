 

pragma solidity 0.4.19;

contract Dextera {
	 

	 
	address public creator = msg.sender;

	 
	address public seller;

	 
	uint256 public ticketPrice;

	 
	uint256 public minimumTickets;

	 
	uint256 public creatorFeePercent;

	 
	uint256 public saleEndTime;

	 

	 
	uint256 public successfulTime;

	 
	struct Buyer {
		address ethAddress;
		uint256 atTicket;
		uint256 amountPaid;
	}
	mapping(uint256 => Buyer) public buyers;

	 
	uint256 public totalBuyers = 0;

	 
	uint256 public totalTickets = 0;

	 
	uint256 public returnLastBuyerIndex = 0;

	 
	uint256 public winnerKey = 0;

	 
	uint256 public winnerTicket = 0;

	 
	enum States { Started, NoEntry, Failed, Succeeded }
	States public saleState = States.Started;

	 

	 
	function Dextera(address _seller, uint256 _ticketPrice, uint256 _minimumTickets, uint256 _creatorFeePercent, uint256 _saleDays) public {
		 
		seller = _seller;

		 
		ticketPrice = _ticketPrice;

		 
		minimumTickets = _minimumTickets;

		 
		creatorFeePercent = _creatorFeePercent;

		 
 		saleEndTime = now + _saleDays * 1 days;
  }

	 

	 
	modifier onlyCreator() {
		require(msg.sender == creator);
		_;
	}

	 
	modifier inState(States _state) {
		require(saleState == _state);
		_;
	}

	 

	 
	function() public payable {
		 
		if (saleState == States.Started) {
			 
			require(msg.value >= ticketPrice);

			 
			uint256 _ticketsBought = 1;
			if (msg.value > ticketPrice) {
				_ticketsBought = msg.value / ticketPrice;
			}

			 
			require(minimumTickets - totalTickets >= _ticketsBought);

			 
			totalTickets = totalTickets + _ticketsBought;

			 
			buyers[totalBuyers] = Buyer(msg.sender, totalTickets, msg.value);

			 
			totalBuyers = totalBuyers + 1;

			 
			if (totalTickets >= minimumTickets) {
				finalSuccess();
			}

		 
		} else if (saleState == States.NoEntry) {
			 
			require(msg.sender == buyers[winnerKey].ethAddress);

			 
			require(this.balance > 0);

			 
			require(msg.value == 0);

			 
			saleState = States.Succeeded;

			 
			uint256 _creatorFee = (this.balance * creatorFeePercent / 100);
			creator.send(_creatorFee);

			 
			seller.send(this.balance);

		 
		} else {
			require(false);
		}
	}

	 

	 
	function saleFinalize() public inState(States.Started) {
		 
		require(now >= saleEndTime);

		 
		saleState = States.Failed;

		 
		returnToBuyers();
	}

	 
	function finalSuccess() private {
		 
		successfulTime = now;

		 
		saleState = States.NoEntry;

		 
		winnerTicket = getRand(totalTickets) + 1;

		 
		winnerKey = getWinnerKey();
	}

	 

	 
	function revertFunds() public inState(States.NoEntry) {
		 
		require(now >= successfulTime + 30 * 1 days);

		 
		saleState = States.Failed;

		 
		returnToBuyers();
	}

	 
	function returnToBuyersContinue() public inState(States.Failed) {
		 
		require(returnLastBuyerIndex < totalBuyers);

		 
		returnToBuyers();
	}

	 

	 
	function pullTheLever() public onlyCreator {
		 
		selfdestruct(creator);
	}

	 
	function getRand(uint256 _max) private view returns(uint256) {
		return (uint256(keccak256(block.difficulty, block.coinbase, now, block.blockhash(block.number - 1))) % _max);
	}

	 
	function getWinnerAccount() public view returns(address) {
		 
		require(winnerTicket > 0);

		 
		return buyers[winnerKey].ethAddress;
	}

	 
	function returnToBuyers() private {
		 
		if (this.balance > 0) {
			 
			uint256 _i = returnLastBuyerIndex;

			while (_i < totalBuyers && msg.gas > 200000) {
				buyers[_i].ethAddress.send(buyers[_i].amountPaid);
				_i++;
			}
			returnLastBuyerIndex = _i;
		}
	}

	 
	function getWinnerKey() private view returns(uint256) {
		 
		uint256 _i = 0;
		uint256 _j = totalBuyers - 1;
		uint256 _n = 0;

		 
		do {
			 
			if (buyers[_i].atTicket >= winnerTicket) {
				return _i;

			 
			} else if (buyers[_j].atTicket <= winnerTicket) {
				return _j;

			 
			} else if ((_j - _i + 1) == 2) {
				return _j;
			}

			 
			_n = ((_j - _i) / 2) + _i;

			 
			if (buyers[_n].atTicket <= winnerTicket) {
				_i = _n;

			 
			} else {
				_j = _n;
			}

		} while(true);
	}
}