 
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

contract SuperFair is UtilFairWin, WhitelistAdminRole {

    using SafeMath for *;

    string constant private name = "SuperFair Official";

    uint ethWei = 1 ether;

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
        uint day;
    }

    struct Order {
        address user;
        uint256 amount;
        string inviteCode;
        string referrer;
        bool execute;
    }

    struct WaitInfo {
        uint256 totalAmount;
        bool isWait;
        uint256 time;
        uint256[] seq;
    }

    string constant systemCode = "99999999";
    uint coefficient = 10;
    uint profit = 100;
    uint startTime;
    uint investCount = 0;
    mapping(uint => uint) rInvestCount;
    uint investMoney = 0;
    mapping(uint => uint) rInvestMoney;
    uint uid = 0;
    uint rid = 1;
    uint period = 3 days;

    uint256 public timeInterval = 1440;

    mapping (uint => mapping(address => User)) userRoundMapping;
    mapping(address => UserGlobal) userMapping;
    mapping (string => address) addressMapping;
    mapping (string => address) codeRegister;
    mapping (uint => address) public indexMapping;
    mapping (uint => mapping(uint256 => Order)) public waitOrder;
    mapping (uint => mapping(address => WaitInfo)) public waitInfo;
    uint32  public ratio = 1000;      
    mapping (uint => mapping(address => uint256[2])) public extraInfo;

    address payable public eggAddress = 0x9ddc752e3D59Cd16e4360743C6eB9608d39e6119;  
    address payable public fivePercentWallet = 0x76594F0FA263Ac33aa28E3AdbFebBcBaf7Db76A9;  
    address payable public twoPercentWallet =  0x4200DBbda245be2b04a0a82eB1e08C6580D81C9b;  
    address payable public threePercentWallet = 0x07BeEec61D7B28177521bFDd0fdA5A07d992e51F;  

    SFtoken internal SFInstance;

    bool public waitLine = true;
    uint256 public numOrder = 1;
    uint256 public startNum = 1;

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

    constructor (address _erc20Address) public {
        SFInstance = SFtoken(_erc20Address);
    }

    function () external payable {
    }

    function calculateToken(address user, uint256 ethAmount)
    internal
    {
        SFInstance.transfer(user, ethAmount.mul(ratio));
    }


    function activeGame(uint time) external onlyWhitelistAdmin
    {
        require(time > now, "invalid game start time");
        startTime = time;
    }

    function modifyProfit(uint p) external onlyWhitelistAdmin
    {
        profit = p;
    }


    function setCoefficient(uint coeff) external onlyWhitelistAdmin
    {
        require(coeff > 0, "invalid coeff");
        coefficient = coeff;
    }

    function setRatio(uint32 r) external onlyWhitelistAdmin
    {
        ratio = r;
    }

    function setWaitLine (bool wait) external onlyWhitelistAdmin
    {
        waitLine = wait;
    }

    function modifyStartNum(uint256 number) external onlyWhitelistAdmin
    {
        startNum = number;
    }

    function executeLine(uint256 end) external onlyWhitelistAdmin
    {
        require(waitLine, "need wait line");
        for(uint256 i = startNum; i < startNum + end; i++) {
            require(waitOrder[rid][i].user != address(0), "user address can not be 0X");
            investIn(waitOrder[rid][i].user, waitOrder[rid][i].amount, waitOrder[rid][i].inviteCode, waitOrder[rid][i].referrer);
            waitOrder[rid][i].execute = true;
            waitInfo[rid][waitOrder[rid][i].user].isWait = false;
        }
        startNum += end;
    }

    function gameStart() public view returns(bool) {
        return startTime != 0 && now > startTime;
    }

    function waitInvest(string memory inviteCode, string memory referrer)
    public
    isHuman()
    payable
    {
        require(gameStart(), "game not start");
        require(msg.value >= 1*ethWei && msg.value <= 15*ethWei, "between 1 and 15");
        require(msg.value == msg.value.div(ethWei).mul(ethWei), "invalid msg value");
        require(codeRegister[inviteCode] == address(0) || codeRegister[inviteCode] == msg.sender, "can not repeat invite");

        UserGlobal storage userGlobal = userMapping[msg.sender];
        if (userGlobal.id == 0) {
            require(!compareStr(inviteCode, ""), "empty invite code");
            address referrerAddr = getUserAddressByCode(referrer);
            require(uint(referrerAddr) != 0, "referer not exist");
            require(referrerAddr != msg.sender, "referrer can't be self");
            require(!isUsed(inviteCode), "invite code is used");
        }

        Order storage order = waitOrder[rid][numOrder];
        order.user = msg.sender;
        order.amount = msg.value;
        order.inviteCode = inviteCode;
        order.referrer = referrer;

        WaitInfo storage info = waitInfo[rid][msg.sender];
        info.totalAmount += msg.value;
        require(info.totalAmount <= 15 ether, "eth amount between 1 and 15");
        info.isWait = true;
        info.seq.push(numOrder);
        info.time = now;

        codeRegister[inviteCode] = msg.sender;

        if(!waitLine){
            if(numOrder!=1){
                require(waitOrder[rid][numOrder - 1].execute, "last order not execute");
            }
            investIn(order.user, order.amount, order.inviteCode, order.referrer);
            order.execute = true;
            info.isWait = false;
            startNum += 1;
        }

        numOrder += 1;
    }

    function investIn(address usera, uint256 amount, string memory inviteCode, string memory referrer)
    private
    {
        UserGlobal storage userGlobal = userMapping[usera];
        if (userGlobal.id == 0) {
            require(!compareStr(inviteCode, ""), "empty invite code");
            address referrerAddr = getUserAddressByCode(referrer);
            extraInfo[rid][referrerAddr][1] += 1;
            require(uint(referrerAddr) != 0, "referer not exist");
            require(referrerAddr != usera, "referrer can't be self");

            require(!isUsed(inviteCode), "invite code is used");

            registerUser(usera, inviteCode, referrer);
        }

        User storage user = userRoundMapping[rid][usera];
        if (uint(user.userAddress) != 0) {
            require(user.freezeAmount.add(amount) <= 15*ethWei, "can not beyond 15 eth");
            user.allInvest = user.allInvest.add(amount);
            user.freezeAmount = user.freezeAmount.add(amount);
            user.staticLevel = getLevel(user.freezeAmount);
            user.dynamicLevel = getLineLevel(user.freezeAmount.add(user.unlockAmount));
        } else {
            user.id = userGlobal.id;
            user.userAddress = usera;
            user.freezeAmount = amount;
            user.staticLevel = getLevel(amount);
            user.allInvest = amount;
            user.dynamicLevel = getLineLevel(amount);
            user.inviteCode = userGlobal.inviteCode;
            user.referrer = userGlobal.referrer;
        }

        Invest memory invest = Invest(usera, amount, now, 0, 0);
        user.invests.push(invest);

        investCount = investCount.add(1);
        investMoney = investMoney.add(amount);
        rInvestCount[rid] = rInvestCount[rid].add(1);
        rInvestMoney[rid] = rInvestMoney[rid].add(amount);

        calculateToken(usera, amount);

        sendMoneyToUser(fivePercentWallet, amount.mul(5).div(100));   
        sendMoneyToUser(twoPercentWallet, amount.mul(2).div(100));    
        sendMoneyToUser(threePercentWallet, amount.mul(3).div(100));  

    emit LogInvestIn(usera, userGlobal.id, amount, now, userGlobal.inviteCode, userGlobal.referrer);
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
        if (!isEnough) {
            endRound();
        }

        uint256[2] storage extra = extraInfo[rid][msg.sender];
        extra[0] += resultMoney;
        if(extra[0] >= user.allInvest) {
            if(user.allInvest > (extra[0] - resultMoney)){
                resultMoney = user.allInvest - (extra[0] - resultMoney);
            } else {
                resultMoney = 0;
            }
        }

        if (resultMoney > 0) {
            sendMoneyToUser(eggAddress, resultMoney.mul(10).div(100));
            sendMoneyToUser(msg.sender, resultMoney.mul(90).div(100));
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

        if(user.hisStaticAmount.add(user.hisDynamicAmount) >=  user.allInvest){
            user.freezeAmount = 0;
            user.unlockAmount = user.allInvest;
            user.staticLevel = getLevel(user.freezeAmount);
            user.staticFlag = user.invests.length;
        } else {
            for (uint i = user.staticFlag; i < user.invests.length; i++) {
                Invest storage invest = user.invests[i];
                if(invest.day < 100) {
                    uint staticGaps = now.sub(invest.investTime).div(timeInterval.mul(1 minutes));  
                    uint unlockDay = now.sub(invest.investTime).div(timeInterval.mul(1 minutes));  
                    if (unlockDay>100) {
                        unlockDay = 100;
                        user.staticFlag++;
                    }

                    if(staticGaps > 100){
                        staticGaps = 100;
                    }
                    if (staticGaps > invest.times) {
                        allStatic += staticGaps.sub(invest.times).mul(scale).mul(invest.investAmount).div(1000);
                        invest.times = staticGaps;
                    }

                    user.freezeAmount = user.freezeAmount.sub(invest.investAmount.div(100).mul(unlockDay - invest.day).mul(profit).div(100));
                    user.unlockAmount = user.unlockAmount.add(invest.investAmount.div(100).mul(unlockDay - invest.day).mul(profit).div(100));
                    invest.day = unlockDay;
                }
            }
        }

        allStatic = allStatic.mul(coefficient).div(10);
        user.allStaticAmount = user.allStaticAmount.add(allStatic);
        user.hisStaticAmount = user.hisStaticAmount.add(allStatic);
        userRoundMapping[rid][userAddr] = user;
        return user.allStaticAmount;
    }

    function calDynamicProfit(uint start, uint end) external onlyWhitelistAdmin {
        for (uint i = start; i <= end; i++) {
            address userAddr = indexMapping[i];
            User memory user = userRoundMapping[rid][userAddr];

            if(user.allInvest > 0) {
                calStaticProfitInner(userAddr);
            }

            if (user.freezeAmount > 0) {
                uint scale = getScByLevel(user.staticLevel);
 
 
 
                    calUserDynamicProfit(user.referrer, user.allInvest, scale);
 
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

            if (calUser.freezeAmount <= 0){
                tmpReferrer = calUser.referrer;
                continue;
            }

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
        withdrawProfit();
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
            require(resultMoney <= user.allInvest,"redeem money can not be 0");
            sendMoneyToUser(msg.sender, resultMoney);  
            delete waitInfo[rid][msg.sender];

            user.staticLevel = 0;
            user.dynamicLevel = 0;
            user.allInvest = 0;
            user.freezeAmount = 0;
            user.unlockAmount = 0;
            user.allStaticAmount = 0;
            user.allDynamicAmount = 0;
            user.hisStaticAmount = 0;
            user.hisDynamicAmount = 0;
            user.staticFlag = 0;
            user.invests.length = 0;

            extraInfo[rid][msg.sender][0] = 0;

            emit LogRedeem(msg.sender, user.id, resultMoney, now);
        }
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
        ct[10] = extraInfo[rid][user][1];

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

    function getWaitInfo(address user) public view returns (uint256 totalAmount, bool isWait, uint256 time, uint256[]  memory seq, bool wait) {
        totalAmount = waitInfo[rid][user].totalAmount;
        isWait = waitInfo[rid][user].isWait;
        time = waitInfo[rid][user].time;
        seq = waitInfo[rid][user].seq;
        wait = waitLine;
    }

    function getWaitOrder(uint256 num) public view returns (address user, uint256 amount, string memory inviteCode, string  memory referrer, bool execute) {
        user = waitOrder[rid][num].user;
        amount = waitOrder[rid][num].amount;
        inviteCode = waitOrder[rid][num].inviteCode;
        referrer = waitOrder[rid][num].referrer;
        execute = waitOrder[rid][num].execute;
    }

    function getInviteNum() public view returns(uint256 num){
        num = extraInfo[rid][msg.sender][1];
    }

    function getLatestUnlockAmount(address userAddr) public view returns(uint)
    {
        User memory user = userRoundMapping[rid][userAddr];
        uint allUnlock = user.unlockAmount;
        for (uint i = user.staticFlag; i < user.invests.length; i++) {
            Invest memory invest = user.invests[i];

            uint unlockDay = now.sub(invest.investTime).div(1 days);
            allUnlock = allUnlock.add(invest.investAmount.div(100).mul(unlockDay).mul(profit).div(100));
        }
        allUnlock = allUnlock <= user.allInvest ? allUnlock : user.allInvest;
        return allUnlock;
    }

    function registerUser(address user, string memory inviteCode, string memory referrer) private {

        uid++;
        userMapping[user].id = uid;
        userMapping[user].userAddress = user;
        userMapping[user].inviteCode = inviteCode;
        userMapping[user].referrer = referrer;

        addressMapping[inviteCode] = user;
        indexMapping[uid] = user;
    }

    function isCode(string memory invite) public view returns (bool){
        return codeRegister[invite] == address(0);
    }

    function getUid() public view returns(uint){
        return uid;
    }

    function withdrawEgg(uint256 money) external
    onlyWhitelistAdmin
    {
        if (money > address(this).balance){
            sendMoneyToUser(eggAddress, address(this).balance);
        } else {
            sendMoneyToUser(eggAddress, money);
        }
    }

    function setTimeInterval(uint256 targetTimeInterval) external onlyWhitelistAdmin{
        timeInterval = targetTimeInterval;
    }
}