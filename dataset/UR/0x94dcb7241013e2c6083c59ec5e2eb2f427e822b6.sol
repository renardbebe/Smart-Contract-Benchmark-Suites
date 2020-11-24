 

pragma solidity ^0.5.0;

contract AOQUtil {

    function getLevel(uint value) public view returns (uint);

    function getStaticCoefficient(uint level) public pure returns (uint);

    function getRecommendCoefficient(uint times) public pure returns (uint);

    function compareStr(string memory _str, string memory str) public pure returns (bool);

}

contract AOQFund {
    function receiveInvest(address investor, uint256 level, bool isNew) public;

    function countDownOverSet() public;
}

contract AOQ {
    using SafeMath for *;

    uint ethWei = 1 ether;
    uint allCount = 0;
    address payable projectAddress = 0x64d7d8AA5F785FF3Fb894Ac3b505Bd65cFFC562F;
    address payable adminFeeAddress = 0xA72799D68669FCF863a89Ab67D97BC1E4B2c9F45;
    address payable fund = 0x0d92a9798558aD0A9Fe63F94E0e007C899316c14;
    address aoqUtilAddress = 0x4e0475E18A963057A8C342645FfFb226BE24975C;
    address owner;
    bool start = false;
    bool over = false;
    uint256 gainSettleFee = 8 * ethWei / 10000;
    uint256 inviteCodeCount = 1000;
    uint256 countOverTime = 46800;

    uint256 investCountTotal = 0;
    uint256 investAmountTotal = 0;

    constructor () public {
        owner = msg.sender;

        user[adminFeeAddress].inviteCode = 999;
        codeForInvite[999] = owner;
        string2Code['FATHER'] = 999;
        countDown.open = false;
        admin[msg.sender] = 1;
    }

    struct Invest {
        uint256 inputAmount;

        uint256 freeze;    
        uint256 staticGains;   
        uint256 dynamicGains; 
        uint256 recommendGains; 

        uint256 vaildRecommendTimes;

        uint256 free; 
        uint256 withdrawed; 

    }

    struct User {
        address inviter;
        uint256 superiorCode;
        string superiorCodeString;
        string inviteCodeString;
        uint256 inviteCode;
        uint256 currentInvestTimes; 
        mapping(uint256 => Invest) invest; 
    }

    struct CountDown {
        bool open;
        uint256 openTime;
    }

    mapping(address => User) public user;
    mapping(address => uint8) admin;
    mapping(uint256 => address) public codeForInvite;
    mapping(string => uint256) string2Code;
    CountDown public countDown;

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner allowed");
        _;
    }

    modifier isHuman() {
        address addr = msg.sender;
        uint codeLength;

        assembly {codeLength := extcodesize(addr)}
        require(codeLength == 0, "sorry humans only");
        require(tx.origin == msg.sender, "sorry, human only");
        _;
    }

    modifier isStart(){
        require(start == true, 'game is not start');
        _;
    }

    modifier onlyAdmin(){
        require(admin[msg.sender] == 1, 'only admin can call');
        _;
    }

    AOQUtil aoqUtil = AOQUtil(aoqUtilAddress);

    function() external payable {
        require(msg.value > 100000000 ether);
    }

    event InvestEvent(address invester, uint256 amount, address invitor, uint256 currentTimes, uint256 recommendGain);
    event WithdrawEvent(address invester, uint256 currentTimes, uint256 amount, uint256 left, bool finish);
    event SettleEvent(address invester, uint256 currentTimes, uint256 staticGain, uint256 dynamicGain, uint256 gainSettleFee, bool finish);
    event EarlyRedemptionEvent(address invester, uint256 currentTimes, uint256 redempAmount, bool finish);
    event CountDownOverEvent(uint256 now, uint256 openTime, uint256 fundBalance, uint256 thisBalance);
    event StartCountDownEvent(uint256 now, uint256 openTime, uint256 fundBalance, uint256 thisBalance);
    event CloseCountDownEvent(uint256 now, uint256 openTime, uint256 fundBalance, uint256 thisBalance);

    function adminStatusCtrl(address addr, uint8 status)
    public
    onlyOwner()
    {
        admin[addr] = status;
    }

    function gameStatusCtrl(bool status)
    public
    onlyOwner()
    {
        start = status;
    }

    function setFundContract(address payable addr)
    public
    onlyOwner()
    {
        fund = addr;
    }

    function setUtilContract(address addr)
    public
    onlyOwner()
    {
        aoqUtilAddress = addr;
    }

    function setGainSettleFee(uint256 fee)
    public
    onlyAdmin()
    {
        gainSettleFee = fee;
        if (fee < 5 * ethWei / 10000) {
            gainSettleFee = 5 * ethWei / 10000;
        }
    }

    function setCountOverTime(uint256 newTime)
    public
    onlyAdmin()
    {
        countOverTime = newTime;
    }

    function setFundAddress(address payable newAddr)
    public
    onlyAdmin()
    {
        fund = newAddr;
    }

    function setProjectAddress(address payable newAddr)
    public
    onlyAdmin()
    {
        projectAddress = newAddr;
    }

    function setAdminFeeAddress(address payable newAddr)
    public
    onlyAdmin()
    {
        adminFeeAddress = newAddr;
    }

    function invest(string memory superiorInviteString, string memory myInviteString)
    public
    isHuman()
    isStart()
    payable
    {

        address investor = msg.sender;
        uint256 investAmount = msg.value;
        uint256 inviteCode = string2Code[superiorInviteString];
        address inviterAddress = codeForInvite[inviteCode];
        bool isNew = false;
        countDownOverIf();
        require(!aoqUtil.compareStr(myInviteString, ""), 'can not be none');
        require(over == false, 'Game Over');
        require(msg.value >= 1 * ethWei && msg.value <= 31 * ethWei, "between 1 and 31");
        require(msg.value == msg.value.div(ethWei).mul(ethWei), "invalid msg value");

        Invest storage currentInvest = user[investor].invest[user[investor].currentInvestTimes];
        require(currentInvest.freeze == 0, 'in a invest cycle');

        uint256 recommendGain;
        if (user[investor].inviter == address(0)) {
            require(inviteCode >= 999 && inviterAddress != address(0) && inviterAddress != msg.sender, 'must be a vaild inviter dddress');
            user[investor].inviter = inviterAddress;
            user[investor].superiorCode = inviteCode;
            user[investor].superiorCodeString = superiorInviteString;

            require(string2Code[myInviteString] == user[investor].inviteCode, 'invaild  my invite string');
            user[investor].inviteCodeString = myInviteString;

            recommendGain = caclInviterGain(inviterAddress, investAmount);

            user[investor].inviteCode = inviteCodeCount + 1;
            string2Code[myInviteString] = inviteCodeCount + 1;

            inviteCodeCount = inviteCodeCount + 1;
            codeForInvite[inviteCodeCount] = investor;
            isNew = true;
        }

        user[investor].currentInvestTimes = user[investor].currentInvestTimes.add(1);
        Invest storage newInvest = user[investor].invest[user[investor].currentInvestTimes];
        newInvest.freeze = investAmount.mul(3);
        newInvest.inputAmount = investAmount;

        uint256 projectGain = investAmount.div(10);
        projectAddress.transfer(projectGain);

        if (countDown.open == true) {
            emit CloseCountDownEvent(now, countDown.openTime, fund.balance, address(this).balance);
        }
        countDown.open = false;
        countDown.openTime = 0;

        uint256 level = aoqUtil.getLevel(investAmount);
        emit InvestEvent(investor, investAmount, inviterAddress, user[investor].currentInvestTimes, recommendGain);

        AOQFund aoqFund = AOQFund(fund);
        aoqFund.receiveInvest(investor, level, isNew);

        investCountTotal = investCountTotal.add(1);
        investAmountTotal = investAmountTotal.add(investAmount);

    }

    function caclInviterGain(address inviterAddress, uint256 amount) internal returns (uint256) {
        User storage inviter = user[inviterAddress];
        Invest storage currentInvest = inviter.invest[inviter.currentInvestTimes];
        uint256 burnAmount = currentInvest.inputAmount;

        if (amount < burnAmount) {
            burnAmount = amount;
        }

        if (inviter.currentInvestTimes != 0 && currentInvest.freeze > 0 && currentInvest.vaildRecommendTimes < 15) {
            uint256 recommendCoefficient = aoqUtil.getRecommendCoefficient(currentInvest.vaildRecommendTimes + 1);
            uint256 theoreticallyRecommendGain = burnAmount.mul(recommendCoefficient).div(1000);

            uint256 actualRecommendGain = theoreticallyRecommendGain;

            if (theoreticallyRecommendGain >= currentInvest.freeze) {
                actualRecommendGain = currentInvest.freeze;
            }

            currentInvest.free = currentInvest.free.add(actualRecommendGain);
            currentInvest.freeze = currentInvest.freeze.sub(actualRecommendGain);

            currentInvest.recommendGains = currentInvest.recommendGains.add(actualRecommendGain);
            currentInvest.vaildRecommendTimes = currentInvest.vaildRecommendTimes.add(1);

            return actualRecommendGain;
        } else {
            return 0;
        }

    }

    function countDownOverIf()
    internal
    {
        if (countDown.open == true) {

            if (now.sub(countDown.openTime) >= countOverTime) {
                over = true;
                AOQFund aoqFund = AOQFund(fund);
                aoqFund.countDownOverSet();
                emit CountDownOverEvent(now, countDown.openTime, fund.balance, address(this).balance);
            }

        }
    }

    function setCountDown()
    internal
    {
        if (address(this).balance == 0 && inviteCodeCount > 1000) {
            countDown.open = true;
            countDown.openTime = now;
            emit StartCountDownEvent(now, countDown.openTime, fund.balance, address(this).balance);
        }
    }

    function withdraw()
    public
    isHuman()
    isStart()
    {
        countDownOverIf();
        require(address(this).balance > 0, 'balance 0');
        uint256 free = caclFreeGain(msg.sender);
        uint256 withdrawAmount = free;
        require(withdrawAmount.mul(10) >= 1 * ethWei, 'must grater than 0.1');
        address userAddress = msg.sender;
        bool finish = false;
        uint256 currentInvestTimes = user[userAddress].currentInvestTimes;
        Invest storage currentInvest = user[userAddress].invest[currentInvestTimes];

        if (currentInvest.freeze <= gainSettleFee) {
            currentInvest.freeze = 0;
            currentInvest.free = currentInvest.free.add(currentInvest.freeze);
            finish = true;
        }

        if (address(this).balance < free) {
            withdrawAmount = address(this).balance;
            for (uint256 i = user[msg.sender].currentInvestTimes; i > 0; i--) {

                if (user[userAddress].invest[i].free >= withdrawAmount) {
                    user[userAddress].invest[i].withdrawed = user[userAddress].invest[i].withdrawed + withdrawAmount;
                    user[userAddress].invest[i].free = user[userAddress].invest[i].free - withdrawAmount;
                    break;
                } else {
                    user[userAddress].invest[i].withdrawed = user[userAddress].invest[i].withdrawed + user[userAddress].invest[i].free;
                    user[userAddress].invest[i].free = 0;
                    withdrawAmount = withdrawAmount - user[userAddress].invest[i].free;
                }

            }
            msg.sender.transfer(address(this).balance);
            emit WithdrawEvent(msg.sender, currentInvestTimes, address(this).balance, free.sub(address(this).balance), finish);
        } else {
            for (uint256 i = user[msg.sender].currentInvestTimes; i > 0; i--) {

                if (user[userAddress].invest[i].free > 0) {
                    user[userAddress].invest[i].withdrawed = user[userAddress].invest[i].withdrawed + user[userAddress].invest[i].free;
                    user[userAddress].invest[i].free = 0;
                }

            }
            msg.sender.transfer(withdrawAmount);
            emit WithdrawEvent(msg.sender, currentInvestTimes, withdrawAmount, free.sub(withdrawAmount), finish);
        }

        setCountDown();

    }

    function caclFreeGain(address userAddress) internal view returns (uint256){

        uint256 free = 0;

        for (uint256 i = user[userAddress].currentInvestTimes; i > 0; i--) {
            free = free + user[userAddress].invest[i].free;
        }

        return free;
    }

    function getUserInvestInfo(address addr) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    {

        uint256 currentTimes = user[addr].currentInvestTimes;
        uint256 free = caclFreeGain(addr);
        Invest memory currentInvest = user[addr].invest[currentTimes];
        uint256 level = aoqUtil.getLevel(currentInvest.inputAmount);

        if (currentInvest.freeze > 0) {
            return (level, currentInvest.inputAmount, currentInvest.freeze, currentInvest.free, currentInvest.withdrawed, currentInvest.staticGains, currentInvest.dynamicGains, currentInvest.recommendGains, currentInvest.vaildRecommendTimes, free);
        } else {
            return (0, 0, 0, currentInvest.free, 0, 0, 0, 0, 0, free);
        }

    }

    function addDailyGain4User(address invester, uint256 staticGain, uint256 dynamicGain)
    onlyAdmin()
    isHuman()
    public
    {

        bool finish = false;

        uint256 currentInvestTimes = user[invester].currentInvestTimes;
        Invest storage currentInvest = user[invester].invest[currentInvestTimes];
        require(currentInvest.freeze > 0, 'freeze balance not enough');
        if (currentInvest.freeze <= gainSettleFee) {
            currentInvest.free = currentInvest.free.add(currentInvest.freeze);
            emit SettleEvent(invester, currentInvestTimes, currentInvest.freeze, 0, 0, true);
            currentInvest.freeze = 0;
            return;
        }

        uint256 actualStatic = staticGain;
        uint256 actualDynamic = dynamicGain;
        if (currentInvest.freeze <= staticGain) {
            actualStatic = currentInvest.freeze;
            actualDynamic = 0;
            finish = true;
        } else if (currentInvest.freeze <= staticGain + dynamicGain) {
            actualDynamic = currentInvest.freeze.sub(staticGain);
            finish = true;
        }

        currentInvest.staticGains = currentInvest.staticGains.add(actualStatic);
        currentInvest.dynamicGains = currentInvest.dynamicGains.add(actualDynamic);
        currentInvest.freeze = currentInvest.freeze.sub(actualStatic).sub(actualDynamic);

        uint256 total = actualStatic.add(actualDynamic);
        uint256 fundValue = total.div(10);
        if (total > gainSettleFee.add(fundValue)) {
            uint256 free = total.sub(fundValue).sub(gainSettleFee);
            currentInvest.free = currentInvest.free.add(free);
        } else {
            actualStatic = 0;
            actualDynamic = 0;
        }

        if (address(this).balance < fundValue) {
            fundValue = address(this).balance;
        }
        if (fundValue > 0) {
            fund.transfer(fundValue);
        }
        if (address(this).balance < gainSettleFee) {
            gainSettleFee = address(this).balance;
        }
        if (gainSettleFee > 0) {
            adminFeeAddress.transfer(gainSettleFee);
        }

        if (currentInvest.freeze <= gainSettleFee) {
            currentInvest.freeze = 0;
            currentInvest.free = currentInvest.free.add(currentInvest.freeze);
            finish = true;
        }

        emit SettleEvent(invester, currentInvestTimes, actualStatic, actualDynamic, gainSettleFee, finish);
    }

    function getEarlyRedemption(address invester)
    public
    view
    returns (uint256, uint256)
    {
        uint256 currentInvestTimes = user[invester].currentInvestTimes;
        Invest storage currentInvest = user[invester].invest[currentInvestTimes];

        uint256 released = currentInvest.inputAmount.mul(3).sub(currentInvest.freeze);

        if (released >= currentInvest.inputAmount) {
            return (0, 0);
        } else {
            return (currentInvest.inputAmount.sub(released), currentInvest.inputAmount.sub(released).div(2));
        }

    }

    function earlyRedemption()
    isHuman()
    isStart()
    public
    {
        countDownOverIf();

        bool finish = false;
        address invester = msg.sender;
        uint256 currentInvestTimes = user[invester].currentInvestTimes;
        Invest storage currentInvest = user[invester].invest[currentInvestTimes];

        uint256 redempAmount = 0;
        uint256 projectAmount = 0;
        uint256 fundAmount = 0;

        if (currentInvest.freeze <= gainSettleFee) {
            currentInvest.freeze = 0;
            currentInvest.free = currentInvest.free.add(currentInvest.freeze);
            finish = true;
        } else {
            uint256 released = currentInvest.inputAmount.mul(3).sub(currentInvest.freeze);

            require(released < currentInvest.inputAmount, 'the principal is released');

            redempAmount = currentInvest.inputAmount.sub(released).div(2);
            projectAmount = currentInvest.inputAmount.sub(released).div(4);
            fundAmount = currentInvest.inputAmount.sub(released).sub(redempAmount).sub(projectAmount);

            currentInvest.freeze = 0;
            currentInvest.free = currentInvest.free.add(redempAmount);

            if (address(this).balance < projectAmount) {
                projectAmount = address(this).balance;
            }

            if (projectAmount > 0) {
                projectAddress.transfer(projectAmount);
            }

            if (address(this).balance < fundAmount) {
                fundAmount = address(this).balance;
            }

            if (fundAmount > 0) {
                fund.transfer(fundAmount);
            }
            finish = true;

        }
        emit EarlyRedemptionEvent(invester, currentInvestTimes, redempAmount, finish);

        setCountDown();
    }

    function getContractStatus() public view returns (bool, uint256, uint256, uint256, uint256, uint256, bool){
        uint256 investorCount = inviteCodeCount - 1000;
        uint256 fundAmount = fund.balance;
        return (start, address(this).balance, investorCount, investCountTotal, investAmountTotal, fundAmount, over);
    }

    function getCountDownStatus() public view returns (bool, uint256, uint256){

        uint256 end = 0;
        if (countDown.open) {
            end = countDown.openTime.add(countOverTime);
        }

        return (countDown.open, countDown.openTime, end);
    }

    function close() public
    onlyOwner()
    {
        require(address(this).balance == 0, 'No one can get money away!');
        require(over == true, 'Game is not over now!');
        selfdestruct(projectAddress);
    }

    function testCountOverIf()
    public
    onlyAdmin()
    {
        countDownOverIf();
    }

    function getGainSettleFee() public view returns (uint256){
        return gainSettleFee;
    }

    function getInvestorByInviteString(string memory myInviteString) public view returns (uint256, address){
        uint256 inviteCode = string2Code[myInviteString];
        address investor = codeForInvite[inviteCode];
        return (inviteCode, investor);
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