 

pragma solidity ^0.4.25;
 
contract SmartHashFast {
    using SafeMath for uint256;

    uint256 constant public DEPOSIT_MINIMUM_AMOUNT = 100 finney;
    uint256 constant public MAXIMUM_DEPOSITS_PER_USER = 50;

    uint256 constant public MINIMUM_DAILY_PERCENT = 50;
    uint256 constant public REFERRAL_PERCENT = 50;
    uint256 constant public MARKETING_PERCENT = 100;
    uint256 constant public BonusContract_PERCENT = 50;
    uint256 constant public MAXIMUM_RETURN_PERCENT = 2000;
    uint256 constant public PERCENTS_DIVIDER = 1000;

    uint256 constant public BALANCE_STEP = 300 ether;
    uint256 constant public TIME_STEP = 1 days;
    uint256 constant public STEP_MULTIPLIER = 10;

    address constant public MARKETING_ADDRESS = 0xa5a3A84Cf9FD3f9dE1A6160C7242bA97b4b64065;
    address constant public bonus_ADDRESS = 0xe4661f1D737993824Ef3da64166525ffc3702487;
   
    uint256 public usersCount = 0;
    uint256 public depositsCount = 0;
    uint256 public totalDeposited = 0;
    uint256 public totalWithdrawn = 0;
    event Invest( address indexed investor, uint256 amount);
    
   
    struct User {
        uint256 deposited;
        uint256 withdrawn;
        uint256 timestamp;
        uint256 depositsCount;
        uint256[] deposits;
    }

    struct Deposit {
        uint256 amount;
        uint256 payed;
        uint256 timestamp;
    }

    mapping (address => User) public users;
    mapping (uint256 => Deposit) public deposits;

    function() public payable {
        if (msg.value >= DEPOSIT_MINIMUM_AMOUNT) {
            makeDeposit();
        } else {
            payDividends();
        }
    }

    function createUser() private {
        users[msg.sender] = User({
            deposited : 0,
            withdrawn : 0,
            timestamp : now,
            depositsCount : 0,
            deposits : new uint256[](0)
        });

        usersCount++;
    }

    function makeDeposit() private {
        if (users[msg.sender].deposited == 0) {
            createUser();
        }

        User storage user = users[msg.sender];

        require(user.depositsCount < MAXIMUM_DEPOSITS_PER_USER);

        Deposit memory deposit = Deposit({
            amount : msg.value,
            payed : 0,
            timestamp : now
        });

        deposits[depositsCount] = deposit;
        user.deposits.push(depositsCount);

        user.deposited = user.deposited.add(msg.value);
        totalDeposited = totalDeposited.add(msg.value);
        emit Invest(msg.sender, msg.value);
        user.depositsCount++;
        depositsCount++;

        uint256 marketingAmount = msg.value.mul(MARKETING_PERCENT).div(PERCENTS_DIVIDER);
        MARKETING_ADDRESS.send(marketingAmount);
        uint256 bonusAmount = msg.value.mul(BonusContract_PERCENT).div(PERCENTS_DIVIDER);
        bonus_ADDRESS.send(bonusAmount);
        
        address refAddress = bytesToAddress(msg.data);
        if (refAddress != address(0) && refAddress != msg.sender) {
            uint256 refAmount = msg.value.mul(REFERRAL_PERCENT).div(PERCENTS_DIVIDER);
            refAddress.send(refAmount);
        }
    }

    function payDividends() private {
        User storage user = users[msg.sender];

        uint256 userMaximumReturn = user.deposited.mul(MAXIMUM_RETURN_PERCENT).div(PERCENTS_DIVIDER);

        require(user.deposited > 0 && user.withdrawn < userMaximumReturn);

        uint256 userDividends = 0;

        for (uint256 i = 0; i < user.depositsCount; i++) {
            if (deposits[user.deposits[i]].payed < deposits[user.deposits[i]].amount.mul(MAXIMUM_RETURN_PERCENT).div(PERCENTS_DIVIDER)) {
                uint256 depositId = user.deposits[i];

                Deposit storage deposit = deposits[depositId];

                uint256 depositDividends = getDepositDividends(depositId, msg.sender);
                userDividends = userDividends.add(depositDividends);

                deposits[depositId].payed = deposit.payed.add(depositDividends);
                deposits[depositId].timestamp = now;
            }
        }

        msg.sender.transfer(userDividends.add(msg.value));

        users[msg.sender].timestamp = now;

        users[msg.sender].withdrawn = user.withdrawn.add(userDividends);
        totalWithdrawn = totalWithdrawn.add(userDividends);
    }

    function getDepositDividends(uint256 depositId, address userAddress) private view returns (uint256) {
        uint256 userActualPercent = getUserActualPercent(userAddress);

        Deposit storage deposit = deposits[depositId];

        uint256 timeDiff = now.sub(deposit.timestamp);
        uint256 depositDividends = deposit.amount.mul(userActualPercent).div(PERCENTS_DIVIDER).mul(timeDiff).div(TIME_STEP);

        uint256 depositMaximumReturn = deposit.amount.mul(MAXIMUM_RETURN_PERCENT).div(PERCENTS_DIVIDER);

        if (depositDividends.add(deposit.payed) > depositMaximumReturn) {
            depositDividends = depositMaximumReturn.sub(deposit.payed);
        }

        return depositDividends;
    }

    function getContractActualPercent() public view returns (uint256) {
        uint256 contractBalance = address(this).balance;
        uint256 balanceAddPercent = contractBalance.div(BALANCE_STEP).mul(STEP_MULTIPLIER);

        return MINIMUM_DAILY_PERCENT.add(balanceAddPercent);
    }

    function getUserActualPercent(address userAddress) public view returns (uint256) {
        uint256 contractActualPercent = getContractActualPercent();

        User storage user = users[userAddress];

        uint256 userMaximumReturn = user.deposited.mul(MAXIMUM_RETURN_PERCENT).div(PERCENTS_DIVIDER);

        if (user.deposited > 0 && user.withdrawn < userMaximumReturn) {
            uint256 timeDiff = now.sub(user.timestamp);
            uint256 userAddPercent = timeDiff.div(TIME_STEP).mul(STEP_MULTIPLIER);
        }

        return contractActualPercent.add(userAddPercent);
    }

    function getUserDividends(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 userDividends = 0;

        for (uint256 i = 0; i < user.depositsCount; i++) {
            if (deposits[user.deposits[i]].payed < deposits[user.deposits[i]].amount.mul(MAXIMUM_RETURN_PERCENT).div(PERCENTS_DIVIDER)) {
                userDividends = userDividends.add(getDepositDividends(user.deposits[i], userAddress));
            }
        }

        return userDividends;
    }

    function getUserDeposits(address userAddress) public view returns (uint256[]){
        return users[userAddress].deposits;
    }

    function bytesToAddress(bytes data) private pure returns (address addr) {
        assembly {
            addr := mload(add(data, 20))
        }
    }
}
 
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
}