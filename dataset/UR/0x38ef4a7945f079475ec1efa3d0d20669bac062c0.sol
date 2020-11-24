 

 

pragma solidity ^0.5.11;

contract UtilWin {
    uint ethWei = 1 ether;

	 
    function getLevel(uint value) public view returns(uint) {
        if (value >= 1*ethWei && value <= 5*ethWei) {
            return 1;
        }
        if (value >= 6*ethWei && value <= 10*ethWei) {
            return 2;
        }
        if (value >= 11*ethWei && value <= 15*ethWei) {
            return 3;
        }
        return 0;
    }


	 
    function getScByLevel(uint level) public pure returns(uint) {
        if (level == 1) {
            return 10;
        }
        if (level == 2) {
            return 12;
        }
        if (level == 3) {
            return 15;
        }
        return 0;
    }
	
	 
	function getFireScByLevel(uint level) public pure returns(uint) {
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

	 
    function getNodeScaleByLevel(uint level,uint times) public pure returns(uint){
        if (level == 1 && times == 1) {
            return 50;
        }
        if (level == 2 && times == 1) {
            return 50;
        }
        if (level == 2 && times == 2) {
            return 30;
        }
        if (level == 3) {
            if(times == 1){
                return 50;
            }
            if (times == 2) {
                return 30;
            }
            if (times == 3) {
                return 20;
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

    function compareStr(string memory _str, string memory str) public pure returns(bool) {
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

 
contract AdminRole is Context, Ownable {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()) || isOwner(), "AdminRole: caller does not have the WhitelistAdmin role");
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

 

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

contract LifeWinner is UtilWin, AdminRole {

    using SafeMath for *;

    string constant private name = "LifeWinner";

    uint ethWei = 1 ether;

    address payable private devAddr = address(0x00Cc7Cde28335Fe2Ef8d73651eB9D22e6e385fDA);
	
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
        uint todayStaticAmount;
        uint inviteCount;
        Invest[] invests;
        uint staticFlag;
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
	uint rday = 5;
    uint startTime;
    uint investCount = 0;
    mapping(uint => uint) rLastUid;
    mapping(uint => uint) rInvestCount;
    uint investMoney = 0;
    mapping(uint => uint) rInvestMoney;
    uint uid = 0;
    uint rid = 1;
    uint period = 2 days;
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

    event LogInvestIn(address indexed who, uint indexed uid, uint amount, uint time, string inviteCode, string referrer);
    event LogWithdrawProfit(address indexed who, uint indexed uid, uint amount, uint time);
    event LogRedeem(address indexed who, uint indexed uid, uint amount, uint now);
	event LogDuplicateInvestIn(address indexed who, uint indexed uid, uint amount, uint time, string inviteCode, string referrer);
    
    constructor () public {
    }

    function () external payable {
    }

	
    function activeGame(uint time) external onlyWhitelistAdmin
    {
        require(time > now, "invalid game start time");
        startTime = time;
    }

    

    function gameStart() public view returns(bool) {
        return startTime != 0 && now > startTime;
    }

    function investIn(string memory inviteCode, string memory referrer)
        public
        isHuman()
        payable
    {
        require(gameStart(), "game not start");
        require(msg.value >= 1*ethWei && msg.value <= 15*ethWei, "between 1 and 15");
        require(msg.value == msg.value.div(ethWei).mul(ethWei), "invalid msg value");


        UserGlobal storage userGlobal = userMapping[msg.sender];
        if (userGlobal.id == 0) {
            
            address referrerAddr = getUserAddressByCode(referrer);
            require(!compareStr(inviteCode, ""), "empty invite code");
            require(uint(referrerAddr) != 0, "referer not exist");
            require(referrerAddr != msg.sender, "referrer can't be self");
            
            require(!isUsed(inviteCode), "invite code is used");

            registerUser(msg.sender, inviteCode, referrer);
            
             User storage puser = userRoundMapping[rid][referrerAddr];
             puser.inviteCount=puser.inviteCount.add(1);
        }

       
        User storage user = userRoundMapping[rid][msg.sender];
        if (uint(user.userAddress) != 0) {
            require(user.freezeAmount.add(msg.value) <= 15*ethWei, "can not beyond 15 eth");
            user.allInvest = user.allInvest.add(msg.value);
            user.freezeAmount = user.freezeAmount.add(msg.value);
            user.staticLevel = getLevel(user.freezeAmount);
            user.dynamicLevel = getLevel(user.freezeAmount.add(user.unlockAmount));
        } else {
            user.id = userGlobal.id;
            user.userAddress = msg.sender;
            user.freezeAmount = msg.value;
            user.staticLevel = getLevel(msg.value);
            user.allInvest = msg.value;
            user.dynamicLevel = getLevel(msg.value);
            user.inviteCode = userGlobal.inviteCode;
            user.referrer = userGlobal.referrer;
        }

        Invest memory invest = Invest(msg.sender, msg.value, now, 0);
        user.invests.push(invest);

        investCount = investCount.add(1);
        investMoney = investMoney.add(msg.value);
        rInvestCount[rid] = rInvestCount[rid].add(1);
        rInvestMoney[rid] = rInvestMoney[rid].add(msg.value);
        rLastUid[rid]=userGlobal.id;
        sendFeetoAdmin(msg.value);
        emit LogInvestIn(msg.sender, userGlobal.id, msg.value, now, userGlobal.inviteCode, userGlobal.referrer);
    }

    function withdrawProfit()
        external
        isHuman()
    {
        require(gameStart(), "game not start");
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
            emit LogWithdrawProfit(msg.sender, user.id, resultMoney, now);
        }
    }

    function isEnoughBalance(uint sendMoney) private view returns (bool, uint){
        if (sendMoney >= address(this).balance) {
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
            uint startDay = invest.investTime.sub(8 hours).div(1 days).mul(1 days);
            uint staticGaps = now.sub(8 hours).sub(startDay).div(1 days);

            uint unlockDay = now.sub(invest.investTime).div(1 days);

            if(staticGaps > rday){
                staticGaps = rday;
            }
            if (staticGaps > invest.times) {
                allStatic += staticGaps.sub(invest.times).mul(scale).mul(invest.investAmount).div(1000);
                invest.times = staticGaps;
            }

            if (unlockDay >= rday) {
                user.staticFlag++;
                user.freezeAmount = user.freezeAmount.sub(invest.investAmount);
                user.unlockAmount = user.unlockAmount.add(invest.investAmount);
                user.staticLevel = getLevel(user.freezeAmount);
            }

        }
        allStatic = allStatic.mul(coefficient).div(10);
        user.todayStaticAmount=allStatic;
        user.allStaticAmount = user.allStaticAmount.add(user.todayStaticAmount);
        user.hisStaticAmount = user.hisStaticAmount.add(user.todayStaticAmount);
        userRoundMapping[rid][userAddr] = user;
        return user.todayStaticAmount;
    }

    function calDynamicProfit(uint start, uint end) external onlyWhitelistAdmin {
        		
        for (uint i = start; i <= end; i++) {
            address userAddr = indexMapping[i];
            User memory user = userRoundMapping[rid][userAddr];
			uint freezeAmount = user.freezeAmount;
			uint staticAmount= calStaticProfitInner(userAddr);
            if (staticAmount>0 && user.freezeAmount >= 1*ethWei) {
                uint scale = getScByLevel(user.staticLevel);
                calUserDynamicProfit(user.referrer, freezeAmount, scale);
            }
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
			if(calUser.id==0){
				break;
			}
            
            uint fireSc = getFireScByLevel(calUser.staticLevel);
            uint recommendSc = getNodeScaleByLevel(calUser.dynamicLevel, i);
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
        external
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

        if (!isEnough) {
            endRound();
        }

        if (resultMoney > 0) {
            sendMoneyToUser(msg.sender, resultMoney);
            user.unlockAmount = 0;
            user.staticLevel = getLevel(user.freezeAmount);
            user.dynamicLevel = getLevel(user.freezeAmount);

            emit LogRedeem(msg.sender, user.id, resultMoney, now);
        }
    }
	
	function duplicateInvestIn()
        external
        isHuman()
    {
        require(gameStart(), "game not start");
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id > 0, "user not exist");

        uint sendMoney = user.unlockAmount;
		
		require(sendMoney>0, "No principal available");
		require(user.freezeAmount.add(sendMoney) >= 1*ethWei && user.freezeAmount.add(sendMoney) <= 15*ethWei, "between 1 and 15");
      
		bool isEnough = false;
        uint resultMoney = 0;
        uint devMoney = sendMoney.div(25);

        (isEnough, resultMoney) = isEnoughBalance(devMoney);

        require(isEnough, "Pool Balance not Enough");

        sendFeetoAdmin(sendMoney);
		
		user.unlockAmount = 0;
		user.allInvest = user.allInvest.add(sendMoney);
		user.freezeAmount=user.freezeAmount.add(sendMoney);
		user.staticLevel = getLevel(user.freezeAmount);
		user.dynamicLevel = getLevel(user.freezeAmount);
		
		
		Invest memory invest = Invest(msg.sender, sendMoney, now,0);
        user.invests.push(invest);

        investCount = investCount.add(1);
        investMoney = investMoney.add(sendMoney);
        rInvestCount[rid] = rInvestCount[rid].add(1);
        rInvestMoney[rid] = rInvestMoney[rid].add(sendMoney);
        rLastUid[rid]=user.id;
        
		emit LogDuplicateInvestIn(msg.sender, user.id, sendMoney, now, user.inviteCode, user.referrer);

        
    }

    function endRound() private {
        rid++;
        startTime = now.add(period).div(1 days).mul(1 days);
        coefficient = 10;
    }

    function isUsed(string memory code) public view returns(bool) {
        address user = getUserAddressByCode(code);
        return uint(user) != 0;
    }

    function getUserAddressByCode(string memory code) public view returns(address) {
        return addressMapping[code];
    }

    function sendFeetoAdmin(uint amount) private {
        devAddr.transfer(amount.div(25));
    }

    function getGameInfo() public isHuman() view returns(uint, uint, uint, uint, uint, uint, uint, uint) {
        return (
            rid,
            uid,
            startTime,
            investCount,
            investMoney,
            rInvestCount[rid],
            rInvestMoney[rid],
            coefficient
        );
    }

    function getUserInfo(address user, uint roundId) public isHuman() view returns(
        uint[11] memory ct, string memory inviteCode, string memory referrer
    ) {

        if(roundId == 0){
            roundId = rid;
        }
        
         UserGlobal storage userGlobal = userMapping[user];

        User memory userInfo = userRoundMapping[roundId][user];
        userInfo.id=userGlobal.id;
        userInfo.inviteCode=userGlobal.inviteCode;
        userInfo.referrer=userGlobal.referrer;

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
        ct[10] = userInfo.inviteCount;


        inviteCode = userInfo.inviteCode;
        referrer = userInfo.referrer;

        return (
            ct,
            inviteCode,
            referrer
        );
    	
    }

    function getUserById(uint id) public view returns(address){
        return indexMapping[id];
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
    
     function getLastInviteUser(uint roundId) public view returns(address){
        uint id = rLastUid[roundId];
        return indexMapping[id];
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