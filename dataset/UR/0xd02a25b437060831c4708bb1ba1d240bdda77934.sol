 
contract Utillibrary is Whitelist {
     
	using SafeMath for *;

     
    event TransferEvent(address indexed _from, address indexed _to, uint _value, uint time);

     
     
    uint internal ethWei = 10 finney; 

     
	function sendMoneyToUser(address payable userAddress, uint money)
        internal
    {
		if (money > 0) {
			userAddress.transfer(money);
		}
	}

     
	function isEnoughBalance(uint sendMoney)
        internal
        view
        returns (bool, uint)
    {
		if (sendMoney >= address(this).balance) {
			return (false, address(this).balance);
		} else {
			return (true, sendMoney);
		}
	}

     
	function getLevel(uint value)
        public
        view
        returns (uint)
    {
		if (value >= ethWei.mul(1) && value <= ethWei.mul(5)) {
			return 1;
		}
		if (value >= ethWei.mul(6) && value <= ethWei.mul(10)) {
			return 2;
		}
		if (value >= ethWei.mul(11) && value <= ethWei.mul(15)) {
			return 3;
		}
		return 0;
	}

     
	function getNodeLevel(uint value)
        public
        view
        returns (uint)
    {
		if (value >= ethWei.mul(1) && value <= ethWei.mul(5)) {
			return 1;
		}
		if (value >= ethWei.mul(6) && value <= ethWei.mul(10)) {
			return 2;
		}
		if (value >= ethWei.mul(11)) {
			return 3;
		}
		return 0;
	}

     
	function getScaleByLevel(uint level)
        public
        pure
        returns (uint)
    {
		if (level == 1) {
			return 5;
		}
		if (level == 2) {
			return 7;
		}
		if (level == 3) {
			return 10;
		}
		return 0;
	}

     
	function getRecommendScaleByLevelAndTim(uint level, uint times)
        public
        pure
        returns (uint)
    {
		if (level == 1 && times == 1) {
			return 50;
		}
		if (level == 2 && times == 1) {
			return 70;
		}
		if (level == 2 && times == 2) {
			return 50;
		}
		if (level == 3) {
			if (times == 1) {
				return 100;
			}
			if (times == 2) {
				return 70;
			}
			if (times == 3) {
				return 50;
			}
			if (times >= 4 && times <= 10) {
				return 10;
			}
			if (times >= 11 && times <= 20) {
				return 5;
			}
			if (times >= 21) {
				return 1;
			}
		}
		return 0;
	}

     
	function getBurnScaleByLevel(uint level)
        public
        pure
        returns (uint)
    {
		if (level == 1) {
			return 3;
		}
		if (level == 2) {
			return 6;
		}
		if (level == 3) {
			return 10;
		}
		return 0;
	}

     
    function sendMoneyToAddr(address _addr, uint _val)
        public
        payable
        onlyOwner
    {
        require(_addr != address(0), "not the zero address");
        address(uint160(_addr)).transfer(_val);
        emit TransferEvent(address(this), _addr, _val, now);
    }
}


