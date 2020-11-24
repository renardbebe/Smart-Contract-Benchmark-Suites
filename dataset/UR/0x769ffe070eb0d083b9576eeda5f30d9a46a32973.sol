 

pragma solidity ^0.4.25;

 

contract WheelOfEther
{
    using SafeMath for uint;

     
    Randomizer private rand;

     
    modifier onlyHuman() {
        require(tx.origin == msg.sender);
        _;
    }

    modifier gameActive() {
        require(gamePaused == false);
        _;
    }

    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }

     
    event onDeposit(
        address indexed customer,
        uint256 amount,
        uint256 balance,
        uint256 devFee,
        uint timestamp
    );

    event onWithdraw(
        address indexed customer,
        uint256 amount,
        uint256 balance,
        uint timestamp
    );

    event spinResult(
        address indexed customer,
        uint256 wheelNumber,
        uint256 outcome,
        uint256 betAmount,
        uint256 returnAmount,
        uint256 customerBalance,
        uint timestamp
    );

     
    address public admin;
    uint256 public devBalance = 0;

     
    bool public gamePaused = false;

     
    uint8 private randMin  = 1;
    uint8 private randMax  = 80;

     
    uint256 public minBet = 0.01 ether;
    uint256 public maxBet = 10 ether;

     
    uint8[10] public brackets = [1,3,6,12,24,40,56,68,76,80];

     
    uint256 private          globalFactor   = 10e21;
    uint256 constant private constantFactor = 10e21 * 10e21;

     
    mapping(address => uint256) private personalFactor;
    mapping(address => uint256) private personalLedger;


     
    constructor() public {
        admin = msg.sender;
    }

     
    function setRandomizer(address _rand) external onlyAdmin {
        rand = Randomizer(_rand);
    }

    function gamePause() external onlyAdmin {
        gamePaused = true;
    }

    function gameUnpause() external onlyAdmin {
        gamePaused = false;
    }

    function refund(address customer) external onlyAdmin {
        uint256 amount = getBalanceOf(customer);
        customer.transfer(amount);
        personalLedger[customer] = 0;
        personalFactor[customer] = constantFactor / globalFactor;
        emit onWithdraw(customer, amount, getBalance(), now);
    }

    function withdrawDevFees() external onlyAdmin {
        admin.transfer(devBalance);
        devBalance = 0;
    }


     
    function getBalance() public view returns(uint256 balance) {
        return address(this).balance;
    }

    function getBalanceOf(address customer) public view returns(uint256 balance) {
        return personalLedger[customer].mul(personalFactor[customer]).mul(globalFactor) / constantFactor;
    }

    function getBalanceMy() public view returns(uint256 balance) {
        return getBalanceOf(msg.sender);
    }

    function betPool(address customer) public view returns(uint256 value) {
        return address(this).balance.sub(getBalanceOf(customer)).sub(devBalance);
    }


     
    function deposit() public payable onlyHuman gameActive {
        address customer = msg.sender;
        require(msg.value >= (minBet * 2));

         
        uint256 devFee = msg.value / 50;
        devBalance = devBalance.add(devFee);

        personalLedger[customer] = getBalanceOf(customer).add(msg.value).sub(devFee);
        personalFactor[customer] = constantFactor / globalFactor;

        emit onDeposit(customer, msg.value, getBalance(), devFee, now);
    }

    function withdraw(uint256 amount) public onlyHuman {
        address customer = msg.sender;
        require(amount > 0);
        require(amount <= getBalanceOf(customer));

        customer.transfer(amount);
        personalLedger[customer] = getBalanceOf(customer).sub(amount);
        personalFactor[customer] = constantFactor / globalFactor;

        emit onWithdraw(customer, amount, getBalance(), now);
    }

    function withdrawAll() public onlyHuman {
        withdraw(getBalanceOf(msg.sender));
    }


     
    function spin(uint256 betAmount) public onlyHuman gameActive returns(uint256 resultNum) {
        address customer = msg.sender;
        require(betAmount              >= minBet);
        require(getBalanceOf(customer) >= betAmount);

        if (betAmount > maxBet) {
            betAmount = maxBet;
        }
        if (betAmount > betPool(customer) / 10) {
            betAmount = betPool(customer) / 10;
        }
        resultNum = bet(betAmount, customer);
    }

    function spinAll() public onlyHuman gameActive returns(uint256 resultNum) {
        resultNum = spin(getBalanceOf(msg.sender));
    }

    function spinDeposit() public payable onlyHuman gameActive returns(uint256 resultNum) {
        address customer  = msg.sender;
        uint256 betAmount = msg.value;

        require(betAmount >= (minBet * 2));

         
        uint256 devFee = betAmount / 50;
        devBalance     = devBalance.add(devFee);
        betAmount      = betAmount.sub(devFee);

        personalLedger[customer] = getBalanceOf(customer).add(msg.value).sub(devFee);
        personalFactor[customer] = constantFactor / globalFactor;

        if (betAmount >= maxBet) {
            betAmount = maxBet;
        }
        if (betAmount > betPool(customer) / 10) {
            betAmount = betPool(customer) / 10;
        }

        resultNum = bet(betAmount, customer);
    }


     
    function bet(uint256 betAmount, address customer) private returns(uint256 resultNum) {
        resultNum      = uint256(rand.getRandomNumber(randMin, randMax + randMin));
        uint256 result = determinePrize(resultNum);

        uint256 returnAmount;

        if (result < 5) {                                                
            uint256 winAmount;
            if (result == 0) {                                           
                winAmount = betAmount.mul(9) / 10;                       
            } else if (result == 1) {                                    
                winAmount = betAmount.mul(8) / 10;                       
            } else if (result == 2) {                                    
                winAmount = betAmount.mul(7) / 10;                       
            } else if (result == 3) {                                    
                winAmount = betAmount.mul(6) / 10;                       
            } else if (result == 4) {                                    
                winAmount = betAmount.mul(3) / 10;                       
            }
            weGotAWinner(customer, winAmount);
            returnAmount = betAmount.add(winAmount);
        } else if (result == 5) {                                        
            returnAmount = betAmount;
        } else {                                                         
            uint256 lostAmount;
            if (result == 6) {                                           
                lostAmount = betAmount / 10;                             
            } else if (result == 7) {                                    
                lostAmount = betAmount / 4;                              
            } else if (result == 8) {                                    
                lostAmount = betAmount / 2;                              
            } else if (result == 9) {                                    
                lostAmount = betAmount;                                  
            }
            goodLuck(customer, lostAmount);
            returnAmount = betAmount.sub(lostAmount);
        }

        uint256 newBalance = getBalanceOf(customer);
        emit spinResult(customer, resultNum, result, betAmount, returnAmount, newBalance, now);
        return resultNum;
    }


    function determinePrize(uint256 result) private view returns(uint256 resultNum) {
        for (uint8 i = 0; i < 10; i++) {
            if (result <= brackets[i]) {
                return i;
            }
        }
    }


    function goodLuck(address customer, uint256 lostAmount) private {
        uint256 customerBalance  = getBalanceOf(customer);
        uint256 globalIncrease   = globalFactor.mul(lostAmount) / betPool(customer);
        globalFactor             = globalFactor.add(globalIncrease);
        personalFactor[customer] = constantFactor / globalFactor;

        if (lostAmount > customerBalance) {
            lostAmount = customerBalance;
        }
        personalLedger[customer] = customerBalance.sub(lostAmount);
    }

    function weGotAWinner(address customer, uint256 winAmount) private {
        uint256 customerBalance  = getBalanceOf(customer);
        uint256 globalDecrease   = globalFactor.mul(winAmount) / betPool(customer);
        globalFactor             = globalFactor.sub(globalDecrease);
        personalFactor[customer] = constantFactor / globalFactor;
        personalLedger[customer] = customerBalance.add(winAmount);
    }
}


 
contract Randomizer {
    function getRandomNumber(int256 min, int256 max) public returns(int256);
}


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}