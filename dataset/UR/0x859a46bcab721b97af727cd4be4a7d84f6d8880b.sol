 

pragma solidity ^0.4.24;

 
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

contract Main {

    using SafeMath for uint;

     
    mapping(uint => mapping(address => uint)) public balance;
    mapping(uint => mapping(address => uint)) public time;
    mapping(uint => mapping(address => uint)) public percentWithdraw;
    mapping(uint => mapping(address => uint)) public allPercentWithdraw;
    mapping(uint => uint) public investorsByRound;

    uint public stepTime = 24 hours;
    uint public countOfInvestors = 0;
    uint public totalRaised;
    uint public rounds_counter;
    uint public projectPercent = 10;
    uint public totalWithdrawed = 0;
    bool public started;

    address public ownerAddress;

    event Invest(uint indexed round, address indexed investor, uint256 amount);
    event Withdraw(uint indexed round, address indexed investor, uint256 amount);

    modifier userExist() {
        require(balance[rounds_counter][msg.sender] > 0, "Address not found");
        _;
    }

    modifier checkTime() {
        require(now >= time[rounds_counter][msg.sender].add(stepTime), "Too fast payout request");
        _;
    }

    modifier onlyStarted() {
        require(started == true);
        _;
    }

     
    function collectPercent() userExist checkTime internal {

         
         
        if ((balance[rounds_counter][msg.sender].mul(2)) <= allPercentWithdraw[rounds_counter][msg.sender]) {
            balance[rounds_counter][msg.sender] = 0;
            time[rounds_counter][msg.sender] = 0;
            percentWithdraw[rounds_counter][msg.sender] = 0;
        } else {
             
             

            uint payout = payoutAmount();   

            percentWithdraw[rounds_counter][msg.sender] = percentWithdraw[rounds_counter][msg.sender].add(payout);
            allPercentWithdraw[rounds_counter][msg.sender] = allPercentWithdraw[rounds_counter][msg.sender].add(payout);

             
            msg.sender.transfer(payout);
            totalWithdrawed = totalWithdrawed.add(payout);

            emit Withdraw(rounds_counter, msg.sender, payout);
        }

    }

     
     
     
    function percentRate() public view returns(uint) {

        uint contractBalance = address(this).balance;
        uint user_balance = balance[rounds_counter][msg.sender];
        uint contract_depending_percent = 0;

         
         
         
        if (contractBalance >= 10000 ether) {
            contract_depending_percent = 20;
        } else if (contractBalance >= 5000 ether) {
            contract_depending_percent = 15;
        } else if (contractBalance >= 1000 ether) {
            contract_depending_percent = 10;
        }

         
        if (user_balance < 9999999999999999999) {           
          return (30 + contract_depending_percent);
        } else if (user_balance < 29999999999999999999) {   
          return (35 + contract_depending_percent);
        } else if (user_balance < 49999999999999999999) {   
          return (40 + contract_depending_percent);
        } else {                                         
          return (45 + contract_depending_percent);
        }

    }


     
    function payoutAmount() public view returns(uint256) {
         
        uint256 percent = percentRate();

        uint256 different = now.sub(time[rounds_counter][msg.sender]).div(stepTime);

         
         
        uint256 rate = balance[rounds_counter][msg.sender].mul(percent).div(1000);

        uint256 withdrawalAmount = rate.mul(different).sub(percentWithdraw[rounds_counter][msg.sender]);

        return withdrawalAmount;
    }

     
    function deposit() private {
        if (msg.value > 0) {  
            require(balance[rounds_counter][msg.sender] == 0);   

            if (balance[rounds_counter][msg.sender] == 0) {   
              countOfInvestors = countOfInvestors.add(1);
              investorsByRound[rounds_counter] = investorsByRound[rounds_counter].add(1);
            }

             
             
            if (
              balance[rounds_counter][msg.sender] > 0 &&
              now > time[rounds_counter][msg.sender].add(stepTime)
            ) {
                collectPercent();
                percentWithdraw[rounds_counter][msg.sender] = 0;
            }

            balance[rounds_counter][msg.sender] = balance[rounds_counter][msg.sender].add(msg.value);
            time[rounds_counter][msg.sender] = now;

             
            ownerAddress.transfer(msg.value.mul(projectPercent).div(100));
            totalRaised = totalRaised.add(msg.value);

            emit Invest(rounds_counter, msg.sender, msg.value);
        } else {   
            collectPercent();
        }
    }

     
    function() external payable onlyStarted {
         
        require(balance[rounds_counter][msg.sender].add(msg.value) <= 100 ether, "More than 100 ethers");

         
         
        if (address(this).balance < totalRaised.div(100).mul(10)) {
            startNewRound();
        }

        deposit();
    }

     
     
    function startNewRound() internal {
        rounds_counter = rounds_counter.add(1);
        totalRaised = address(this).balance;
    }

     
    function start() public {
        require(ownerAddress == msg.sender);
        started = true;
    }

    constructor() public {
        ownerAddress = msg.sender;
        started = false;
    }

}