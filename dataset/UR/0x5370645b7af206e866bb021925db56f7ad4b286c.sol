 

pragma solidity ^0.5.0;

contract UtilMutualAlliance{
    uint ethWei = 1 ether;

    function getLevel(uint value) internal view returns (uint) {
        if (value >= 1 * ethWei && value <= 5 * ethWei) {
            return 1;
        }
        if (value >= 6 * ethWei && value <= 14 * ethWei) {
            return 2;
        }
        if (value >= 15 * ethWei && value <= 20 * ethWei) {
            return 3;
        }
        return 0;
    }

    function getLineLevel(uint value) internal view returns (uint) {
        if (value >= 1 * ethWei && value <= 5 * ethWei) {
            return 1;
        }
        if (value >= 6 * ethWei && value <= 14 * ethWei) {
            return 2;
        }
        if (value >= 15 * ethWei) {
            return 3;
        }
        return 0;
    }

    function getSepScByLevel(uint level) internal pure returns(uint) {
        if (level == 1) {
            return 65;
        }
        if (level == 2) {
            return 85;
        }
        if (level == 3) {
            return 120;
        }

        return 0;
    }

    function getScByLevel(uint level, uint reInvestCount) internal pure returns (uint) {
        if (level == 1) {
            if (reInvestCount == 0) {
                return 20;
            }
            if (reInvestCount == 1) {
                return 25;
            }
            if (reInvestCount == 2) {
                return 30;
            }
            if (reInvestCount == 3) {
                return 35;
            }
            if (reInvestCount >= 4) {
                return 50;
            }
        }
        if (level == 2) {
            if (reInvestCount == 0) {
                return 30;
            }
            if (reInvestCount == 1) {
                return 40;
            }
            if (reInvestCount == 2) {
                return 50;
            }
            if (reInvestCount == 3) {
                return 60;
            }
            if (reInvestCount >= 4) {
                return 70;
            }
        }
        if (level == 3) {
            if (reInvestCount == 0) {
                return 60;
            }
            if (reInvestCount == 1) {
                return 70;
            }
            if (reInvestCount == 2) {
                return 80;
            }
            if (reInvestCount == 3) {
                return 90;
            }
            if (reInvestCount >= 4) {
                return 100;
            }
        }
        return 0;
    }

    function getFireScByLevel(uint level) internal pure returns (uint) {
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

    function getDynamicFloor(uint level) internal pure returns (uint) {
        if (level == 1) {
            return 1;
        }
        if (level == 2) {
            return 2;
        }
        if (level == 3) {
            return 20;
        }

        return 0;
    }

    function getFloorIndex(uint floor) internal pure returns (uint) {
        if (floor == 1) {
            return 1;
        }
        if (floor == 2) {
            return 2;
        }
        if (floor == 3) {
            return 3;
        }
        if (floor >= 4 && floor <= 5) {
            return 4;
        }
        if (floor >= 6 && floor <= 10) {
            return 5;
        }
        if (floor >= 11) {
            return 6;
        }

        return 0;
    }

    function getRecommendScaleByLevelAndTim(uint level, uint floorIndex) internal pure returns (uint){
        if (level == 1 && floorIndex == 1) {
            return 20;
        }
        if (level == 2) {
            if (floorIndex == 1) {
                return 30;
            }
            if (floorIndex == 2) {
                return 20;
            }
        }
        if (level == 3) {
            if (floorIndex == 1) {
                return 50;
            }
            if (floorIndex == 2) {
                return 30;
            }
            if (floorIndex == 3) {
                return 20;
            }
            if (floorIndex == 4) {
                return 10;
            }
            if (floorIndex == 5) {
                return 5;
            }
            if (floorIndex >= 6) {
                return 2;
            }
        }
        return 0;
    }

    function isEmpty(string memory str) internal pure returns (bool) {
        if (bytes(str).length == 0) {
            return true;
        }

        return false;
    }
}

 
contract Context {
     
     
    constructor() internal {}
     

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
         
        return msg.data;
    }
}

 
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

 
contract WhitelistAdminRole is Context, Ownable {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()) || isOwner(), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function removeWhitelistAdmin(address account) public onlyOwner {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

contract MutualAlliance is UtilMutualAlliance, WhitelistAdminRole {

    using SafeMath for *;

    string constant private name = "MutualAlliance Official";

    uint ethWei = 1 ether;

    address payable private devAddr = address(0x3fd4967d8C5079c2D37cbaac8014c1e9584Fe5Dd);

    address payable private loyal = address(0x0EF71a4b3b37dbAb581bEc482bcd0eE7429917A3);

    address payable private other = address(0x0040E7d9808e9D344158D7379E0b91b61B93CC9F);

    struct User {
        uint id;
        address userAddress;
        uint staticLevel;
        uint dynamicLevel;
        uint allInvest;
        uint freezeAmount;
        uint unlockAmount;
        uint unlockAmountRedeemTime;
        uint allStaticAmount;
        uint hisStaticAmount;
        uint dynamicWithdrawn;
        uint staticWithdrawn;
        Invest[] invests;
        uint staticFlag;

        mapping(uint => mapping(uint => uint)) dynamicProfits;
        uint reInvestCount;
        uint inviteAmount;
        uint solitaire;
        uint hisSolitaire;
    }

    struct UserGlobal {
        uint id;
        address userAddress;
        string inviteCode;
        string referrer;
    }

    struct Invest {
        address userAddress;
        uint investAmount;
        uint investTime;
        uint realityInvestTime;
        uint times;
        uint modeFlag;
        bool isSuspendedInvest;
    }

    uint coefficient = 10;
    uint startTime;
    uint baseTime;
    uint investCount = 0;
    mapping(uint => uint) rInvestCount;
    uint investMoney = 0;
    mapping(uint => uint) rInvestMoney;
    uint uid = 0;
    uint rid = 1;
    uint period = 3 days;
    uint suspendedTime = 0;
    uint suspendedDays = 0 days;
    uint lastInvestTime = 0;
    mapping(uint => mapping(address => User)) userRoundMapping;
    mapping(address => UserGlobal) userMapping;
    mapping(string => address) addressMapping;
    mapping(uint => address) public indexMapping;
    mapping(uint => uint) public everyDayInvestMapping;
    mapping(uint => uint[]) investAmountList;
    mapping(uint => uint) transformAmount;
    uint baseLimit = 300 * ethWei;

     
    modifier isHuman() {
        address addr = msg.sender;
        uint codeLength;

        assembly {codeLength := extcodesize(addr)}
        require(codeLength == 0, "sorry humans only");
        require(tx.origin == msg.sender, "sorry, human only");
        _;
    }

    modifier isSuspended() {
        require(notSuspended(), "suspended");
        _;
    }

    event LogInvestIn(address indexed who, uint indexed uid, uint amount, uint time, uint investTime, string inviteCode, string referrer, uint t);
    event LogWithdrawProfit(address indexed who, uint indexed uid, uint amount, uint time, uint t);
    event LogRedeem(address indexed who, uint indexed uid, uint amount, uint now);

    constructor () public {
    }

    function() external payable {
    }

    function activeGame(uint time, uint _baseTime) external onlyWhitelistAdmin
    {
        require(time > now, "invalid game start time");
        startTime = time;

        if (baseTime == 0) {
            baseTime = _baseTime;
        }
    }

    function setCoefficient(uint coeff, uint _baseLimit) external onlyWhitelistAdmin
    {
        require(coeff > 0, "invalid coeff");
        coefficient = coeff;
        require(_baseLimit > 0, "invalue base limit");
        baseLimit = _baseLimit;
    }

    function gameStart() public view returns (bool) {
        return startTime != 0 && now > startTime;
    }

    function investIn(string memory inviteCode, string memory referrer, uint flag)
    public
    isHuman()
    payable
    {
        require(flag == 0 || flag == 1, "invalid flag");
        require(gameStart(), "game not start");
        require(msg.value >= 1 * ethWei && msg.value <= 20 * ethWei, "between 1 and 20");
        require(msg.value == msg.value.div(ethWei).mul(ethWei), "invalid msg value");
        uint investTime = getInvestTime(msg.value);
        uint investDay = getCurrentInvestDay(investTime);
        everyDayInvestMapping[investDay] = msg.value.add(everyDayInvestMapping[investDay]);
        calUserQueueingStatic(msg.sender);

        UserGlobal storage userGlobal = userMapping[msg.sender];
        if (userGlobal.id == 0) {
            require(!isEmpty(inviteCode), "empty invite code");
            address referrerAddr = getUserAddressByCode(referrer);
            require(uint(referrerAddr) != 0, "referer not exist");
            require(referrerAddr != msg.sender, "referrer can't be self");
            require(!isUsed(inviteCode), "invite code is used");

            registerUser(msg.sender, inviteCode, referrer);
        }

        User storage user = userRoundMapping[rid][msg.sender];
        if (uint(user.userAddress) != 0) {
            require(user.freezeAmount == 0 && user.unlockAmount == 0, "your invest not unlocked");
            user.allInvest = user.allInvest.add(msg.value);
            user.freezeAmount = msg.value;
            user.staticLevel = getLevel(msg.value);
            user.dynamicLevel = getLineLevel(msg.value);
        } else {
            user.id = userGlobal.id;
            user.userAddress = msg.sender;
            user.freezeAmount = msg.value;
            user.staticLevel = getLevel(msg.value);
            user.dynamicLevel = getLineLevel(msg.value);
            user.allInvest = msg.value;
            if (!isEmpty(userGlobal.referrer)) {
                address referrerAddr = getUserAddressByCode(userGlobal.referrer);
                if (referrerAddr != address(0)) {
                    userRoundMapping[rid][referrerAddr].inviteAmount++;
                }
            }
        }
        Invest memory invest = Invest(msg.sender, msg.value, investTime, now, 0, flag, !notSuspended(investTime));
        user.invests.push(invest);
        lastInvestTime = investTime;

        investCount = investCount.add(1);
        investMoney = investMoney.add(msg.value);
        rInvestCount[rid] = rInvestCount[rid].add(1);
        rInvestMoney[rid] = rInvestMoney[rid].add(msg.value);
        
        if (user.staticLevel >= 3) {
            storeSolitaire(msg.sender);
        }
        investAmountList[rid].push(msg.value);

        storeDynamicPreProfits(msg.sender, getDayForProfits(investTime), flag);

        sendFeetoAdmin(msg.value);
        trySendTransform(msg.value);

        emit LogInvestIn(msg.sender, userGlobal.id, msg.value, now, investTime, userGlobal.inviteCode, userGlobal.referrer, 0);
    }

    function reInvestIn() external payable {
        require(gameStart(), "game not start");
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id > 0, "user haven't invest in round before");
        calStaticProfitInner(msg.sender);
        require(user.freezeAmount == 0, "user have had invest in round");
        require(user.unlockAmount > 0, "user must have unlockAmount");
        require(user.unlockAmount.add(msg.value) <= 20 * ethWei, "can not beyond 20 eth");
        require(user.unlockAmount.add(msg.value) == user.unlockAmount.add(msg.value).div(ethWei).mul(ethWei), "invalid msg value");

        bool isEnough;
        uint sendMoney;
        sendMoney = calDynamicProfits(msg.sender);
        if (sendMoney > 0) {
            (isEnough, sendMoney) = isEnoughBalance(sendMoney);

            if (sendMoney > 0) {
                user.dynamicWithdrawn = user.dynamicWithdrawn.add(sendMoney);
                sendMoneyToUser(msg.sender, sendMoney.mul(90).div(100));
                sendMoneyToUser(loyal, sendMoney.mul(10).div(100));
                emit LogWithdrawProfit(msg.sender, user.id, sendMoney, now, 2);
            }
            if (!isEnough) {
                endRound();
                return;
            }
        }

        uint reInvestAmount = user.unlockAmount.add(msg.value);

        uint investTime = now;
        calUserQueueingStatic(msg.sender);

        uint leastAmount = reInvestAmount.mul(4).div(100);
        (isEnough, sendMoney) = isEnoughBalance(leastAmount);
        if (!isEnough) {
            if (sendMoney > 0) {
                sendMoneyToUser(msg.sender, sendMoney);
            }
            endRound();
            return;
        }

        user.unlockAmount = 0;
        user.allInvest = user.allInvest.add(reInvestAmount);
        user.freezeAmount = user.freezeAmount.add(reInvestAmount);
        user.staticLevel = getLevel(user.freezeAmount);
        user.dynamicLevel = getLineLevel(user.freezeAmount);
        user.reInvestCount = user.reInvestCount.add(1);
        user.unlockAmountRedeemTime = 0;

        uint flag = user.invests[user.invests.length-1].modeFlag;
        Invest memory invest = Invest(msg.sender, reInvestAmount, investTime, now, 0, flag, !notSuspended(investTime));
        user.invests.push(invest);
        if (investTime > lastInvestTime) {
            lastInvestTime = investTime;
        }

        investCount = investCount.add(1);
        investMoney = investMoney.add(reInvestAmount);
        rInvestCount[rid] = rInvestCount[rid].add(1);
        rInvestMoney[rid] = rInvestMoney[rid].add(reInvestAmount);
        if (user.staticLevel >= 3) {
            storeSolitaire(msg.sender);
        }
        investAmountList[rid].push(reInvestAmount);
        storeDynamicPreProfits(msg.sender, getDayForProfits(investTime), flag);

        sendFeetoAdmin(reInvestAmount);
        trySendTransform(reInvestAmount);
        emit LogInvestIn(msg.sender, user.id, reInvestAmount, now, investTime, userMapping[msg.sender].inviteCode, userMapping[msg.sender].referrer, 1);
    }

    function storeSolitaire(address user) private {
        uint len = investAmountList[rid].length;
        if (len != 0) {
            uint tmpTotalInvest;
            for (uint i = 1; i <= 20 && i <= len; i++) {
                tmpTotalInvest = tmpTotalInvest.add(investAmountList[rid][len-i]);
            }
            uint reward = tmpTotalInvest.mul(1).div(10000).mul(6);
            if (reward > 0) {
                userRoundMapping[rid][user].solitaire = userRoundMapping[rid][user].solitaire.add(reward);
            }
        }
    }

    function withdrawProfit()
    public
    isHuman()
    {
        require(gameStart(), "game not start");
        User storage user = userRoundMapping[rid][msg.sender];
        calStaticProfitInner(msg.sender);

        uint sendMoney = user.allStaticAmount;

        bool isEnough = false;
        uint resultMoney = 0;
        (isEnough, resultMoney) = isEnoughBalance(sendMoney);
        if (!isEnough) {
            endRound();
        }

        if (resultMoney > 0) {
            sendMoneyToUser(msg.sender, resultMoney);
            user.staticWithdrawn = user.staticWithdrawn.add(sendMoney);
            user.allStaticAmount = 0;
            emit LogWithdrawProfit(msg.sender, user.id, resultMoney, now, 1);
        }
    }

    function isEnoughBalance(uint sendMoney) private view returns (bool, uint){
        if (sendMoney >= address(this).balance) {
            return (false, address(this).balance);
        } else {
            return (true, sendMoney);
        }
    }

    function isEnoughBalanceToRedeem(uint sendMoney, uint reInvestCount, uint hisStaticAmount) private view returns (bool, uint){
        uint deductedStaticAmount = 0;
        if (reInvestCount >= 0 && reInvestCount <= 6) {
            deductedStaticAmount = hisStaticAmount.mul(5).div(10);
            sendMoney = sendMoney.sub(deductedStaticAmount);
        }
        if (reInvestCount > 6 && reInvestCount <= 18) {
            deductedStaticAmount = hisStaticAmount.mul(4).div(10);
            sendMoney = sendMoney.sub(deductedStaticAmount);
        }
        if (reInvestCount > 18 && reInvestCount <= 36) {
            deductedStaticAmount = hisStaticAmount.mul(3).div(10);
            sendMoney = sendMoney.sub(deductedStaticAmount);
        }
        if (reInvestCount >= 37) {
            deductedStaticAmount = hisStaticAmount.mul(1).div(10);
            sendMoney = sendMoney.sub(deductedStaticAmount);
        }
        if (sendMoney >= address(this).balance) {
            return (false, address(this).balance);
        } else {
            return (true, sendMoney);
        }
    }

    function sendMoneyToUser(address payable userAddress, uint money) private {
        userAddress.transfer(money);
    }

    function calStaticProfitInner(address payable userAddr) private returns (uint){
        User storage user = userRoundMapping[rid][userAddr];
        if (user.id == 0 || user.freezeAmount == 0) {
            return 0;
        }
        uint allStatic = 0;
        uint i = user.invests.length.sub(1);
        Invest storage invest = user.invests[i];
        uint scale;
        if (invest.modeFlag == 0) {
            scale = getScByLevel(user.staticLevel, user.reInvestCount);
        } else if (invest.modeFlag == 1) {
            scale = getSepScByLevel(user.staticLevel);
        }
        uint startDay = invest.investTime.sub(8 hours).div(1 days).mul(1 days);
        if (now.sub(8 hours) < startDay) {
            return 0;
        }
        uint staticGaps = now.sub(8 hours).sub(startDay).div(1 days);

        if (staticGaps > 6) {
            staticGaps = 6;
        }
        if (staticGaps > invest.times) {
            if (invest.isSuspendedInvest) {
                allStatic = staticGaps.sub(invest.times).mul(scale).mul(invest.investAmount).div(10000).mul(2);
                invest.times = staticGaps;
            } else {
                allStatic = staticGaps.sub(invest.times).mul(scale).mul(invest.investAmount).div(10000);
                invest.times = staticGaps;
            }
        }

        (uint unlockDay, uint unlockAmountRedeemTime) = getUnLockDay(invest.investTime);

        if (unlockDay >= 6 && user.freezeAmount != 0) {
            user.staticFlag = user.staticFlag.add(1);
            user.freezeAmount = user.freezeAmount.sub(invest.investAmount);
            user.unlockAmount = user.unlockAmount.add(invest.investAmount);
            user.unlockAmountRedeemTime = unlockAmountRedeemTime;
            user.staticLevel = getLevel(user.freezeAmount);

            if (user.solitaire > 0) {
                userAddr.transfer(user.solitaire);
                user.hisSolitaire = user.hisSolitaire.add(user.solitaire);
                emit LogWithdrawProfit(userAddr, user.id, user.solitaire, now, 3);
            }
            user.solitaire = 0;
        }

        allStatic = allStatic.mul(coefficient).div(10);
        user.allStaticAmount = user.allStaticAmount.add(allStatic);
        user.hisStaticAmount = user.hisStaticAmount.add(allStatic);
        return user.allStaticAmount;
    }

    function getStaticProfits(address userAddr) public view returns(uint, uint, uint) {
        User memory user = userRoundMapping[rid][userAddr];
        if (user.id == 0 || user.invests.length == 0) {
            return (0, 0, 0);
        }
        if (user.freezeAmount == 0) {
            return (0, user.hisStaticAmount, user.staticWithdrawn);
        }
        uint allStatic = 0;
        uint i = user.invests.length.sub(1);
        Invest memory invest = user.invests[i];
        uint scale;
        if (invest.modeFlag == 0) {
            scale = getScByLevel(user.staticLevel, user.reInvestCount);
        } else if (invest.modeFlag == 1) {
            scale = getSepScByLevel(user.staticLevel);
        }
        uint startDay = invest.investTime.sub(8 hours).div(1 days).mul(1 days);
        if (now.sub(8 hours) < startDay) {
            return (0, user.hisStaticAmount, user.staticWithdrawn);
        }
        uint staticGaps = now.sub(8 hours).sub(startDay).div(1 days);

        if (staticGaps > 6) {
            staticGaps = 6;
        }
        if (staticGaps > invest.times) {
            if (invest.isSuspendedInvest) {
                allStatic = staticGaps.sub(invest.times).mul(scale).mul(invest.investAmount).div(10000).mul(2);
            } else {
                allStatic = staticGaps.sub(invest.times).mul(scale).mul(invest.investAmount).div(10000);
            }
        }

        allStatic = allStatic.mul(coefficient).div(10);
        return (
            user.allStaticAmount.add(allStatic),
            user.hisStaticAmount.add(allStatic),
            user.staticWithdrawn
        );
    }

    function storeDynamicPreProfits(address userAddr, uint investDay, uint modeFlag) private {
        uint freezeAmount = userRoundMapping[rid][userAddr].freezeAmount;
        if (freezeAmount >= 1 * ethWei) {
            uint scale;
            if (modeFlag == 0) {
                scale = getScByLevel(userRoundMapping[rid][userAddr].staticLevel, userRoundMapping[rid][userAddr].reInvestCount);
            } else if (modeFlag == 1) {
                scale = getSepScByLevel(userRoundMapping[rid][userAddr].staticLevel);
            }
            uint staticMoney = freezeAmount.mul(scale).div(10000);
            updateReferrerPreProfits(userMapping[userAddr].referrer, investDay, staticMoney);
        }
    }

    function updateReferrerPreProfits(string memory referrer, uint day, uint staticMoney) private {
        string memory tmpReferrer = referrer;

        for (uint i = 1; i <= 20; i++) {
            if (isEmpty(tmpReferrer)) {
                break;
            }
            uint floorIndex = getFloorIndex(i);
            address tmpUserAddr = addressMapping[tmpReferrer];
            if (tmpUserAddr == address(0)) {
                break;
            }

            for (uint j = 0; j < 6; j++) {
                uint dayIndex = day.add(j);
                uint currentMoney = userRoundMapping[rid][tmpUserAddr].dynamicProfits[floorIndex][dayIndex];
                userRoundMapping[rid][tmpUserAddr].dynamicProfits[floorIndex][dayIndex] = currentMoney.add(staticMoney);
            }
            tmpReferrer = userMapping[tmpUserAddr].referrer;
        }
    }

    function calDynamicProfits(address user) public view returns (uint) {
        uint len = userRoundMapping[rid][user].invests.length;
        if (len == 0) {
            return 0;
        }
        uint userInvestDay = getDayForProfits(userRoundMapping[rid][user].invests[len - 1].investTime);
        uint totalProfits;

        uint floor;
        uint dynamicLevel = userRoundMapping[rid][user].dynamicLevel;
        floor = getDynamicFloor(dynamicLevel);
        if (floor > 20) {
            floor = 20;
        }
        uint floorCap = getFloorIndex(floor);
        uint fireSc = getFireScByLevel(dynamicLevel);

        for (uint i = 1; i <= floorCap; i++) {
            uint recommendSc = getRecommendScaleByLevelAndTim(dynamicLevel, i);
            for (uint j = 0; j < 6; j++) {
                uint day = userInvestDay.add(j);
                uint staticProfits = userRoundMapping[rid][user].dynamicProfits[i][day];

                if (recommendSc != 0) {
                    uint tmpDynamicAmount = staticProfits.mul(fireSc).mul(recommendSc);
                    totalProfits = tmpDynamicAmount.div(10).div(100).add(totalProfits);
                }
            }
        }

        return totalProfits;
    }

    function registerUserInfo(address user, string calldata inviteCode, string calldata referrer) external onlyOwner {
        registerUser(user, inviteCode, referrer);
    }

    function calUserQueueingStatic(address userAddress) private returns(uint) {
        User storage calUser = userRoundMapping[rid][userAddress];

        uint investLength = calUser.invests.length;
        if (investLength == 0) {
            return 0;
        }

        Invest memory invest = calUser.invests[investLength - 1];
        if (invest.investTime <= invest.realityInvestTime) {
            return 0;
        }

        uint staticGaps = getQueueingStaticGaps(invest.investTime, invest.realityInvestTime);
        if (staticGaps <= 0) {
            return 0;
        }
        uint staticAmount = invest.investAmount.mul(staticGaps).mul(5).div(10000);
        calUser.hisStaticAmount = calUser.hisStaticAmount.add(staticAmount);
        calUser.allStaticAmount = calUser.allStaticAmount.add(staticAmount);
        return staticAmount;
    }

    function getQueueingStaticGaps(uint investTime, uint realityInvestTime) private pure returns (uint){
        if(investTime <= realityInvestTime){
            return 0;
        }
        uint startDay = realityInvestTime.sub(8 hours).div(1 days).mul(1 days);
        uint staticGaps = investTime.sub(8 hours).sub(startDay).div(1 days);
        return staticGaps;
    }

    function redeem()
    public
    isHuman()
    isSuspended()
    {
        require(gameStart(), "game not start");
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id > 0, "user not exist");
        withdrawProfit();
        require(now >= user.unlockAmountRedeemTime, "redeem time non-arrival");

        uint sendMoney = user.unlockAmount;
        require(sendMoney != 0, "you don't have unlock money");
        uint reInvestCount = user.reInvestCount;
        uint hisStaticAmount = user.hisStaticAmount;

        bool isEnough = false;
        uint resultMoney = 0;

        uint index = user.invests.length - 1;
        if (user.invests[index].modeFlag == 0) {
            (isEnough, resultMoney) = isEnoughBalanceToRedeem(sendMoney, reInvestCount, hisStaticAmount);
        } else if (user.invests[index].modeFlag == 1) {
            require(reInvestCount == 4 || (reInvestCount>4 && (reInvestCount-4)%5 == 0), "reInvest time not enough");
            (isEnough, resultMoney) = isEnoughBalance(sendMoney);
        } else {
            revert("invalid flag");
        }

        if (!isEnough) {
            endRound();
        }
        if (resultMoney > 0) {
            sendMoneyToUser(msg.sender, resultMoney);
            user.unlockAmount = 0;
            user.staticLevel = getLevel(user.freezeAmount);
            user.dynamicLevel = 0;
            user.reInvestCount = 0;
            user.hisStaticAmount = 0;
            emit LogRedeem(msg.sender, user.id, resultMoney, now);
        }
    }

    function getUnLockDay(uint investTime) public view returns (uint unlockDay, uint unlockAmountRedeemTime){
        uint gameStartTime = startTime;
        if (gameStartTime <= 0 || investTime > now || investTime < gameStartTime) {
            return (0, 0);
        }
        unlockDay = now.sub(investTime).div(1 days);
        unlockAmountRedeemTime = 0;
        if (unlockDay < 6) {
            return (unlockDay, unlockAmountRedeemTime);
        }
        unlockAmountRedeemTime = investTime.add(uint(6).mul(1 days));

        uint stopTime = suspendedTime;
        if (stopTime == 0) {
            return (unlockDay, unlockAmountRedeemTime);
        }

        uint stopDays = suspendedDays;
        uint stopEndTime = stopTime.add(stopDays.mul(1 days));
        if (investTime < stopTime){
            if(unlockAmountRedeemTime >= stopEndTime){
                unlockAmountRedeemTime = unlockAmountRedeemTime.add(stopDays.mul(1 days));
            }else if(unlockAmountRedeemTime < stopEndTime && unlockAmountRedeemTime > stopTime){
                unlockAmountRedeemTime = stopEndTime.add(unlockAmountRedeemTime.sub(stopTime));
            }
        }
        if (investTime >= stopTime && investTime < stopEndTime){
            if(unlockAmountRedeemTime >= stopEndTime){
                unlockAmountRedeemTime = unlockAmountRedeemTime.add(stopEndTime.sub(investTime));
            }else if(unlockAmountRedeemTime < stopEndTime && unlockAmountRedeemTime > stopTime){
                unlockAmountRedeemTime = stopEndTime.add(uint(6).mul(1 days));
            }
        }
        return (unlockDay, unlockAmountRedeemTime);
    }

    function endRound() private {
        rid++;
        startTime = now.add(period).div(1 days).mul(1 days);
        coefficient = 10;
    }

    function isUsed(string memory code) public view returns (bool) {
        address user = getUserAddressByCode(code);
        return uint(user) != 0;
    }

    function getUserAddressByCode(string memory code) public view returns (address) {
        return addressMapping[code];
    }

    function sendFeetoAdmin(uint amount) private {
        devAddr.transfer(amount.div(25));
    }

    function trySendTransform(uint amount) private {
        if (transformAmount[rid] > 500 * ethWei) {
            return;
        }
        uint sendAmount = amount.div(100);
        transformAmount[rid] = transformAmount[rid].add(sendAmount);
        other.transfer(sendAmount);
    }

    function getGameInfo() public isHuman() view returns (uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        uint dayInvest;
        uint dayLimit;
        dayInvest = everyDayInvestMapping[getCurrentInvestDay(now)];
        dayLimit = getCurrentInvestLimit(now);
        return (
        rid,
        uid,
        startTime,
        investCount,
        investMoney,
        rInvestCount[rid],
        rInvestMoney[rid],
        coefficient,
        dayInvest,
        dayLimit,
        now,
        lastInvestTime
        );
    }

    function getUserInfo(address user, uint roundId) public isHuman() view returns (
        uint[19] memory ct, string memory inviteCode, string memory referrer
    ) {

        if (roundId == 0) {
            roundId = rid;
        }

        User memory userInfo = userRoundMapping[roundId][user];

        ct[0] = userInfo.id;
        ct[1] = userInfo.staticLevel;
        ct[2] = userInfo.dynamicLevel;
        ct[3] = userInfo.allInvest;
        Invest memory invest;
        if (userInfo.invests.length == 0) {
            ct[4] = 0;
        } else {
            invest = userInfo.invests[userInfo.invests.length-1];
            if (invest.modeFlag == 0) {
                ct[4] = getScByLevel(userInfo.staticLevel, userInfo.reInvestCount);
            } else if(invest.modeFlag == 1) {
                ct[4] = getSepScByLevel(userInfo.staticLevel);
            } else {
                ct[4] = 0;
            }
        }
        ct[5] = userInfo.inviteAmount;
        ct[6] = userInfo.freezeAmount;
        ct[7] = userInfo.staticWithdrawn.add(userInfo.dynamicWithdrawn);
        ct[8] = userInfo.staticWithdrawn;
        ct[9] = userInfo.dynamicWithdrawn;
        uint canWithdrawn;
        uint hisWithdrawn;
        uint staticWithdrawn;
        (canWithdrawn, hisWithdrawn, staticWithdrawn) = getStaticProfits(user);
        ct[10] = canWithdrawn;
        ct[11] = calDynamicProfits(user);
        uint lockDay;
        uint redeemTime;
        (lockDay, redeemTime) = getUnLockDay(invest.investTime);
        ct[12] = lockDay;
        ct[13] = redeemTime;
        ct[14] = userInfo.reInvestCount;
        ct[15] = invest.modeFlag;
        ct[16] = userInfo.unlockAmount;
        ct[17] = invest.investTime;
        ct[18] = userInfo.hisSolitaire;

        inviteCode = userMapping[user].inviteCode;
        referrer = userMapping[user].referrer;
        return (
        ct,
        inviteCode,
        referrer
        );
    }

    function getInvestTime(uint amount) public view returns (uint){
        uint lastTime = lastInvestTime;

        uint investTime = 0;

        if (isLessThanLimit(amount, now)) {
            if (now < lastTime) {
                investTime = lastTime.add(1 seconds);
            } else {
                investTime = now;
            }
        } else {
            investTime = lastTime.add(1 seconds);
            if (!isLessThanLimit(amount, investTime)) {
                investTime = getCurrentInvestDay(lastTime).mul(1 days).add(baseTime);
            }
        }
        return investTime;
    }


    function getDayForProfits(uint investTime) private pure returns (uint) {
        return investTime.sub(8 hours).div(1 days);
    }

    function getCurrentInvestLimit(uint investTime) public view returns (uint){
        uint currentDays = getCurrentInvestDay(investTime).sub(1);
        uint currentRound = currentDays.div(6).add(1);
        uint x = 3 ** (currentRound.sub(1));
        uint y = 2 ** (currentRound.sub(1));
        return baseLimit.mul(x).div(y);
    }

    function getCurrentInvestDay(uint investTime) public view returns (uint){
        uint gameStartTime = baseTime;
        if (gameStartTime == 0 || investTime < gameStartTime) {
            return 0;
        }
        uint currentInvestDay = investTime.sub(gameStartTime).div(1 days).add(1);
        return currentInvestDay;
    }
    function isLessThanLimit(uint amount, uint investTime) public view returns (bool){
        return getCurrentInvestLimit(investTime) >= amount.add(everyDayInvestMapping[getCurrentInvestDay(investTime)]);
    }
    function notSuspended() public view returns (bool) {
        uint sTime = suspendedTime;
        uint sDays = suspendedDays;
        return sTime == 0 || now < sTime || now >= sDays.mul(1 days).add(sTime);
    }

    function notSuspended(uint investTime) public view returns (bool) {
        uint sTime = suspendedTime;
        uint sDays = suspendedDays;
        return sTime == 0 || investTime < sTime || investTime >= sDays.mul(1 days).add(sTime);
    }

    function suspended(uint stopTime, uint stopDays) external onlyWhitelistAdmin {
        require(gameStart(), "game not start");
        require(stopTime > now, "stopTime shoule gt now");
        require(stopTime > lastInvestTime, "stopTime shoule gt lastInvestTime");
        suspendedTime = stopTime;
        suspendedDays = stopDays;
    }

    function getUserById(uint id) public view returns (address){
        return indexMapping[id];
    }

    function getAvailableReInvestInAmount(address userAddr) public view returns (uint){
        User memory user = userRoundMapping[rid][userAddr];
        if(user.freezeAmount == 0){
            return user.unlockAmount;
        }else{
            Invest memory invest = user.invests[user.invests.length - 1];
            (uint unlockDay, uint unlockAmountRedeemTime) = getUnLockDay(invest.investTime);
            if(unlockDay >= 6){
                return invest.investAmount;
            }
        }
        return 0;
    }

    function getAvailableRedeemAmount(address userAddr) public view returns (uint){
        User memory user = userRoundMapping[rid][userAddr];
        if (now < user.unlockAmountRedeemTime) {
            return 0;
        }
        uint allUnlock = user.unlockAmount;
        if (user.freezeAmount > 0) {
            Invest memory invest = user.invests[user.invests.length - 1];
            (uint unlockDay, uint unlockAmountRedeemTime) = getUnLockDay(invest.investTime);
            if (unlockDay >= 6 && now >= unlockAmountRedeemTime) {
                allUnlock = invest.investAmount;
            }
            if(invest.modeFlag == 1){
                if(user.reInvestCount < 4 || (user.reInvestCount - 4)%5 != 0){
                    allUnlock = 0;
                }
            }
        }
        return allUnlock;
    }

    function registerUser(address user, string memory inviteCode, string memory referrer) private {
        UserGlobal storage userGlobal = userMapping[user];
        if (userGlobal.id != 0) {
            userGlobal.userAddress = user;
            userGlobal.inviteCode = inviteCode;
            userGlobal.referrer = referrer;
            
            addressMapping[inviteCode] = user;
            indexMapping[uid] = user;
        } else {
            uid++;
            userGlobal.id = uid;
            userGlobal.userAddress = user;
            userGlobal.inviteCode = inviteCode;
            userGlobal.referrer = referrer;
            
            addressMapping[inviteCode] = user;
            indexMapping[uid] = user;
        }
        
    }
}

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "mul overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div zero");
         
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "lower sub bigger");
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "overflow");

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "mod zero");
        return a % b;
    }
}