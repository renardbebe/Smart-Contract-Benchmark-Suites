 

pragma solidity ^0.4.26;


contract UtilGameFair {
    uint ethWei = 1 ether;

    function getLevel(uint value) public view returns (uint) {
        if (value >= 1 * ethWei && value <= 5 * ethWei) {
            return 1;
        }
        if (value >= 6 * ethWei && value <= 10 * ethWei) {
            return 2;
        }
        if (value >= 11 * ethWei && value <= 15 * ethWei) {
            return 3;
        }
        return 0;
    }

    function getLineLevel(uint value) public view returns (uint) {
        if (value >= 1 * ethWei && value <= 5 * ethWei) {
            return 1;
        }
        if (value >= 6 * ethWei && value <= 10 * ethWei) {
            return 2;
        }
        if (value >= 11 * ethWei) {
            return 3;
        }
        return 0;
    }

    function getScByLevel(uint level) public pure returns (uint) {
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

    function getFireScByLevel(uint level) public pure returns (uint) {
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

    function getRecommendScaleByLevelAndTim(uint level, uint times) public pure returns (uint){
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

    function compareStr(string memory _str, string memory str) public pure returns (bool) {
        if (keccak256(abi.encodePacked(_str)) == keccak256(abi.encodePacked(str))) {
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

contract GameFair is UtilGameFair, WhitelistAdminRole {

    using SafeMath for *;

    string constant private name = "GameFair Official";

    uint ethWei = 1 ether;

    address  private devAddr = address(0x933a751586E7A0658513D1113521A92d9c41fe58);

    struct User {
        uint id;
        address userAddress;
        string inviteCode;
        string referrer;
        uint staticLevel;
        uint dynamicLevel;
        uint allInvest;
        uint freezeAmount;
        uint unlockAmount;
        uint allStaticAmount;
        uint allDynamicAmount;
        uint hisStaticAmount;
        uint hisDynamicAmount;
        Invest[] invests;
        SeizeInvest[] seizesInvests;
        uint votes;
        uint staticFlag;
    }

    struct UserGlobal {
        uint id;
        address userAddress;
        string inviteCode;
        string referrer;
        uint inviteCount;
    }

    struct Invest {
        address userAddress;
        uint investAmount;
        uint investTime;
        uint times;
    }

    struct SeizeInvest {
        uint rid;
        address userAddress;
        uint seizeAmount;
        uint seizeTime;
    }

    string constant systemCode = "99999999";
    uint startTime;
    uint investCount = 0;
    mapping(uint => uint) rInvestCount;
    uint investMoney = 0;
    mapping(uint => uint) rInvestMoney;
    uint userAssets = 0;

    uint uid = 0;
    uint rid = 1;
    uint period = 6 hours;

    uint voteStartSc = 80;
    uint gameStatus = 1;
    uint voteEndTime = 0;
    uint seizeEndTime = 0;

    uint[] voteResult = [0, 0];
    mapping(uint => SeizeInvest) lastSeizeInvest;

    mapping(uint => mapping(address => User)) userRoundMapping;
    mapping(address => UserGlobal) userMapping;
    mapping(string => address) addressMapping;
    mapping(uint => address) public indexMapping;

    modifier isHuman() {
        address addr = msg.sender;
        uint codeLength;

        assembly {codeLength := extcodesize(addr)}
        require(codeLength == 0, "sorry humans only");
        require(tx.origin == msg.sender, "sorry, human only");
        _;
    }

    event LogInvestIn(address indexed who, uint indexed uid, uint amount, uint time, string inviteCode, string referrer);
    event LogWithdrawProfit(address indexed who, uint indexed uid, uint amount, uint time);
    event LogRedeem(address indexed who, uint indexed uid, uint amount, uint now);
    event VoteStart(uint startTime, uint endTime);
    event SeizeInvestNow(address indexed who, uint indexed uid, uint amount, uint now);

    constructor () public {
        startTime = now;
    }

    function() external payable {
    }

    function gameStart() public view returns (bool) {
        return startTime != 0 && now > startTime && gameStatus == 1;
    }

    function investIn(string memory inviteCode, string memory referrer) public isHuman() payable {
        require(now > startTime && gameStatus == 1, "invest is not allowed now");
        require(msg.value >= 1 * ethWei && msg.value <= 15 * ethWei, "between 1 and 15");
        require(msg.value == msg.value.div(ethWei).mul(ethWei), "invalid msg value");

        UserGlobal storage userGlobal = userMapping[msg.sender];
        if (userGlobal.id == 0) {
            require(!compareStr(inviteCode, ""), "empty invite code");
            address referrerAddr = getUserAddressByCode(referrer);
            require(uint(referrerAddr) != 0, "referer not exist");
            require(referrerAddr != msg.sender, "referrer can't be self");
            require(!isUsed(inviteCode), "invite code is used");
            registerUser(msg.sender, inviteCode, referrer);
        }

        User storage user = userRoundMapping[rid][msg.sender];
        if (uint(user.userAddress) != 0) {
            require(user.freezeAmount.add(msg.value) <= 15 * ethWei, "can not beyond 15 eth");
            user.allInvest = user.allInvest.add(msg.value);
            user.freezeAmount = user.freezeAmount.add(msg.value);
            user.staticLevel = getLevel(user.freezeAmount);
            user.dynamicLevel = getLineLevel(user.freezeAmount.add(user.unlockAmount));
        } else {
            user.id = userGlobal.id;
            user.userAddress = msg.sender;
            user.freezeAmount = msg.value;
            user.staticLevel = getLevel(msg.value);
            user.allInvest = msg.value;
            user.dynamicLevel = getLineLevel(msg.value);
            user.inviteCode = userGlobal.inviteCode;
            user.referrer = userGlobal.referrer;
        }

        Invest memory invest = Invest(msg.sender, msg.value, now, 0);
        user.invests.push(invest);
        user.votes += (msg.value.div(ethWei));

        investCount = investCount.add(1);
        investMoney = investMoney.add(msg.value);
        rInvestCount[rid] = rInvestCount[rid].add(1);
        rInvestMoney[rid] = rInvestMoney[rid].add(msg.value);
        userAssets += msg.value;
        sendFeetoAdmin(msg.value);
        emit LogInvestIn(msg.sender, userGlobal.id, msg.value, now, userGlobal.inviteCode, userGlobal.referrer);
    }

    function seizeInvest(string memory inviteCode) public isHuman() payable {
        require(seizeEndTime > now, "seize invest not start");
        require(!compareStr(inviteCode, ""), "empty invite code");
        require(msg.value >= 1 * ethWei && msg.value <= 15 * ethWei, "between 1 and 15");
        require(msg.value == msg.value.div(ethWei).mul(ethWei), "invalid msg value");

        UserGlobal storage userGlobal = userMapping[msg.sender];
        if (userGlobal.id == 0) {
            require(!isUsed(inviteCode), "invite code is used");
            registerUser(msg.sender, inviteCode, "");
        }
        User storage user = userRoundMapping[rid][msg.sender];
        SeizeInvest memory si = SeizeInvest(rid, msg.sender, msg.value, now);
        if (uint(user.userAddress) != 0) {
            user.unlockAmount = user.unlockAmount.add(msg.value);
            user.allInvest += msg.value;
        } else {
            user.id = userGlobal.id;
            user.userAddress = msg.sender;
            user.allInvest = msg.value;
            user.inviteCode = userGlobal.inviteCode;
            user.referrer = userGlobal.referrer;
            user.unlockAmount = msg.value;
        }
        user.seizesInvests.push(si);
        investMoney = investMoney.add(msg.value);
        userAssets += msg.value;
        lastSeizeInvest[rid] = si;
        emit SeizeInvestNow(msg.sender, userGlobal.id, msg.value, now);
    }

    function voteComplete() external onlyWhitelistAdmin {
        require(gameStatus == 2, "game status error");
        if (voteResult[0] > voteResult[1]) {
            startTime = now.add(period);
            voteStartSc = 80;
            uint sc = address(this).balance.mul(100).div(userAssets);
            for (uint i = 1; i <= uid; i++) {
                address userAddr = indexMapping[i];
                User storage previousUser = userRoundMapping[rid][userAddr];
                User storage curUser = userRoundMapping[rid + 1][userAddr];
                curUser.id = previousUser.id;
                curUser.userAddress = previousUser.userAddress;
                curUser.inviteCode = previousUser.inviteCode;
                curUser.referrer = previousUser.referrer;
                curUser.allInvest = previousUser.allInvest;
                curUser.unlockAmount = previousUser.freezeAmount.add(previousUser.unlockAmount).mul(sc).div(100);
                curUser.freezeAmount = 0;
                curUser.allStaticAmount = previousUser.allStaticAmount.mul(sc).div(100);
                curUser.allDynamicAmount = previousUser.allDynamicAmount.mul(sc).div(100);
                curUser.votes = curUser.unlockAmount.div(ethWei);
                curUser.hisStaticAmount = previousUser.hisStaticAmount;
                curUser.hisDynamicAmount = previousUser.hisDynamicAmount;
                curUser.staticLevel = 0;
                curUser.dynamicLevel = getLineLevel(curUser.unlockAmount);
            }
            rid++;
        } else {
            for (i = 1; i <= uid; i++) {
                userAddr = indexMapping[i];
                curUser = userRoundMapping[rid][userAddr];
                curUser.votes = curUser.freezeAmount.add(curUser.unlockAmount).div(ethWei);
            }
            lastSeizeInvest[rid] = SeizeInvest(rid, 0x00, 0, 0);
        }

        gameStatus = 1;
        voteResult = [0, 0];
    }

    function withdrawProfit()
    public
    isHuman() {
        require(now > startTime && gameStatus == 1, "now not withdrawal");
        User storage user = userRoundMapping[rid][msg.sender];
        uint sendMoney = user.allStaticAmount.add(user.allDynamicAmount);

        bool isEnough = false;
        uint resultMoney = 0;
        (isEnough, resultMoney) = isEnoughBalance(sendMoney);
        if (!isEnough) {
            endRound();
        }

        if (resultMoney > 0) {
            sendMoneyToUser(msg.sender, resultMoney);
            user.allStaticAmount = 0;
            user.allDynamicAmount = 0;
            userAssets -= resultMoney;
            checkVote();
            emit LogWithdrawProfit(msg.sender, user.id, resultMoney, now);
        }
    }

    function isEnoughBalance(uint sendMoney) private view returns (bool, uint) {
        if (sendMoney >= address(this).balance) {
            return (false, address(this).balance);
        } else {
            return (true, sendMoney);
        }
    }

    function sendMoneyToUser(address userAddress, uint money) private {
        userAddress.transfer(money);
    }

    function calStaticProfit(address userAddr) external onlyWhitelistAdmin returns (uint) {
        return calStaticProfitInner(userAddr);
    }

    function calStaticProfitInner(address userAddr) private returns (uint) {
        User storage user = userRoundMapping[rid][userAddr];
        if (user.id == 0) {
            return 0;
        }

        uint scale = getScByLevel(user.staticLevel);
        uint allStatic = 0;
        for (uint i = user.staticFlag; i < user.invests.length; i++) {
            Invest storage invest = user.invests[i];
            uint startDay = invest.investTime.sub(8 hours).div(1 days).mul(1 days);
            uint staticGaps = now.sub(8 hours).sub(startDay).div(1 days);
            uint unlockDay = now.sub(invest.investTime).div(1 days);

            if (staticGaps > 5) {
                staticGaps = 5;
            }
            if (staticGaps > invest.times) {
                allStatic += staticGaps.sub(invest.times).mul(scale).mul(invest.investAmount).div(1000);
                invest.times = staticGaps;
            }

            if (unlockDay >= 5) {
                user.staticFlag++;
                user.freezeAmount = user.freezeAmount.sub(invest.investAmount);
                user.unlockAmount = user.unlockAmount.add(invest.investAmount);
                user.staticLevel = getLevel(user.freezeAmount);
            }
        }
        allStatic = allStatic.mul(getCoefficientInner()).div(100);
        user.allStaticAmount = user.allStaticAmount.add(allStatic);
        user.hisStaticAmount = user.hisStaticAmount.add(allStatic);
        userRoundMapping[rid][userAddr] = user;
        userAssets += allStatic;
        return user.allStaticAmount;
    }

    function calDynamicProfit(uint start, uint end) external onlyWhitelistAdmin {
        for (uint i = start; i <= end; i++) {
            address userAddr = indexMapping[i];
            User memory user = userRoundMapping[rid][userAddr];
            calStaticProfitInner(userAddr);
            if (user.freezeAmount >= 1 * ethWei) {
                uint scale = getScByLevel(user.staticLevel);
                calUserDynamicProfit(user.referrer, user.freezeAmount, scale);
            }
        }
        checkVote();
    }

    function registerUserInfo(address user, string inviteCode, string referrer) external onlyOwner {
        registerUser(user, inviteCode, referrer);
    }

    function calUserDynamicProfit(string memory referrer, uint money, uint shareSc) internal {
        string memory tmpReferrer = referrer;
        for (uint i = 1; i <= 30; i++) {
            if (compareStr(tmpReferrer, "")) {
                break;
            }
            address tmpUserAddr = addressMapping[tmpReferrer];
            User storage calUser = userRoundMapping[rid][tmpUserAddr];

            uint fireSc = getFireScByLevel(calUser.staticLevel);
            uint recommendSc = getRecommendScaleByLevelAndTim(calUser.dynamicLevel, i);
            uint moneyResult = 0;
            if (money <= calUser.freezeAmount.add(calUser.unlockAmount)) {
                moneyResult = money;
            } else {
                moneyResult = calUser.freezeAmount.add(calUser.unlockAmount);
            }

            if (recommendSc != 0) {
                uint tmpDynamicAmount = moneyResult.mul(shareSc).mul(fireSc).mul(recommendSc);
                tmpDynamicAmount = tmpDynamicAmount.div(1000).div(10).div(100);

                tmpDynamicAmount = tmpDynamicAmount.mul(getCoefficientInner()).div(100);
                calUser.allDynamicAmount = calUser.allDynamicAmount.add(tmpDynamicAmount);
                calUser.hisDynamicAmount = calUser.hisDynamicAmount.add(tmpDynamicAmount);
                userAssets += tmpDynamicAmount;
            }

            tmpReferrer = calUser.referrer;
        }
    }

    function checkVote() internal {
        uint thisBalance = address(this).balance;
        uint sc = thisBalance.mul(100).div(userAssets);
        if (sc < 80 && sc > 60 && voteStartSc == 80) {
            voteStart(60);
        } else if (sc < 60 && sc > 40 && voteStartSc == 60) {
            voteStart(40);
        } else if (sc < 40 && sc > 20 && voteStartSc == 40) {
            voteStart(20);
        } else if (sc < 20 && sc > 0 && voteStartSc == 20) {
            voteStart(0);
        }
    }

    function voteStart(uint nextSc) internal {
        voteStartSc = nextSc;
        gameStatus = 2;
        voteEndTime = now.add(120 minutes);
        seizeEndTime = now.add(30 minutes);
        emit VoteStart(now, voteEndTime);
    }

    function redeem() public isHuman() {
        require(now > startTime && gameStatus == 1, "now not withdrawal");
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id > 0, "user not exist");

        calStaticProfitInner(msg.sender);

        uint sendMoney = user.unlockAmount;
        bool isEnough = false;
        uint resultMoney = 0;

        (isEnough, resultMoney) = isEnoughBalance(sendMoney);
        if (!isEnough) {
            endRound();
        }

        if (resultMoney > 0) {
            sendMoneyToUser(msg.sender, resultMoney);
            user.unlockAmount = 0;
            user.staticLevel = getLevel(user.freezeAmount);
            user.dynamicLevel = getLineLevel(user.freezeAmount);
            userAssets -= resultMoney;
            user.votes -= (resultMoney.div(ethWei));
            checkVote();
            emit LogRedeem(msg.sender, user.id, resultMoney, now);
        }
    }

    function vote(uint voteCount, uint voteIntent) public isHuman() {
        require(voteCount > 0, "vote count error");
        require(gameStatus == 2 && voteEndTime > now, "vote not start");
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.votes >= voteCount, "vote count error");
        if (voteIntent == 0) {
            voteResult[0] += voteCount;
        } else {
            voteResult[1] += voteCount;
        }
        user.votes -= voteCount;
    }

    function reInvestIn(uint investAmount) public isHuman() {
        require(now > startTime && gameStatus == 1, "invest is not allowed now");
        require(investAmount == investAmount.div(ethWei).mul(ethWei), "invalid msg value");
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.unlockAmount >= investAmount && investAmount > 0, "reinvest count error");
        uint allFreezeAmount = user.freezeAmount.add(investAmount);
        require(allFreezeAmount <= 15 * ethWei, "can not beyond 15 eth");
        user.unlockAmount = user.unlockAmount.sub(investAmount);
        user.freezeAmount = user.freezeAmount.add(investAmount);
        user.staticLevel = getLevel(user.freezeAmount);
        user.dynamicLevel = getLineLevel(user.freezeAmount.add(user.unlockAmount));

        Invest memory invest = Invest(msg.sender, investAmount, now, 0);
        user.invests.push(invest);
        user.votes -= (investAmount.div(ethWei));
    }

    function getCoefficient() public view returns (uint) {
        return getCoefficientInner();
    }

    function getCoefficientInner() internal view returns (uint) {
        if (userAssets == 0) {
            return 100;
        }
        uint thisBalance = address(this).balance;
        uint coefficient = thisBalance.mul(100).div(userAssets);
        if (coefficient >= 80) {
            return 100;
        }
        if (coefficient >= 60) {
            return 125;
        }
        if (coefficient >= 40) {
            return 167;
        }
        if (coefficient >= 20) {
            return 250;
        }
        if (coefficient > 0) {
            return 300;
        }
        return 100;
    }

    function endRound() private {
        rid++;
        gameStatus = 1;
        userAssets = 0;
        startTime = now.add(period).div(1 hours).mul(1 hours);
        voteStartSc = 80;
        voteResult = [0, 0];
        voteEndTime = 0;
    }

    function isUsed(string memory code) public view returns (bool) {
        address user = getUserAddressByCode(code);
        return uint(user) != 0;
    }

    function getUserAddressByCode(string memory code) public view returns (address) {
        return addressMapping[code];
    }

    function sendFeetoAdmin(uint amount) private {
        devAddr.transfer(amount.div(16));
    }

    function getGameInfo() public isHuman() view returns (uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        uint coeff = getCoefficientInner();
        uint balance = address(this).balance;
        return (
        rid,
        uid,
        startTime,
        balance,
        userAssets,
        investCount,
        investMoney,
        rInvestCount[rid],
        rInvestMoney[rid],
        coeff,
        gameStatus,
        voteStartSc
        );
    }

    function getSeizeInfo(uint r) public isHuman() view returns (address, uint, uint) {
        uint thisBalance = address(this).balance;
        uint coefficient = thisBalance.mul(100).div(userAssets);
        uint mult = 0;
        if (coefficient > 60) {
            mult = 3;
        } else if (coefficient > 40) {
            mult = 4;
        } else if (coefficient > 20) {
            mult = 6;
        } else if (coefficient > 0) {
            mult = 8;
        } else {
            mult = 10;
        }
        return (
        lastSeizeInvest[r].userAddress,
        lastSeizeInvest[r].seizeAmount,
        mult
        );
    }

    function getVoteResult() public isHuman view returns (uint, uint, uint, uint){
        return (
        seizeEndTime,
        voteEndTime,
        voteResult[0],
        voteResult[1]
        );
    }

    function getUserInfo(address user, uint roundId) public isHuman() view returns (uint[11] memory ct, uint inviteCount, string memory inviteCode, string memory referrer) {
        if (roundId == 0) {
            roundId = rid;
        }

        User memory userInfo = userRoundMapping[roundId][user];
        ct[0] = userInfo.id;
        ct[1] = userInfo.staticLevel;
        ct[2] = userInfo.dynamicLevel;
        ct[3] = userInfo.allInvest;
        ct[4] = userInfo.freezeAmount;
        ct[5] = userInfo.unlockAmount;
        ct[6] = userInfo.allStaticAmount;
        ct[7] = userInfo.allDynamicAmount;
        ct[8] = userInfo.hisStaticAmount;
        ct[9] = userInfo.hisDynamicAmount;
        ct[10] = userInfo.votes;
        UserGlobal storage userGlobal = userMapping[user];
        return (ct, userGlobal.id == 0 ? 0 : userGlobal.inviteCount, userGlobal.inviteCode, userGlobal.referrer);
    }

    function getLatestUnlockAmount(address userAddr) public view returns (uint)
    {
        User memory user = userRoundMapping[rid][userAddr];
        uint allUnlock = user.unlockAmount;
        for (uint i = user.staticFlag; i < user.invests.length; i++) {
            Invest memory invest = user.invests[i];
            uint unlockDay = now.sub(invest.investTime).div(1 days);

            if (unlockDay >= 5) {
                allUnlock = allUnlock.add(invest.investAmount);
            }
        }
        return allUnlock;
    }

    function registerUser(address user, string memory inviteCode, string memory referrer) private {
        UserGlobal storage userGlobal = userMapping[user];
        uid++;
        userGlobal.id = uid;
        userGlobal.userAddress = user;
        userGlobal.inviteCode = inviteCode;
        userGlobal.referrer = referrer;
        userGlobal.inviteCount = 0;

        addressMapping[inviteCode] = user;
        indexMapping[uid] = user;

        address parentAddr = getUserAddressByCode(referrer);
        UserGlobal storage parent = userMapping[parentAddr];
        parent.inviteCount += 1;
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