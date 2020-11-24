 

pragma solidity ^0.4.24;


contract DoubleProfit {
    using SafeMath for uint256;
    struct Investor {
        uint256 deposit;
        uint256 paymentTime;
        uint256 withdrawals;
        bool insured;
    }
    uint public countOfInvestors;
    mapping (address => Investor) public investors;

    uint256 public minimum = 0.01 ether;
    uint step = 5 minutes;
    uint ownerPercent = 2;
    uint promotionPercent = 8;
    uint insurancePercent = 2;
    bool public closed = false;

    address public ownerAddress = 0x8462372F80b8f1230E2de9e29D173607b8EE6F99;
    address public promotionAddress = 0xefa08884C1e9f7A4A3F87F5134E9D8fe5309Fb59;
    address public insuranceFundAddress;

    DPInsuranceFund IFContract;

    event Invest(address indexed investor, uint256 amount);
    event Withdraw(address indexed investor, uint256 amount);
    event UserDelete(address indexed investor);
    event ReturnOfDeposit(address indexed investor, uint256 difference);

     
    modifier onlyIF() {
        require(insuranceFundAddress == msg.sender, "access denied");
        _;
    }

     
    function setInsuranceFundAddress(address _insuranceFundAddress) public{
        require(insuranceFundAddress == address(0x0));
        insuranceFundAddress = _insuranceFundAddress;
        IFContract = DPInsuranceFund(insuranceFundAddress);
    }

     
    function setInsured(address _address) public onlyIF returns(uint256, uint256, bool){
        Investor storage investor = investors[_address];
        investor.insured = true;
        return (investor.deposit, investor.withdrawals, investor.insured);
    }

     
    function closeEntrance() public {
        require(address(this).balance < 0.1 ether && !closed);
        closed = true;
    }

     
    function getPhasePercent() view public returns (uint){
        uint contractBalance = address(this).balance;

        if (contractBalance >= 5000 ether) {
            return(88);
        }
        if (contractBalance >= 2500 ether) {
            return(75);
        }
        if (contractBalance >= 1000 ether) {
            return(60);
        }
        if (contractBalance >= 500 ether) {
            return(50);
        }
        if (contractBalance >= 100 ether) {
            return(42);
        } else {
            return(35);
        }

    }

     
    function allocation() private{
        ownerAddress.transfer(msg.value.mul(ownerPercent).div(100));
        promotionAddress.transfer(msg.value.mul(promotionPercent).div(100));
        insuranceFundAddress.transfer(msg.value.mul(insurancePercent).div(100));
    }

     
    function getUserBalance(address _address) view public returns (uint256) {
        Investor storage investor = investors[_address];
        uint percent = getPhasePercent();
        uint256 differentTime = now.sub(investor.paymentTime).div(step);
        uint256 differentPercent = investor.deposit.mul(percent).div(1000);
        uint256 payout = differentPercent.mul(differentTime).div(288);

        return payout;
    }

     
    function withdraw() private {
        Investor storage investor = investors[msg.sender];
        uint256 balance = getUserBalance(msg.sender);
        if (investor.deposit > 0 && address(this).balance > balance && balance > 0) {
            uint256 tempWithdrawals = investor.withdrawals;

            investor.withdrawals = investor.withdrawals.add(balance);
            investor.paymentTime = now;

            if (investor.withdrawals >= investor.deposit.mul(2)){
                investor.deposit = 0;
                investor.paymentTime = 0;
                investor.withdrawals = 0;
                countOfInvestors--;
                if (investor.insured)
                    IFContract.deleteInsured(msg.sender);
                investor.insured = false;
                emit UserDelete(msg.sender);
            } else {
                if (investor.insured && tempWithdrawals < investor.deposit){
                    IFContract.setInfo(msg.sender, investor.deposit, investor.withdrawals);
                }
            }
            msg.sender.transfer(balance);
            emit Withdraw(msg.sender, balance);
        }

    }

     
    function () external payable {
        require(!closed);
        Investor storage investor = investors[msg.sender];
        if (msg.value >= minimum){

            if (investor.deposit == 0){
                countOfInvestors++;
            } else {
                withdraw();
            }

            investor.deposit = investor.deposit.add(msg.value);
            investor.paymentTime = now;

            if (investor.insured){
                IFContract.setInfo(msg.sender, investor.deposit, investor.withdrawals);
            }
            allocation();
            emit Invest(msg.sender, msg.value);
        } else if (msg.value == 0.00000112 ether) {
            returnDeposit();
        } else {
            withdraw();
        }
    }

     
    function returnDeposit() private {
        Investor storage investor = investors[msg.sender];
        require(investor.deposit > 0);
        withdraw();
        uint withdrawalAmount = investor.deposit.sub(investor.withdrawals).sub(investor.deposit.mul(ownerPercent + promotionPercent + insurancePercent).div(100));
        investor.deposit = 0;
        investor.paymentTime = 0;
        investor.withdrawals = 0;
        countOfInvestors--;
        if (investor.insured)
            IFContract.deleteInsured(msg.sender);
        investor.insured = false;
        emit UserDelete(msg.sender);
        msg.sender.transfer(withdrawalAmount);
        emit ReturnOfDeposit(msg.sender, withdrawalAmount);
    }
}


 
 library SafeMath {

     function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         if (_a == 0) {
             return 0;
         }

         uint256 c = _a * _b;
         require(c / _a == _b);

         return c;
     }

     function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
         require(_b > 0);
         uint256 c = _a / _b;

         return c;
     }

     function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
         require(_b <= _a);
         uint256 c = _a - _b;

         return c;
     }

     function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
         uint256 c = _a + _b;
         require(c >= _a);

         return c;
     }

     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
         require(b != 0);
         return a % b;
     }
 }


 
