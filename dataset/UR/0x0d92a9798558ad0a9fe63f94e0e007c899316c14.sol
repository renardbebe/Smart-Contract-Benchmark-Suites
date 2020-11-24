 

pragma solidity ^0.5.0;

contract MainContract {
    function getUserInvestInfo(address addr) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
}

contract AOQFund {

    using SafeMath for *;

    uint ethWei = 1 ether;
    uint256  fundValue;
    uint256  gradeOne;
    uint256  gradeTwo;
    uint256  gradeThree;
    address public mainContract;
    bool public canWithdraw = false;
    address owner;
    uint256 public totalInvestorCount;

    address payable projectAddress = 0x64d7d8AA5F785FF3Fb894Ac3b505Bd65cFFC562F;

    uint256 closeTime;

    uint256 public gradeThreeCount;
    uint256 public gradeTwoCount;
    uint256 public gradeOneCount;

    uint256 public gradeThreeCountLimit = 10;
    uint256 public gradeTwoCountLimit = 90;

    struct Invest {
        uint256 level;
        bool withdrawed;
        uint256 lastInvestTime;
        uint256 grade;
    }

    mapping(uint256 => uint256) gradeDistribute;
    mapping(address => Invest) public projectInvestor;
    mapping(address => bool) admin;

    constructor () public {
        owner = msg.sender;
        admin[msg.sender] = true;

        gradeDistribute[3] = 250;
        gradeDistribute[2] = 350;
        gradeDistribute[1] = 400;

    }

     
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

    modifier onlyAdmin(){
        require(admin[msg.sender] == true, 'only admin can call');
        _;
    }

    modifier onlyMainContract(){
        require(msg.sender == mainContract, 'only Main Contract');
        _;
    }

    modifier isContract() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength != 0, "ERROR_ONLY_CONTRACT");
        _;
    }

    function setAdmin(address addr)
    public
    onlyOwner()
    {
        admin[addr] = true;
    }

    function setCloseTime(uint256 cTime)
    public
    onlyAdmin()
    {
        closeTime = cTime;
    }

    function setProjectAddress(address payable pAddress)
    public
    onlyAdmin()
    {
        projectAddress = pAddress;
    }

    function setMainContract(address addr)
    public
    onlyAdmin()
    {
        mainContract = addr;
    }

    function() external payable {

    }

    function setGradeCountLimit(uint256 gradeThreeLimit, uint256 gradeTwoLimit)
    public
    onlyAdmin()
    {
        gradeThreeCountLimit = gradeThreeLimit;
        gradeTwoCountLimit = gradeTwoLimit;
    }

    function countDownOverSet()
    public
    onlyMainContract()
    isContract()
    {
        fundValue = address(this).balance;
        gradeThree = fundValue.mul(gradeDistribute[3]).div(1000);
        gradeTwo = fundValue.mul(gradeDistribute[2]).div(1000);
        gradeOne = fundValue.sub(gradeThree).sub(gradeTwo);
        closeTime = now + 3 days;
    }

    function getFundInfo()
    public
    view
    returns (uint256, uint256, uint256, uint256)
    {
        return (fundValue, gradeThree, gradeTwo, gradeOne);
    }

    function receiveInvest(address investor, uint256 level, bool isNew)
    public
    onlyMainContract()
    isContract()
    {
        uint codeLength;

        assembly {codeLength := extcodesize(investor)}
        require(codeLength == 0, "not a valid human address");

        projectInvestor[investor].level = level;
        projectInvestor[investor].lastInvestTime = now;

        if (isNew) {
            totalInvestorCount = totalInvestorCount.add(1);
        }
    }

    function setFrontInvestors(address investor, uint256 grade)
    public
    onlyAdmin()
    {

        Invest storage investInfo = projectInvestor[investor];

        require(investInfo.level >= 1 && investInfo.withdrawed == false, 'invalid investor');
        require(canWithdraw == false, 'invalid period');
        require(grade < 4, 'invalid grade');

        if (grade == 3 && investInfo.grade != 3) {
            require(gradeThreeCount <= gradeThreeCountLimit, 'only 10 count allowed');
            gradeThreeCount = gradeThreeCount.add(1);
            if (investInfo.grade == 2) {
                gradeTwoCount = gradeTwoCount.sub(1);
            }
        }
        if (grade == 2 && investInfo.grade != 2) {
            require(gradeTwoCount <= gradeTwoCountLimit, 'only 90 count allowed');
            gradeTwoCount = gradeTwoCount.add(1);
            if (investInfo.grade == 3) {
                gradeThreeCount = gradeThreeCount.sub(1);
            }
        }
        if (grade < 2 && investInfo.grade >= 2) {
            if (investInfo.grade == 2) {
                gradeTwoCount = gradeTwoCount.sub(1);
            }
            if (investInfo.grade == 3) {
                gradeThreeCount = gradeThreeCount.sub(1);
            }
        }

        investInfo.grade = grade;

    }

    function setGradeOne(uint256 num)
    public
    onlyAdmin()
    {
        gradeOneCount = num;
    }

    function openCanWithdraw(uint256 open)
    public
    onlyAdmin()
    {
        if (open == 1) {
            canWithdraw = true;
        } else {
            canWithdraw = false;
        }
    }

    function getInvest(address investor) internal view returns (uint256){
        MainContract mainContractIns = MainContract(mainContract);
        uint256 three;
        (,,three,,,,,,,) = mainContractIns.getUserInvestInfo(investor);
        return three;
    }

    function withdrawFund()
    public
    isHuman()
    {
        require(canWithdraw == true, 'can not withdraw now');

        Invest storage investInfo = projectInvestor[msg.sender];
        require(investInfo.withdrawed == false, 'withdrawed address');

        uint256 withdrawAmount;

        withdrawAmount = getFundReward(msg.sender);

        if (withdrawAmount > 0) {
            investInfo.withdrawed = true;
        }

        msg.sender.transfer(withdrawAmount);

    }

    function getFundReward(address addr)
    public
    view
    isHuman()
    returns (uint256)
    {

        Invest storage investInfo = projectInvestor[addr];

        uint256 withdrawAmount = 0;

        uint256 freeze;
        freeze = getInvest(addr);

        if (canWithdraw != false && investInfo.withdrawed != true && freeze > 0) {

            if (investInfo.grade == 3 && gradeThreeCount > 0) {
                withdrawAmount = gradeThree.div(gradeThreeCount);
            } else if (investInfo.grade == 2 && gradeTwoCount > 0) {
                withdrawAmount = gradeTwo.div(gradeTwoCount);
            }

            if (investInfo.grade < 2 && gradeOneCount > 0) {
                withdrawAmount = gradeOne.div(gradeOneCount);
            }
        }

        return withdrawAmount;

    }

    function close() public
    onlyOwner()
    {
        require(canWithdraw == true && gradeThreeCount > 0, 'Game is not start over now!');
        require(now > closeTime, 'only 3 days later Game Over');
        selfdestruct(projectAddress);
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