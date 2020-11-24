 

pragma solidity ^0.5.0;

interface tokenTransfer {
    function transfer(address receiver, uint amount) external;
    function transferFrom(address _from, address _to, uint256 _value) external;
    function balanceOf(address receiver) external returns(uint256);
}

contract UtilCMME {
    uint ethWei = 1 ether;

    function getLevel(uint value) internal view returns(uint) {
        if (value >= 1*ethWei && value <= 5*ethWei) {
            return 1;
        }
        if (value >= 6*ethWei && value <= 10*ethWei) {
            return 2;
        }
        if (value >= 11*ethWei && value <= 20*ethWei) {
            return 3;
        }
        return 0;
    }

    function getLineLevel(uint value) internal view returns(uint) {
        if (value >= 1*ethWei && value <= 5*ethWei) {
            return 1;
        }
        if (value >= 6*ethWei && value <= 10*ethWei) {
            return 2;
        }
        if (value >= 11*ethWei) {
            return 3;
        }
        return 0;
    }

    function getScByLevel(uint level) internal pure returns(uint) {
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

    function getFireScByLevel(uint level) internal pure returns(uint) {
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

    function getRecommendScaleByLevelAndTim(uint level,uint times) internal pure returns(uint){
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
            if(times == 1){
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

    function compareStr(string memory _str, string memory str) internal pure returns(bool) {
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
        mapping (address => bool) bearer;
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

contract CMME is UtilCMME, WhitelistAdminRole {

    using SafeMath for *;

    string constant private name = "eth magic foundation";

    uint ethWei = 1 ether;

    address tokencontract = address(0x244BD00B4B1623fC59ab542FF34F5b6fcbe7b128);

    struct User{
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
        uint inviteAmount;
        uint reInvestCount;
        uint lastReInvestTime;
        Invest[] invests;
        uint staticFlag;
    }

    struct GameInfo {
        uint luckPort;
        address[] specialUsers;
    }

    struct UserGlobal {
        uint id;
        address userAddress;
        string inviteCode;
        string referrer;
    }

    struct Invest{
        address userAddress;
        uint investAmount;
        uint investTime;
        uint times;
    }

    uint coefficient = 10;
    uint startTime;
    uint investCount = 0;
    mapping(uint => uint) rInvestCount;
    uint investMoney = 0;
    mapping(uint => uint) rInvestMoney;
    mapping(uint => GameInfo) rInfo;
    uint uid = 0;
    uint rid = 1;
    uint period = 3 hours;
    mapping (uint => mapping(address => User)) userRoundMapping;
    mapping(address => UserGlobal) userMapping;
    mapping (string => address) addressMapping;
    mapping (uint => address) public indexMapping;

     
    modifier isHuman() {
        address addr = msg.sender;
        uint codeLength;

        assembly {codeLength := extcodesize(addr)}
        require(codeLength == 0, "sorry humans only");
        require(tx.origin == msg.sender, "sorry, human only");
        _;
    }

    event LogInvestIn(address indexed who, uint indexed uid, uint amount, uint time, string inviteCode, string referrer, uint typeFlag);
    event LogWithdrawProfit(address indexed who, uint indexed uid, uint amount, uint time);
    event LogRedeem(address indexed who, uint indexed uid, uint amount, uint now);

     
     
     
    constructor () public {
    }

    function () external payable {
    }

    function activeGame(uint time) external onlyWhitelistAdmin
    {
        require(time > now, "invalid game start time");
        startTime = time;
    }

    function setCoefficient(uint coeff) external onlyWhitelistAdmin
    {
        require(coeff > 0, "invalid coeff");
        coefficient = coeff;
    }

    function gameStart() private view returns(bool) {
        return startTime != 0 && now > startTime;
    }

    function investIn(string memory inviteCode, string memory referrer,uint256 value)
        public
        isHuman()
    {
        value = value*ethWei;
        require(gameStart(), "game not start");
        require(value >= 1*ethWei && value <= 20*ethWei, "between 1 and 20");
        require(value == value.div(ethWei).mul(ethWei), "invalid msg value");

        tokenTransfer(tokencontract).transferFrom(msg.sender,address(address(this)),value.div(1e8));

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
            require(user.freezeAmount.add(value) <= 20*ethWei, "can not beyond 20 eth");
            user.allInvest = user.allInvest.add(value);
            user.freezeAmount = user.freezeAmount.add(value);
            user.staticLevel = getLevel(user.freezeAmount);
            user.dynamicLevel = getLineLevel(user.freezeAmount.add(user.unlockAmount));
        } else {
            user.id = userGlobal.id;
            user.userAddress = msg.sender;
            user.freezeAmount = value;
            user.staticLevel = getLevel(value);
            user.allInvest = value;
            user.dynamicLevel = getLineLevel(value);
            user.inviteCode = userGlobal.inviteCode;
            user.referrer = userGlobal.referrer;

            if (!compareStr(userGlobal.referrer, "")) {
                address referrerAddr = getUserAddressByCode(userGlobal.referrer);
                userRoundMapping[rid][referrerAddr].inviteAmount++;
            }
        }

        Invest memory invest = Invest(msg.sender, value, now, 0);
        user.invests.push(invest);

        if (rInvestMoney[rid] != 0 && (rInvestMoney[rid].div(10000).div(ethWei) != rInvestMoney[rid].add(value).div(10000).div(ethWei))) {
            bool isEnough;
            uint sendMoney;
            (isEnough, sendMoney) = isEnoughBalance(rInfo[rid].luckPort);
            if (sendMoney > 0) {
                sendMoneyToUser(msg.sender, sendMoney);
            }
            rInfo[rid].luckPort = 0;

        }

        investCount = investCount.add(1);
        investMoney = investMoney.add(value);
        rInvestCount[rid] = rInvestCount[rid].add(1);
        rInvestMoney[rid] = rInvestMoney[rid].add(value);
        rInfo[rid].luckPort = rInfo[rid].luckPort.add(value.mul(2).div(1000));

        emit LogInvestIn(msg.sender, userGlobal.id, value, now, userGlobal.inviteCode, userGlobal.referrer, 0);
    }
    
    function reInvestIn() public {
        
        User storage user = userRoundMapping[rid][msg.sender];
        
        calStaticProfitInner(msg.sender);

        uint reInvestAmount = user.unlockAmount;
        if (user.freezeAmount > 20*ethWei) {
            user.freezeAmount = 20*ethWei;
        }
        if (user.freezeAmount.add(reInvestAmount) > 20*ethWei) {
            reInvestAmount = (20*ethWei).sub(user.freezeAmount);
        }

        if (reInvestAmount == 0) {
            return;
        }

        uint leastAmount = reInvestAmount.mul(47).div(1000);
        bool isEnough;
        uint sendMoney;
        (isEnough, sendMoney) = isEnoughBalance(leastAmount);


        user.unlockAmount = user.unlockAmount.sub(reInvestAmount);
        user.allInvest = user.allInvest.add(reInvestAmount);
        user.freezeAmount = user.freezeAmount.add(reInvestAmount);
        user.staticLevel = getLevel(user.freezeAmount);
        user.dynamicLevel = getLineLevel(user.freezeAmount.add(user.unlockAmount));
        if ((now - user.lastReInvestTime) > 5 hours) {
            user.reInvestCount = user.reInvestCount.add(1);
            user.lastReInvestTime = now;
        }

        if (user.reInvestCount == 12) {
            rInfo[rid].specialUsers.push(msg.sender);
        }

        Invest memory invest = Invest(msg.sender, reInvestAmount, now, 0);
        user.invests.push(invest);

        if (rInvestMoney[rid] != 0 && (rInvestMoney[rid].div(10000).div(ethWei) != rInvestMoney[rid].add(reInvestAmount).div(10000).div(ethWei))) {
            (isEnough, sendMoney) = isEnoughBalance(rInfo[rid].luckPort);
            if (sendMoney > 0) {
                sendMoneyToUser(msg.sender, sendMoney);
            }
            rInfo[rid].luckPort = 0;

        }

        investCount = investCount.add(1);
        investMoney = investMoney.add(reInvestAmount);
        rInvestCount[rid] = rInvestCount[rid].add(1);
        rInvestMoney[rid] = rInvestMoney[rid].add(reInvestAmount);
        rInfo[rid].luckPort = rInfo[rid].luckPort.add(reInvestAmount.mul(2).div(1000));

        
        emit LogInvestIn(msg.sender, user.id, reInvestAmount, now, user.inviteCode, user.referrer, 1);
    }

    function withdrawProfit()
        public
        isHuman()
    {
        require(gameStart(), "game not start");
        User storage user = userRoundMapping[rid][msg.sender];
        uint sendMoney = user.allStaticAmount.add(user.allDynamicAmount);

        bool isEnough = false;
        uint resultMoney = 0;
        (isEnough, resultMoney) = isEnoughBalance(sendMoney);
        if (resultMoney > 0) {
            tokenTransfer(tokencontract).transfer(msg.sender,resultMoney.div(1e8));
            user.allStaticAmount = 0;
            user.allDynamicAmount = 0;
            emit LogWithdrawProfit(msg.sender, user.id, resultMoney, now);
        }


    }

    function isEnoughBalance(uint sendMoney) private view returns (bool, uint){
        if (sendMoney <= address(this).balance) {
            return (false, address(this).balance);
        } else {
            return (true, sendMoney);
        }
    }

    function sendMoneyToUser(address payable userAddress, uint money) private {
        userAddress.transfer(money);
    }

    function calStaticProfit(address userAddr) external onlyWhitelistAdmin returns(uint)
    {
        return calStaticProfitInner(userAddr);
    }

    function calStaticProfitInner(address userAddr) private returns(uint)
    {
        User storage user = userRoundMapping[rid][userAddr];
        if (user.id == 0) {
            return 0;
        }

        uint scale = getScByLevel(user.staticLevel);
        uint allStatic = 0;
        for (uint i = user.staticFlag; i < user.invests.length; i++) {
            Invest storage invest = user.invests[i];
            uint startDay = invest.investTime.sub(4 hours).div(1 hours).mul(1 hours);
            uint staticGaps = now.sub(4 hours).sub(startDay).div(1 hours);

            uint unlockDay = now.sub(invest.investTime).div(1 hours);

            if(staticGaps > 10){
                staticGaps = 10;
            }
            if (staticGaps > invest.times) {
                allStatic += staticGaps.sub(invest.times).mul(scale).mul(invest.investAmount).div(1000);
                invest.times = staticGaps;
            }

            if (unlockDay >= 10) {
                user.staticFlag = user.staticFlag.add(1);
                user.freezeAmount = user.freezeAmount.sub(invest.investAmount);
                user.unlockAmount = user.unlockAmount.add(invest.investAmount);
                user.staticLevel = getLevel(user.freezeAmount);
            }

        }
        allStatic = allStatic.mul(coefficient).div(10);
        user.allStaticAmount = user.allStaticAmount.add(allStatic);
        user.hisStaticAmount = user.hisStaticAmount.add(allStatic);
        return user.allStaticAmount;
    }

    function calDynamicProfit(uint start, uint end) external onlyWhitelistAdmin {
        for (uint i = start; i <= end; i++) {
            address userAddr = indexMapping[i];
            User memory user = userRoundMapping[rid][userAddr];
            if (user.freezeAmount >= 1*ethWei) {
                uint scale = getScByLevel(user.staticLevel);
                calUserDynamicProfit(user.referrer, user.freezeAmount, scale);
            }
            calStaticProfitInner(userAddr);
        }
    }

    function registerUserInfo(address user, string calldata inviteCode, string calldata referrer) external onlyOwner {
        registerUser(user, inviteCode, referrer);
    }

    function calUserDynamicProfit(string memory referrer, uint money, uint shareSc) private {
        string memory tmpReferrer = referrer;
        
        for (uint i = 1; i <= 30; i++) {
            if (compareStr(tmpReferrer, "")) {
                break;
            }
            address tmpUserAddr = addressMapping[tmpReferrer];
            User storage calUser = userRoundMapping[rid][tmpUserAddr];
            
            uint fireSc = getFireScByLevel(calUser.dynamicLevel);
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

                tmpDynamicAmount = tmpDynamicAmount.mul(coefficient).div(10);
                calUser.allDynamicAmount = calUser.allDynamicAmount.add(tmpDynamicAmount);
                calUser.hisDynamicAmount = calUser.hisDynamicAmount.add(tmpDynamicAmount);
            }

            tmpReferrer = calUser.referrer;
        }
    }

    function redeem()
        public
        isHuman()
    {
        require(gameStart(), "game not start");
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id > 0, "user not exist");

        calStaticProfitInner(msg.sender);

        uint sendMoney = user.unlockAmount;

        bool isEnough = false;
        uint resultMoney = 0;

        (isEnough, resultMoney) = isEnoughBalance(sendMoney);
        if (resultMoney > 0) {
            tokenTransfer(tokencontract).transfer(msg.sender,resultMoney.div(1e8));
            user.unlockAmount = 0;
            user.staticLevel = getLevel(user.freezeAmount);
            user.dynamicLevel = getLineLevel(user.freezeAmount);

            emit LogRedeem(msg.sender, user.id, resultMoney, now);
        }

        if (user.reInvestCount < 12) {
            user.reInvestCount = 0;
        }


    }

    function endRound() public onlyOwner {
        rid++;
        startTime = now.add(period).div(1 hours).mul(1 hours);
        coefficient = 10;
    }

    function isUsed(string memory code) public view returns(bool) {
        address user = getUserAddressByCode(code);
        return uint(user) != 0;
    }

    function getUserAddressByCode(string memory code) public view returns(address) {
        return addressMapping[code];
    }


    function getGameInfo() public isHuman() view returns(uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        return (
            rid,
            uid,
            startTime,
            investCount,
            investMoney,
            rInvestCount[rid],
            rInvestMoney[rid],
            coefficient,
            rInfo[rid].luckPort,
            rInfo[rid].specialUsers.length
        );
    }

    function getUserInfo(address user, uint roundId, uint i) public isHuman() view returns(
        uint[17] memory ct, string memory inviteCode, string memory referrer
    ) {

        if(roundId == 0){
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
        ct[10] = userInfo.inviteAmount;
        ct[11] = userInfo.reInvestCount;
        ct[12] = userInfo.staticFlag;
        ct[13] = userInfo.invests.length;
        if (ct[13] != 0) {
            ct[14] = userInfo.invests[i].investAmount;
            ct[15] = userInfo.invests[i].investTime;
            ct[16] = userInfo.invests[i].times;
        } else {
            ct[14] = 0;
            ct[15] = 0;
            ct[16] = 0;
        }
        

        inviteCode = userMapping[user].inviteCode;
        referrer = userMapping[user].referrer;

        return (
            ct,
            inviteCode,
            referrer
        );
    }

    function getSpecialUser(uint _rid, uint i) public view returns(address) {
        return rInfo[_rid].specialUsers[i];
    }

    function getLatestUnlockAmount(address userAddr) public view returns(uint)
    {
        User memory user = userRoundMapping[rid][userAddr];
        uint allUnlock = user.unlockAmount;
        for (uint i = user.staticFlag; i < user.invests.length; i++) {
            Invest memory invest = user.invests[i];
            uint unlockDay = now.sub(invest.investTime).div(1 hours);

            if (unlockDay >= 10) {
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

        addressMapping[inviteCode] = user;
        indexMapping[uid] = user;
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