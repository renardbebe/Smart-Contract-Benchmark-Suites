 

pragma solidity ^0.4.24;

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


contract BlockWar {
    using SafeMath for uint256;
    address owner;
    mapping (uint => mapping(address => uint)) public leftUserBlockNumber;
    mapping (uint => mapping(address => uint)) public rightUserBlockNumber;
    mapping (uint => bool) public mapGameLeftWin;   
    mapping (uint => uint) public mapGamePrizePerBlock;   
    mapping (address => uint) public userWithdrawRound;   
    uint currentRound = 0;
    uint leftBlockNumber = 0;
    uint rightBlockNumber = 0;
    uint maxBlockNumber = 500;  
    uint buildFee = 100 finney;
    uint gameStartTimestamp;   
    uint gameIntervalTimestamp = 600;   
    uint gamePrizePool = 0;   
    uint public gameLength = 10800;  
    uint public doCallNumber;
     
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    modifier onlyInGame() {
        require(now > gameStartTimestamp);
        _;
    }

     
    function setOwner (address _owner) onlyOwner() public {
        owner = _owner;
    }

    function BlockWar() public {
        owner = msg.sender;
        gameStartTimestamp = 1535605200;   
    }

    function getBlockBuildFee(uint currentBlockNumber) public view returns(uint) {
        if (currentBlockNumber <= 10) {
            return 0;
        }
        if (currentBlockNumber <= 20) {
            return buildFee.div(4);
        }
		if (currentBlockNumber <= 100) {
			return buildFee.div(2);   
		}
		if (currentBlockNumber <= 200) {
			return buildFee.mul(3).div(4);   
		}
		return buildFee;  
    }

    function buildLeft(address inviteAddress, uint blockNumber) public payable onlyInGame {
    	uint totalMoney = buildFee.mul(blockNumber);
    	require(msg.value >= totalMoney);
        require(blockNumber > 0);
        uint excess = msg.value.sub(totalMoney);
        uint totalBuildFee = 0;
        for (uint i=leftBlockNumber;i<leftBlockNumber+blockNumber;i++) {
    		totalBuildFee = totalBuildFee.add(getBlockBuildFee(i+1));
        }
        excess = excess.add(totalMoney.sub(totalBuildFee));
        if (excess > 0) {
        	msg.sender.transfer(excess);
        }
         
        uint devFee = 0;
        uint inviteFee = 0;
        devFee = totalBuildFee.mul(4).div(100);
        if (inviteAddress != address(0)) {
    		inviteFee = totalBuildFee.mul(3).div(100);
        } else {
    		devFee = totalBuildFee.mul(7).div(100);   
        }
        owner.transfer(devFee);
        if (inviteFee > 0) {
    		inviteAddress.transfer(inviteFee);
        }
        leftBlockNumber = leftBlockNumber.add(blockNumber);
        gamePrizePool = gamePrizePool.add(totalBuildFee.sub(devFee).sub(inviteFee));

         
        leftUserBlockNumber[currentRound][msg.sender] += blockNumber;
       	 
       	trigger_game_end(totalBuildFee);
    }

    function buildRight(address inviteAddress, uint blockNumber) public payable onlyInGame {
		uint totalMoney = buildFee.mul(blockNumber);
		require(msg.value >= totalMoney);
        require(blockNumber > 0);
        uint excess = msg.value.sub(totalMoney);
        uint totalBuildFee = 0;
        for (uint i=rightBlockNumber;i<rightBlockNumber+blockNumber;i++) {
    		totalBuildFee = totalBuildFee.add(getBlockBuildFee(i+1));
        }
        excess = excess.add(totalMoney.sub(totalBuildFee));
        if (excess > 0) {
        	msg.sender.transfer(excess);
        }
         
        uint devFee = 0;
        uint inviteFee = 0;
        devFee = totalBuildFee.mul(4).div(100);
        if (inviteAddress != address(0)) {
    		inviteFee = totalBuildFee.mul(3).div(100);
        } else {
    		devFee = totalBuildFee.mul(7).div(100);   
        }
        owner.transfer(devFee);
        if (inviteFee > 0) {
    		inviteAddress.transfer(inviteFee);
        }
        rightBlockNumber = rightBlockNumber.add(blockNumber);
        gamePrizePool = gamePrizePool.add(totalBuildFee.sub(devFee).sub(inviteFee));

         
        rightUserBlockNumber[currentRound][msg.sender] += blockNumber;
       	 
       	trigger_game_end(totalBuildFee);
    }

    function trigger_game_end(uint totalBuildFee) private onlyInGame {
		 
		bool gameEnd = false;
		if (rightBlockNumber > maxBlockNumber) {
				gameEnd = true;
		}
		if (leftBlockNumber > maxBlockNumber) {
				gameEnd = true;
		}
		if (now.sub(gameStartTimestamp) > gameLength) {
				gameEnd = true;
		}
		if (gameEnd) {
			uint maxUserPrize = gamePrizePool.mul(3).div(100);
			uint nextGamePrizePool = gamePrizePool.div(10);
			if (gamePrizePool > 0) {
					msg.sender.transfer(maxUserPrize);
			}
			gamePrizePool = gamePrizePool.sub(maxUserPrize).sub(nextGamePrizePool);
			uint prizePerBlock = 0;
			if (leftBlockNumber > maxBlockNumber) {
				 
				if (rightBlockNumber > 0) {
				    prizePerBlock = gamePrizePool/rightBlockNumber;
				} else {
				    owner.transfer(gamePrizePool);
				    prizePerBlock = 0;
				}
				mapGameLeftWin[currentRound] = false;
			} else if (rightBlockNumber > maxBlockNumber) {
				 
				if (leftBlockNumber > 0) {
				    prizePerBlock = gamePrizePool/leftBlockNumber;
				} else {
				    owner.transfer(gamePrizePool);
				    prizePerBlock = 0;
				}
				mapGameLeftWin[currentRound] = true;
			} else {
				if (leftBlockNumber >= rightBlockNumber) {
					 
					prizePerBlock = gamePrizePool/leftBlockNumber;
					mapGameLeftWin[currentRound] = true;
				} else {
					 
					prizePerBlock = gamePrizePool/rightBlockNumber;
					mapGameLeftWin[currentRound] = false;
				}
			}
			 
			mapGamePrizePerBlock[currentRound] = prizePerBlock;
			 
			gamePrizePool = nextGamePrizePool;
			gameStartTimestamp = now + gameIntervalTimestamp;   
			currentRound += 1;
			leftBlockNumber = 0;
			rightBlockNumber = 0;
		}
    }

    function getUserMoney(address userAddress) public view returns(uint){
		uint userTotalPrize = 0;
		for (uint i=userWithdrawRound[userAddress]; i<currentRound;i++) {
			if (mapGameLeftWin[i]) {
				userTotalPrize = userTotalPrize.add(leftUserBlockNumber[i][userAddress].mul(mapGamePrizePerBlock[i]));
			} else {
				userTotalPrize = userTotalPrize.add(rightUserBlockNumber[i][userAddress].mul(mapGamePrizePerBlock[i]));
			}
		}
		return userTotalPrize;
    }

    function withdrawUserPrize() public {
		require(currentRound > 0);
		uint userTotalPrize = getUserMoney(msg.sender);
		userWithdrawRound[msg.sender] = currentRound;
		if (userTotalPrize > 0) {
			msg.sender.transfer(userTotalPrize);
		}
    }

    function daCall() public {
        doCallNumber += 1;
    }

    function getGameStats() public view returns(uint[]) {
         
         
         
         
         
         
        uint[] memory result = new uint[](8);
        uint userPrize = getUserMoney(msg.sender);
        result[0] = currentRound;
        result[1] = gameStartTimestamp;
        result[2] = leftBlockNumber;
        result[3] = rightBlockNumber;
        result[4] = gamePrizePool;
        result[5] = userPrize;
        result[6] = leftUserBlockNumber[currentRound][msg.sender];
        result[7] = rightUserBlockNumber[currentRound][msg.sender];
        return result;
    }
}