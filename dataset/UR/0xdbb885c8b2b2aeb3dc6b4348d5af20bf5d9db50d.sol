 

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



contract EtProfit{

   using SafeMath for uint;
     
    mapping (address => uint) public balances;
     
    mapping (address => uint) public time;
    
     
    uint steep1 = 1000;
    uint steep2 = 2000;
    uint steep3 = 3000;
    uint steep4 = 4000;
    uint steep5 = 5000;
    
     
    uint dividendsTime = 1 days;
    
    event NewInvestor(address indexed investor, uint deposit);
    event PayOffDividends(address indexed investor, uint value);
    event NewDeposit(address indexed investor, uint value);
    
    uint public allDeposits;
    uint public allPercents;
    uint public allBeneficiaries;
    uint public lastPayment;
    
    
    
     
    modifier isIssetRecepient(){
        require(balances[msg.sender] > 0,  "Deposit not found");
        _;
    }
    
     
    modifier timeCheck(){
        
         require(now >= time[msg.sender].add(dividendsTime), "Too fast payout request. The time of payment has not yet come");
         _;
        
    }
    function getDepositMultiplier()public view  returns(uint){
        uint percent = getPercent();
        uint rate = balances[msg.sender].mul(percent).div(10000);
        uint depositMultiplier = now.sub(time[msg.sender]).div(dividendsTime);
        return(rate.mul(depositMultiplier));
        
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
        
        uint balanceSteep1 = steep1.mul(1 ether);
        uint balanceSteep2 = steep2.mul(1 ether);
        uint balanceSteep3 = steep3.mul(1 ether);
        uint balanceSteep4 = steep4.mul(1 ether);
        uint balanceSteep5 = steep5.mul(1 ether);
        
        
        if(contractBalance < balanceSteep1){
            return(425);
        }
        if(contractBalance >= balanceSteep1 && contractBalance < balanceSteep2){
            return(450);
        }
        if(contractBalance >= balanceSteep2 && contractBalance < balanceSteep3){
            return(475);
        }
        if(contractBalance >= balanceSteep3 && contractBalance < balanceSteep4){
            return(500);
        }
        if(contractBalance >= balanceSteep4 && contractBalance < balanceSteep5){
            return(525);
        }
        if(contractBalance >= balanceSteep5){
            return(550);
        }
        
        
    }
    
    
    
     
    function createDeposit() private{
        
        if(msg.value > 0){
            
            if (balances[msg.sender] == 0){
                emit NewInvestor(msg.sender, msg.value);
                allBeneficiaries+=1;
            }
            
            
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
         
        require((balances[msg.sender] + msg.value) >= balances[msg.sender]);
        createDeposit();
       
    }
    
    
}