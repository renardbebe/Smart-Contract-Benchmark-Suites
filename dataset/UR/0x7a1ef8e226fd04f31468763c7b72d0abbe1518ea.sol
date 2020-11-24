 

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
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
        return msg.sender == _owner;
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

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity 0.5.10;




contract Game is Ownable {
    using SafeMath for uint256;

    uint constant public depositAmount = 0.01 ether;
    uint public currentPaymentIndex;
    uint constant public percent = 150;
    uint constant public startBlock = 50;  

     
    address payable constant public organizer = 0xECf10d5b0c4c2C63dF6E3465ceAbEA3D536491dd;
    uint constant public feeOrganizer = 9;  

    address payable constant public technician = 0x60B4Aa91028Ab07DF9bee21e4F7d8767d9D6dEbf;
    uint constant public feeTechnician = 1;  

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

    event OnDepositReceived(address depositorAddress, uint depositTime, uint depositorsCount, uint depositsCount);
    event OnPaymentSent(address payee, uint paymentTime, uint paidDepositNumber);

    constructor () public {
    }


    function () external payable {
        makeDeposit();
    }


    function makeDeposit() internal {
        require(msg.value == depositAmount);
        require(block.number >= startBlock);

        Deposit memory newDeposit = Deposit(msg.sender, msg.value, msg.value.mul(percent).div(100), now, 0);
        deposits.push(newDeposit);

        if (depositors[msg.sender].length == 0) depositorsCount += 1;

        depositors[msg.sender].push(deposits.length - 1);

        amountRaised = amountRaised.add(msg.value);

        emit OnDepositReceived(msg.sender, msg.value, depositorsCount, deposits.length);

        organizer.transfer(msg.value.mul(feeOrganizer).div(100));
        technician.transfer(msg.value.mul(feeTechnician).div(100));

        if (address(this).balance >= deposits[currentPaymentIndex].payout && deposits[currentPaymentIndex].paymentTime == 0) {
            deposits[currentPaymentIndex].paymentTime = now;
            deposits[currentPaymentIndex].depositor.transfer(deposits[currentPaymentIndex].payout);
            emit OnPaymentSent(deposits[currentPaymentIndex].depositor, now, currentPaymentIndex);
            currentPaymentIndex += 1;
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
    
}