contract DPInsuranceFund {
    using SafeMath for uint256;

     
    struct Investor {
        uint256 deposit;
        uint256 withdrawals;
        bool insured;
    }
    mapping (address => Investor) public investors;
    uint public countOfInvestors;

    bool public startOfPayments = false;
    uint256 public totalSupply;

    uint256 public totalNotReceived;
    address public DPAddress;

    DoubleProfit DPContract;

    event Paid(address investor, uint256 amount, uint256  notRecieve, uint256  partOfNotReceived);
    event SetInfo(address investor, uint256  notRecieve, uint256 deposit, uint256 withdrawals);

     
    modifier onlyDP() {
        require(msg.sender == DPAddress, "access denied");
        _;
    }

     
    function setDPAddress(address _DPAddress) public {
        require(DPAddress == address(0x0));
        DPAddress = _DPAddress;
        DPContract = DoubleProfit(DPAddress);
    }

     
    function privateSetInfo(address _address, uint256 deposit, uint256 withdrawals) private{
        if (!startOfPayments) {
            Investor storage investor = investors[_address];

            if (investor.deposit != deposit){
                totalNotReceived = totalNotReceived.add(deposit.sub(investor.deposit));
                investor.deposit = deposit;
            }

            if (investor.withdrawals != withdrawals){
                uint256 different;

                if (investor.deposit <= withdrawals){
                    different = investor.deposit.sub(investor.withdrawals);
                    if (totalNotReceived >= different && different != 0)
                        totalNotReceived = totalNotReceived.sub(different);
                    else
                        totalNotReceived = 0;
                    withdrawals = investor.deposit;
                } else {
                    different = withdrawals.sub(investor.withdrawals);
                    if (totalNotReceived >= different)
                        totalNotReceived = totalNotReceived.sub(different);
                    else
                        totalNotReceived = 0;

                }
            }
            investor.withdrawals = withdrawals;
            emit SetInfo(_address, totalNotReceived, investor.deposit, investor.withdrawals);
        }
    }

     
    function setInfo(address _address, uint256 deposit, uint256 withdrawals) public onlyDP {
        privateSetInfo(_address, deposit, withdrawals);
    }

     
    function deleteInsured(address _address) public onlyDP {
        Investor storage investor = investors[_address];
        investor.deposit = 0;
        investor.withdrawals = 0;
        investor.insured = false;
        countOfInvestors--;
    }

     
    function beginOfPayments() public {
        require(address(DPAddress).balance < 0.1 ether && !startOfPayments);
        startOfPayments = true;
        totalSupply = address(this).balance;
    }

     
    function () external payable {
        Investor storage investor = investors[msg.sender];
        if (msg.value > 0){
            require(!startOfPayments);
            if (msg.sender != DPAddress && msg.value >= 0.1 ether) {
                require(countOfInvestors.add(1) <= DPContract.countOfInvestors().mul(32).div(100));
                uint256 deposit;
                uint256 withdrawals;
                (deposit, withdrawals, investor.insured) = DPContract.setInsured(msg.sender);
                require(msg.value >= deposit.div(10) && deposit > 0);
                if (msg.value > deposit.div(10)) {
                    msg.sender.transfer(msg.value - deposit.div(10));
                }
                countOfInvestors++;
                privateSetInfo(msg.sender, deposit, withdrawals);
            }
        } else if (msg.value == 0){
            uint256 notReceived = investor.deposit.sub(investor.withdrawals);
            uint256 partOfNotReceived = notReceived.mul(100).div(totalNotReceived);
            uint256 payAmount = totalSupply.div(100).mul(partOfNotReceived);
            require(startOfPayments && investor.insured && notReceived > 0);
            investor.insured = false;
            msg.sender.transfer(payAmount);
            emit Paid(msg.sender, payAmount, notReceived, partOfNotReceived);
        }
    }
}