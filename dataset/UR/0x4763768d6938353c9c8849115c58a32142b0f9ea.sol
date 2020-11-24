 

pragma solidity ^0.4.18;
 
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


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract DeLottery is Pausable {
	using SafeMath for uint256;

	uint32 public constant QUORUM = 3;

	address[] gamblers;

	uint public ticketPrice = 1 ether;

	uint public prizeFund = 0;

	uint public nextTicketPrice = 0;

	uint public stage;

	uint public maxTickets = 100;

	mapping(address => mapping(address => uint)) prizes;

	mapping(address => bool) lotteryRunners;

	event Win(uint indexed stage, uint ticketsCount, uint ticketNumber, address indexed winner, uint prize);

   	modifier canRunLottery() {
   		require(lotteryRunners[msg.sender]);
   		_;
   	}

	function DeLottery() public {
		lotteryRunners[msg.sender] = true;
		gamblers.push(0x0);
	}

	function () public payable whenNotPaused {
		require(!isContract(msg.sender));
		require(msg.value >= ticketPrice);
		uint availableTicketsToBuy = maxTickets - getTicketsCount();
		require(availableTicketsToBuy > 0);

		uint ticketsBought = msg.value.div(ticketPrice);

		uint ticketsToBuy;
		uint refund = 0;
		if(ticketsBought > availableTicketsToBuy) {
			ticketsToBuy = availableTicketsToBuy;
			refund = (ticketsBought - availableTicketsToBuy).mul(ticketPrice);
		} else {
			ticketsToBuy = ticketsBought;
		}

		for(uint16 i = 0; i < ticketsToBuy; i++) {
			gamblers.push(msg.sender);
		}

		prizeFund = prizeFund.add(ticketsToBuy.mul(ticketPrice));

		 
		refund = refund.add(msg.value % ticketPrice);
		if(refund > 0) {
			msg.sender.transfer(refund);
		}
	}

	function calculateWinnerPrize(uint fund, uint winnersCount) public pure returns (uint prize) {
		return fund.mul(19).div(winnersCount).div(20);
	}

	function calculateWinnersCount(uint _ticketsCount) public pure returns (uint count) {
		if(_ticketsCount < 10) {
			return 1;
		} else {
			return _ticketsCount.div(10);
		}
	}

	function runLottery() external whenNotPaused canRunLottery {
		uint gamblersLength = getTicketsCount();
		require(gamblersLength >= QUORUM);

		uint winnersCount = calculateWinnersCount(gamblersLength);
		uint winnerPrize = calculateWinnerPrize(prizeFund, winnersCount);

		int[] memory winners = new int[](winnersCount);

		uint lastWinner = 0;
		bytes32 rnd = block.blockhash(block.number - 1);
		for(uint i = 0; i < winnersCount; i++) {
			lastWinner = generateNextWinner(rnd, lastWinner, winners, gamblers.length);
			winners[i] = int(lastWinner);
			address winnerAddress = gamblers[uint(winners[i])];
			winnerAddress.transfer(winnerPrize);  
			Win(stage, gamblersLength, lastWinner, winnerAddress, winnerPrize);
		}

		setTicketPriceIfNeeded();

		 
		prizeFund = 0;
		gamblers.length = 1;
		stage += 1;
	}

	function getTicketsCount() public view returns (uint) {
		return gamblers.length - 1;
	}

	function setTicketPrice(uint _ticketPrice) external onlyOwner {
		if(getTicketsCount() == 0) {
			ticketPrice = _ticketPrice;
			nextTicketPrice = 0;
		} else {
			nextTicketPrice = _ticketPrice;
		}
	}

	function setMaxTickets(uint _maxTickets) external onlyOwner {
		maxTickets = _maxTickets;
	}

	function setAsLotteryRunner(address addr, bool isAllowedToRun) external onlyOwner {
		lotteryRunners[addr] = isAllowedToRun;
	}

	function setTicketPriceIfNeeded() private {
		if(nextTicketPrice > 0) {
			ticketPrice = nextTicketPrice;
			nextTicketPrice = 0;
		}
	}

	 
	function withdrawEther(address recipient, uint amount) external onlyOwner {
		recipient.transfer(amount);
	}

	function generateNextWinner(bytes32 rnd, uint previousWinner, int[] winners, uint gamblersCount) private view returns(uint) {
		uint nonce = 0;
		uint winner = generateWinner(rnd, previousWinner, nonce, gamblersCount);

		while(isInArray(winner, winners)) {
			nonce += 1;
			winner = generateWinner(rnd, previousWinner, nonce, gamblersCount);
		}

		return winner;
	}

	function generateWinner(bytes32 rnd, uint previousWinner, uint nonce, uint gamblersCount) private pure returns (uint winner) {
		return uint(keccak256(rnd, previousWinner, nonce)) % gamblersCount;
	}

	function isInArray(uint element, int[] array) private pure returns (bool) {
		for(uint64 i = 0; i < array.length; i++) {
			if(uint(array[i]) == element) {
				return true;
			}
		}
		return false;
	}

	function isContract(address _addr) private view returns (bool is_contract) {
		uint length;
		assembly {
			 
			length := extcodesize(_addr)
		}
		return length > 0;
	}

}