contract HYPlay is Context, HumanChsek, Whitelist, DBUtilli, Utillibrary {
     
	using SafeMath for *;
    using String for string;
    using Address for address;

     
	struct User {
		uint id;
		address userAddress;
        uint lineAmount; 
        uint freezeAmount; 
		uint freeAmount; 
        uint dayBonusAmount; 
        uint bonusAmount; 
		uint inviteAmonut; 
		uint level; 
		uint nodeLevel; 
		uint investTimes; 
		uint rewardIndex; 
		uint lastRwTime; 
	}
	struct AwardData {
        uint time; 
        uint staticAmount; 
		uint oneInvAmount; 
		uint twoInvAmount; 
		uint threeInvAmount; 
	}

     
    event InvestEvent(address indexed _addr, string _code, string _rCode, uint _value, uint time);
    event WithdrawEvent(address indexed _addr, uint _value, uint time);

     
	address payable private devAddr = address(0); 
	address payable private foundationAddr = address(0); 

     
    uint startTime = 0;
	uint canSetStartTime = 1;
	uint period = 1 days;

     
    uint lineStatus = 0;

     
	uint rid = 1;
	mapping(uint => uint) roundInvestCount; 
	mapping(uint => uint) roundInvestMoney; 
	mapping(uint => uint[]) lineArrayMapping; 
     
	mapping(uint => mapping(address => User)) userRoundMapping;
     
	mapping(uint => mapping(address => mapping(uint => AwardData))) userAwardDataMapping;

     
	uint bonuslimit = ethWei.mul(15);
	uint sendLimit = ethWei.mul(100);
	uint withdrawLimit = ethWei.mul(15);

     
	constructor (address _dbAddr, address _devAddr, address _foundationAddr) public {
        db = IDB(_dbAddr);
        devAddr = address(_devAddr).toPayable();
        foundationAddr = address(_foundationAddr).toPayable();
	}

     
	function() external payable {
	}

     
	function actUpdateLine(uint line)
        external
        onlyIfWhitelisted
    {
		lineStatus = line;
	}

     
	function actSetStartTime(uint time)
        external
        onlyIfWhitelisted
    {
		require(canSetStartTime == 1, "verydangerous, limited!");
		require(time > now, "no, verydangerous");
		startTime = time;
		canSetStartTime = 0;
	}

     
	function actEndRound()
        external
        onlyIfWhitelisted
    {
		require(address(this).balance < ethWei.mul(1), "contract balance must be lower than 1 ether");
		rid++;
		startTime = now.add(period).div(1 days).mul(1 days);
		canSetStartTime = 1;
	}

     
	function actAllLimit(uint _bonuslimit, uint _sendLimit, uint _withdrawLimit)
        external
        onlyIfWhitelisted
    {
		require(_bonuslimit >= ethWei.mul(15) && _sendLimit >= ethWei.mul(100) && _withdrawLimit >= ethWei.mul(15), "invalid amount");
		bonuslimit = _bonuslimit;
		sendLimit = _sendLimit;
		withdrawLimit = _withdrawLimit;
	}

     
	function actUserStatus(address addr, uint status)
        external
        onlyIfWhitelisted
    {
		require(status == 0 || status == 1 || status == 2, "bad parameter status");
        _setUser(addr, status);
	}

     
	function calculationBonus(uint start, uint end, uint isUID)
        external
        isHuman()
        onlyIfWhitelisted
    {
		for (uint i = start; i <= end; i++) {
			uint userId = 0;
			if (isUID == 0) {
				userId = lineArrayMapping[rid][i];
			} else {
				userId = i;
			}
			address userAddr = _getIndexMapping(userId);
			User storage user = userRoundMapping[rid][userAddr];
			if (user.freezeAmount == 0 && user.lineAmount >= ethWei.mul(1) && user.lineAmount <= ethWei.mul(15)) {
				user.freezeAmount = user.lineAmount;
				user.level = getLevel(user.freezeAmount);
				user.lineAmount = 0;
				sendFeeToDevAddr(user.freezeAmount);
				countBonus_All(user.userAddress);
			}
		}
	}

     
	function settlement(uint start, uint end)
        external
        onlyIfWhitelisted
    {
		for (uint i = start; i <= end; i++) {
			address userAddr = _getIndexMapping(i);
			User storage user = userRoundMapping[rid][userAddr];

            uint[2] memory user_data;
            (user_data, , ) = _getUserInfo(userAddr);
            uint user_status = user_data[1];

			if (now.sub(user.lastRwTime) <= 12 hours) {
				continue;
			}
			user.lastRwTime = now;

			if (user_status == 1) {
                user.rewardIndex = user.rewardIndex.add(1);
				continue;
			}

             
			uint bonusStatic = 0;
			if (user.id != 0 && user.freezeAmount >= ethWei.mul(1) && user.freezeAmount <= bonuslimit) {
				if (user.investTimes < 5) {
					bonusStatic = bonusStatic.add(user.dayBonusAmount);
					user.bonusAmount = user.bonusAmount.add(bonusStatic);
					user.investTimes = user.investTimes.add(1);
				} else {
					user.freeAmount = user.freeAmount.add(user.freezeAmount);
					user.freezeAmount = 0;
					user.dayBonusAmount = 0;
					user.level = 0;
				}
			}

             
			uint inviteSend = 0;
            if (user_status == 0) {
                inviteSend = getBonusAmount_Dynamic(userAddr, rid, 0, false);
            }

             
			if (bonusStatic.add(inviteSend) <= sendLimit) {
				user.inviteAmonut = user.inviteAmonut.add(inviteSend);
				bool isEnough = false;
				uint resultMoney = 0;
				(isEnough, resultMoney) = isEnoughBalance(bonusStatic.add(inviteSend));
				if (resultMoney > 0) {
					uint foundationMoney = resultMoney.div(10);
					sendMoneyToUser(foundationAddr, foundationMoney);
					resultMoney = resultMoney.sub(foundationMoney);
					address payable sendAddr = address(uint160(userAddr));
					sendMoneyToUser(sendAddr, resultMoney);
				}
			}

            AwardData storage awData = userAwardDataMapping[rid][userAddr][user.rewardIndex];
             
            awData.staticAmount = bonusStatic;
             
            awData.time = now;

             
            user.rewardIndex = user.rewardIndex.add(1);
		}
	}

     
    function withdraw()
        public
        isHuman()
    {
		require(isOpen(), "Contract no open");
		User storage user = userRoundMapping[rid][_msgSender()];
		require(user.id != 0, "user not exist");
		uint sendMoney = user.freeAmount + user.lineAmount;

		require(sendMoney > 0, "Incorrect sendMoney");

		bool isEnough = false;
		uint resultMoney = 0;

		(isEnough, resultMoney) = isEnoughBalance(sendMoney);

        require(resultMoney > 0, "not Enough Balance");

		if (resultMoney > 0 && resultMoney <= withdrawLimit) {
			user.freeAmount = 0;
			user.lineAmount = 0;
			user.nodeLevel = getNodeLevel(user.freezeAmount);
            sendMoneyToUser(_msgSender(), resultMoney);
		}

        emit WithdrawEvent(_msgSender(), resultMoney, now);
	}

     
	function invest(string memory code, string memory rCode)
        public
        payable
        isHuman()
    {
		require(isOpen(), "Contract no open");
		require(_msgValue() >= ethWei.mul(1) && _msgValue() <= ethWei.mul(15), "between 1 and 15");
		require(_msgValue() == _msgValue().div(ethWei).mul(ethWei), "invalid msg value");

        uint[2] memory user_data;
        (user_data, , ) = _getUserInfo(_msgSender());
        uint user_id = user_data[0];

		if (user_id == 0) {
			_registerUser(_msgSender(), code, rCode);
            (user_data, , ) = _getUserInfo(_msgSender());
            user_id = user_data[0];
		}

		uint investAmout;
		uint lineAmount;
		if (isLine()) {
			lineAmount = _msgValue();
		} else {
			investAmout = _msgValue();
		}
		User storage user = userRoundMapping[rid][_msgSender()];
		if (user.id != 0) {
			require(user.freezeAmount.add(user.lineAmount) == 0, "only once invest");
		} else {
			user.id = user_id;
			user.userAddress = _msgSender();
		}
        user.freezeAmount = investAmout;
        user.lineAmount = lineAmount;
        user.level = getLevel(user.freezeAmount);
        user.nodeLevel = getNodeLevel(user.freezeAmount.add(user.freeAmount).add(user.lineAmount));

		roundInvestCount[rid] = roundInvestCount[rid].add(1);
		roundInvestMoney[rid] = roundInvestMoney[rid].add(_msgValue());
		if (!isLine()) {
			sendFeeToDevAddr(_msgValue());
			countBonus_All(user.userAddress);
		} else {
			lineArrayMapping[rid].push(user.id);
		}

        emit InvestEvent(_msgSender(), code, rCode, _msgValue(), now);
	}

     
    function stateView()
        public
        view
        returns (uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint)
    {
		return (
            _getCurrentUserID(),
            rid,
            startTime,
            canSetStartTime,
            roundInvestCount[rid],
            roundInvestMoney[rid],
            bonuslimit,
            sendLimit,
            withdrawLimit,
            lineStatus,
            lineArrayMapping[rid].length
		);
	}

     
	function isOpen()
        public
        view
        returns (bool)
    {
		return startTime != 0 && now > startTime;
	}

     
	function isLine()
        private
        view
        returns (bool)
    {
		return lineStatus != 0;
	}

     
	function getLineUserId(uint index, uint roundId)
        public
        view
        returns (uint)
    {
		require(checkWhitelist(), "Permission denied");
		if (roundId == 0) {
			roundId = rid;
		}
		return lineArrayMapping[rid][index];
	}

     
	function getUserByAddress(
        address addr,
        uint roundId,
        uint rewardIndex,
        bool useRewardIndex
    )
        public
        view
        returns (uint[17] memory info, string memory code, string memory rCode)
    {
		require(checkWhitelist() || _msgSender() == addr, "Permission denied for view user's privacy");

		if (roundId == 0) {
			roundId = rid;
		}

        uint[2] memory user_data;
        (user_data, code, rCode) = _getUserInfo(addr);
        uint user_id = user_data[0];
        uint user_status = user_data[1];

		User memory user = userRoundMapping[roundId][addr];

        uint historyDayBonusAmount = 0;
        uint settlementbonustime = 0;
        if (useRewardIndex)
        {
            AwardData memory awData = userAwardDataMapping[roundId][user.userAddress][rewardIndex];
            historyDayBonusAmount = awData.staticAmount;
            settlementbonustime = awData.time;
        }

        uint grantAmount = 0;
		if (user.id > 0 && user.freezeAmount >= ethWei.mul(1) && user.freezeAmount <= bonuslimit && user.investTimes < 5 && user_status != 1) {
            if (!useRewardIndex)
            {
                grantAmount = grantAmount.add(user.dayBonusAmount);
            }
		}

        grantAmount = grantAmount.add(getBonusAmount_Dynamic(addr, roundId, rewardIndex, useRewardIndex));

		info[0] = user_id;
		info[1] = user.lineAmount; 
        info[2] = user.freezeAmount; 
        info[3] = user.freeAmount; 
        info[4] = user.dayBonusAmount; 
        info[5] = user.bonusAmount; 
        info[6] = grantAmount; 
		info[7] = user.inviteAmonut; 
        info[8] = user.level; 
        info[9] = user.nodeLevel; 
        info[10] = _getRCodeMappingLength(code); 
        info[11] = user.investTimes; 
		info[12] = user.rewardIndex; 
        info[13] = user.lastRwTime; 
        info[14] = user_status; 
        info[15] = historyDayBonusAmount; 
        info[16] = settlementbonustime; 

		return (info, code, rCode);
	}

     
	function countBonus_All(address addr)
        private
    {
		User storage user = userRoundMapping[rid][addr];
		if (user.id == 0) {
			return;
		}
		uint staticScale = getScaleByLevel(user.level);
		user.dayBonusAmount = user.freezeAmount.mul(staticScale).div(1000);
		user.investTimes = 0;

        uint[2] memory user_data;
        string memory user_rCode;
        (user_data, , user_rCode) = _getUserInfo(addr);
        uint user_status = user_data[1];

		if (user.freezeAmount >= ethWei.mul(1) && user.freezeAmount <= bonuslimit && user_status == 0) {
			countBonus_Dynamic(user_rCode, user.freezeAmount, staticScale);
		}
	}

     
	function countBonus_Dynamic(string memory rCode, uint money, uint staticScale)
        private
    {
		string memory tmpReferrerCode = rCode;

		for (uint i = 1; i <= 25; i++) {
			if (tmpReferrerCode.compareStr("")) {
				break;
			}
			address tmpUserAddr = _getCodeMapping(tmpReferrerCode);
			User memory tmpUser = userRoundMapping[rid][tmpUserAddr];

            string memory tmpUser_rCode;
            (, , tmpUser_rCode) = _getUserInfo(tmpUserAddr);

			if (tmpUser.freezeAmount.add(tmpUser.freeAmount).add(tmpUser.lineAmount) == 0) {
				tmpReferrerCode = tmpUser_rCode;
				continue;
			}

             
             
			uint recommendScale = getRecommendScaleByLevelAndTim(3, i);
			uint moneyResult = 0;
			if (money <= ethWei.mul(15)) {
				moneyResult = money;
			} else {
				moneyResult = ethWei.mul(15);
			}

			if (recommendScale != 0) {
				uint tmpDynamicAmount = moneyResult.mul(staticScale).mul(recommendScale);
				tmpDynamicAmount = tmpDynamicAmount.div(1000).div(100);
				recordAwardData(tmpUserAddr, tmpDynamicAmount, tmpUser.rewardIndex, i);
			}
			tmpReferrerCode = tmpUser_rCode;
		}
	}

     
	function recordAwardData(address addr, uint awardAmount, uint rewardIndex, uint times)
        private
    {
		for (uint i = 0; i < 5; i++) {
			AwardData storage awData = userAwardDataMapping[rid][addr][rewardIndex.add(i)];
			if (times == 1) {
				awData.oneInvAmount = awData.oneInvAmount.add(awardAmount);
			}
			if (times == 2) {
				awData.twoInvAmount = awData.twoInvAmount.add(awardAmount);
			}
			awData.threeInvAmount = awData.threeInvAmount.add(awardAmount);
		}
	}

     
	function sendFeeToDevAddr(uint amount)
        private
    {
        sendMoneyToUser(devAddr, amount.div(25));
	}

     
	function getBonusAmount_Dynamic(
        address addr,
        uint roundId,
        uint rewardIndex,
        bool useRewardIndex
    )
        private
        view
        returns (uint)
    {
        uint resultAmount = 0;
		User memory user = userRoundMapping[roundId][addr];

        if (!useRewardIndex) {
			rewardIndex = user.rewardIndex;
		}

        uint[2] memory user_data;
        (user_data, , ) = _getUserInfo(addr);
        uint user_status = user_data[1];

        uint lineAmount = user.freezeAmount.add(user.freeAmount).add(user.lineAmount);
		if (user_status == 0 && lineAmount >= ethWei.mul(1) && lineAmount <= withdrawLimit) {
			uint inviteAmount = 0;
			AwardData memory awData = userAwardDataMapping[roundId][user.userAddress][rewardIndex];
            uint lineValue = lineAmount.div(ethWei);
            if (lineValue >= 15) {
                inviteAmount = inviteAmount.add(awData.threeInvAmount);
            } else {
                if (user.nodeLevel == 1 && lineAmount >= ethWei.mul(1) && awData.oneInvAmount > 0) {
                     
                    inviteAmount = inviteAmount.add(awData.oneInvAmount.div(15).mul(lineValue).div(2));
                }
                if (user.nodeLevel == 2 && lineAmount >= ethWei.mul(1) && (awData.oneInvAmount > 0 || awData.twoInvAmount > 0)) {
                     
                    inviteAmount = inviteAmount.add(awData.oneInvAmount.div(15).mul(lineValue).mul(7).div(10));
                     
                    inviteAmount = inviteAmount.add(awData.twoInvAmount.div(15).mul(lineValue).mul(5).div(7));
                }
                if (user.nodeLevel == 3 && lineAmount >= ethWei.mul(1) && awData.threeInvAmount > 0) {
                    inviteAmount = inviteAmount.add(awData.threeInvAmount.div(15).mul(lineValue));
                }
                if (user.nodeLevel < 3) {
                     
                    uint burnScale = getBurnScaleByLevel(user.nodeLevel);
                    inviteAmount = inviteAmount.mul(burnScale).div(10);
                }
            }
            resultAmount = resultAmount.add(inviteAmount);
		}

        return resultAmount;
	}
}