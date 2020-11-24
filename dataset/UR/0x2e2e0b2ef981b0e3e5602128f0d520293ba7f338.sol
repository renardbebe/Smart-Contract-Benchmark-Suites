 

pragma solidity ^0.4.25;

 
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
 
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
         
        uint256 c = a / b;
         
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }
 
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
 
}


library Address {
    function toAddress(bytes source) internal pure returns(address addr) {
        assembly { addr := mload(add(source,0x14)) }
        return addr;
    }
}


 
contract SInv {
     
    using SafeMath for uint;
    using Address for *;

     
    mapping(address => uint) public userDeposit;
     
    mapping(address=>uint) public RefBonus;
     
    mapping(address=>uint) public UserEarnings;
     
    mapping(address => uint) public userTime;
     
    mapping(address => uint) public persentWithdraw;
     
    address public projectFund =  0xB3cE9796aCDC1855bd6Cec85a3403f13C918f1F2;
     
    uint projectPercent = 5;  
     
    uint public chargingTime = 24 hours;
    uint public startPercent = 250*10;
    uint public countOfInvestors;
    uint public daysOnline;
    uint public dividendsPaid;

    constructor() public {
        daysOnline = block.timestamp;
    }    
    
    modifier isIssetUser() {
        require(userDeposit[msg.sender] > 0, "Deposit not found");
        _;
    }
 
    modifier timePayment() {
        require(now >= userTime[msg.sender].add(chargingTime), "Too fast payout request");
        _;
    }
    
    function() external payable {
        if (msg.value > 0) {
             
            makeDepositA(msg.data.toAddress());
        }
        else {
            collectPercent();
        }
    }

     
    function collectPercent() isIssetUser timePayment public {
            uint payout;
            uint multipl;
            (payout,multipl) = payoutAmount(msg.sender);
            userTime[msg.sender] += multipl*chargingTime;
            persentWithdraw[msg.sender] += payout;
            msg.sender.transfer(payout);
            UserEarnings[msg.sender]+=payout;
            dividendsPaid += payout;
            uint UserInitDeposit=userDeposit[msg.sender];
            projectFund.transfer(UserInitDeposit.mul(projectPercent).div(1000));
    }

     
    function Reinvest() isIssetUser timePayment external {
        uint payout;
        uint multipl;
        (payout,multipl) = payoutAmount(msg.sender);
        userTime[msg.sender] += multipl*chargingTime;
        userDeposit[msg.sender]+=payout;
        UserEarnings[msg.sender]+=payout;
        uint UserInitDeposit=userDeposit[msg.sender];
        projectFund.transfer(UserInitDeposit.mul(projectPercent).div(1000));
    }
 
     
    function makeDeposit(bytes32 referrer) public payable {
        if (msg.value > 0) {
            if (userDeposit[msg.sender] == 0) {
                countOfInvestors += 1;

                 
                if((RefNameToAddress[referrer] != address(0x0) && referrer > 0 && TheGuyWhoReffedMe[msg.sender] == address(0x0) && RefNameToAddress[referrer] != msg.sender)) {
                     
                    TheGuyWhoReffedMe[msg.sender] = RefNameToAddress[referrer];
                    newRegistrationwithRef();
                }
            }
            if (userDeposit[msg.sender] > 0 && now > userTime[msg.sender].add(chargingTime)) {
                collectPercent();
            }

            userDeposit[msg.sender] = userDeposit[msg.sender].add(msg.value);
            userTime[msg.sender] = now;

        } else {
            collectPercent();
        }
    }
    
     
    function makeDepositA(address referrer) public payable {
        if (msg.value > 0) {
            if (userDeposit[msg.sender] == 0) {
                countOfInvestors += 1;
                 
                if((referrer != address(0x0) && referrer > 0 && TheGuyWhoReffedMe[msg.sender] == address(0x0) && referrer != msg.sender)) {
                     
                    TheGuyWhoReffedMe[msg.sender] = referrer;
                    newRegistrationwithRef();
                }
            }
            if (userDeposit[msg.sender] > 0 && now > userTime[msg.sender].add(chargingTime)) {
                collectPercent();
            }
            userDeposit[msg.sender] = userDeposit[msg.sender].add(msg.value);
            userTime[msg.sender] = now;

        } else {
            collectPercent();
        }
    }
     
    function getUserEarnings(address addr) public view returns(uint)
    {
        return UserEarnings[addr];
    }
 
     
    function persentRate() public view returns(uint) {
        return(startPercent);
 
    }
 
     
    function PayOutRefBonus() external
    {       
         
        require(RefBonus[msg.sender]>0,"You didn't earn any bonus");
        uint payout = RefBonus[msg.sender];
         
        msg.sender.transfer(payout);
         
        RefBonus[msg.sender]=0;
    }
 
 
     
    function payoutAmount(address addr) public view returns(uint,uint) {
        uint rate = userDeposit[addr].mul(startPercent).div(100000);
        uint interestRate = now.sub(userTime[addr]).div(chargingTime);
        uint withdrawalAmount = rate.mul(interestRate);
        return (withdrawalAmount, interestRate);
    }

 
    mapping (address=>address) public TheGuyWhoReffedMe;
 
    mapping (address=>bytes32) public MyPersonalRefName;
     
    mapping (bytes32=>address) public RefNameToAddress;
    
     
    mapping (address=>uint256) public referralCounter;
     
    mapping (address=>uint256) public referralEarningsCounter;

     
    function createMyPersonalRefName(bytes32 _RefName) external payable
    {  
         
        require(_RefName > 0);

         
        require(RefNameToAddress[_RefName]==0, "Somebody else owns this Refname");
 
         
        require(MyPersonalRefName[msg.sender] == 0, "You already registered a Ref");  
 
         
        MyPersonalRefName[msg.sender]= _RefName;

        RefNameToAddress[_RefName]=msg.sender;

    }
 
    function newRegistrationwithRef() private
    {
         
        CheckFirstGradeRefAdress();
        CheckSecondGradeRefAdress();
        CheckThirdGradeRefAdress();
    }
 
     
    function CheckFirstGradeRefAdress() private
    {  
         
         
         
 
         
        if(TheGuyWhoReffedMe[msg.sender]>0) {
         
            RefBonus[TheGuyWhoReffedMe[msg.sender]] += msg.value * 2/100;
            referralEarningsCounter[TheGuyWhoReffedMe[msg.sender]] += msg.value * 2/100;
            referralCounter[TheGuyWhoReffedMe[msg.sender]]++;
        }
    }
 
     
    function CheckSecondGradeRefAdress() private
    {
         
         
         
         
         
         
        if(TheGuyWhoReffedMe[TheGuyWhoReffedMe[msg.sender]]>0) {
         
            RefBonus[TheGuyWhoReffedMe[TheGuyWhoReffedMe[msg.sender]]] += msg.value * 2/200;
            referralEarningsCounter[TheGuyWhoReffedMe[TheGuyWhoReffedMe[msg.sender]]] += msg.value * 2/200;
            referralCounter[TheGuyWhoReffedMe[TheGuyWhoReffedMe[msg.sender]]]++;
        }
    }
 
     
    function CheckThirdGradeRefAdress() private
    {
         
         
         
         
         
         
         
         
        if (TheGuyWhoReffedMe[TheGuyWhoReffedMe[TheGuyWhoReffedMe[msg.sender]]]>0) {

            RefBonus[TheGuyWhoReffedMe[TheGuyWhoReffedMe[TheGuyWhoReffedMe[msg.sender]]]] += msg.value * 2/400;
            referralEarningsCounter[TheGuyWhoReffedMe[TheGuyWhoReffedMe[TheGuyWhoReffedMe[msg.sender]]]] += msg.value * 2/400;
            referralCounter[TheGuyWhoReffedMe[TheGuyWhoReffedMe[TheGuyWhoReffedMe[msg.sender]]]]++;
        }
    }
    
     
    function getMyRefName(address addr) public view returns(bytes32)
    {
        return (MyPersonalRefName[addr]);
    }

    function getMyRefNameAsString(address addr) public view returns(string) {
        return bytes32ToString(MyPersonalRefName[addr]);
    }

    function bytes32ToString(bytes32 x) internal pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}