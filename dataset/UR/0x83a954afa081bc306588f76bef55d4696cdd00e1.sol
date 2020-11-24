 

pragma solidity 0.5.9;


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);  
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


 
contract Ownable {
    address payable public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }


     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

     
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


contract x2jp is Ownable {
    using SafeMath for uint256;

    uint public depositAmount;
    uint public currentPaymentIndex;
    uint public percent;
    uint public lastWinnerPeriod;
    uint public jackpotAmount;

    uint public amountRaised;
    uint public depositorsCount;


    struct Deposit {
        address payable depositor;
        uint amount;
        uint payout;
        uint depositTime;
        uint paymentTime;
    }

     
    Deposit[] public deposits;
     
    mapping (address => uint[]) public depositors;

    event OnDepositReceived(address investorAddress, uint value);
    event OnPaymentSent(address investorAddress, uint value);


    constructor () public {
        depositAmount = 100000000000000000;  
        percent = 130;
        lastWinnerPeriod = 21600;
    }


    function () external payable {
        if (msg.value > 0) {
            makeDeposit();
        } else {
            payout();
        }

    }


    function makeDeposit() internal {
        require(msg.value == depositAmount);

        payout();

        amountRaised = amountRaised.add(msg.value);
        owner.transfer(msg.value.mul(8500).div(100000));
        jackpotAmount = jackpotAmount.add(msg.value.mul(1500).div(100000));

        Deposit memory newDeposit = Deposit(msg.sender, msg.value, msg.value.mul(percent).div(100), now, 0);
        deposits.push(newDeposit);

        if (depositors[msg.sender].length == 0) depositorsCount += 1;

        depositors[msg.sender].push(deposits.length - 1);

        emit OnDepositReceived(msg.sender, msg.value);

        if (address(this).balance >= deposits[currentPaymentIndex].payout && deposits[currentPaymentIndex].paymentTime == 0) {
            deposits[currentPaymentIndex].paymentTime = now;
            deposits[currentPaymentIndex].depositor.send(deposits[currentPaymentIndex].payout);
            emit OnPaymentSent(deposits[currentPaymentIndex].depositor, deposits[currentPaymentIndex].payout);
            currentPaymentIndex += 1;
        }
    }


    function payout() internal {
        if (deposits.length > 0 && deposits[deposits.length - 1].depositTime + lastWinnerPeriod < now && jackpotAmount > 0) {
            uint val = jackpotAmount;
            jackpotAmount = 0;
            deposits[deposits.length - 1].depositor.send(val);
            emit OnPaymentSent(deposits[deposits.length - 1].depositor, val);
            currentPaymentIndex = deposits.length;  
            owner.transfer(address(this).balance - msg.value);
        }
    }


    function getDepositsCount() public view returns (uint) {
        return deposits.length;
    }

    function lastDepositId() public view returns (uint) {
        return deposits.length - 1;
    }

    function getDeposit(uint _id) public view returns (address, uint, uint, uint, uint){
        return (deposits[_id].depositor, deposits[_id].amount, deposits[_id].payout,
        deposits[_id].depositTime, deposits[_id].paymentTime);
    }

    function getUserDepositsCount(address depositor) public view returns (uint) {
        return depositors[depositor].length;
    }

     
    function getLastPayments(uint lastIndex) public view returns (address, uint, uint, uint, uint) {
        uint depositIndex = currentPaymentIndex.sub(lastIndex + 1);

        return (deposits[depositIndex].depositor,
        deposits[depositIndex].amount,
        deposits[depositIndex].payout,
        deposits[depositIndex].depositTime,
        deposits[depositIndex].paymentTime);
    }

    function getUserDeposit(address depositor, uint depositNumber) public view returns(uint, uint, uint, uint) {
        return (deposits[depositors[depositor][depositNumber]].amount,
        deposits[depositors[depositor][depositNumber]].payout,
        deposits[depositors[depositor][depositNumber]].depositTime,
        deposits[depositors[depositor][depositNumber]].paymentTime);
    }

     
    function setLastWinnerPeriod(uint _interval) onlyOwner public {
        require(_interval > 0);
        lastWinnerPeriod = _interval;
    }

}