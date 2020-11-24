 

pragma solidity ^0.4.25;

interface HourglassInterface {
    function() payable external;
    function buy(address _investorAddress) payable external returns(uint256);
    function reinvest() external;
    function exit() payable external;
    function withdraw() payable external;
    function sell(uint256 _amountOfTokens) external;
    function transfer(address _toAddress, uint256 _amountOfTokens) external returns(bool);
    function totalEthereumBalance() external;
    function totalSupply() external;
    function myTokens() external returns(uint256);
    function myDividends(bool _includeReferralBonus) external returns (uint256);
    function balanceOf(address _investorAddress) external returns (uint256);
    function dividendsOf(address _investorAddress) external returns (uint256);
    function sellPrice() payable external returns (uint256);
    function buyPrice() external;
    function calculateTokensReceived(uint256 _ethereumToSpend) external;
    function calculateEthereumReceived(uint256 _tokensToSell) external returns(uint256);
    function purchaseTokens(uint256 _incomingEthereum, address _referredBy) external;
}

contract FastEth {
    
    using SafeMath
    for uint;
    
     
    address constant _parojectMarketing = 0xaC780d067c52227ac7563FBe975eD9A8F235eb35;
    address constant _wmtContractAddress = 0xB487283470C54d28Ed97453E8778d4250BA0F7d4;
         
    HourglassInterface constant WMTContract = HourglassInterface(_wmtContractAddress);
    
     
    uint constant _masterTaxOnInvestment = 10;
    
	 
    address constant private PROMO1 = 0xaC780d067c52227ac7563FBe975eD9A8F235eb35;
	address constant private PROMO2 = 0x6dBFFf54E23Cf6DB1F72211e0683a5C6144E8F03;
	address constant private PRIZE	= 0xeE9B823ef62FfB79aFf2C861eDe7d632bbB5B653;
	
	 
    uint constant public PERCENT = 5;
    
     
    uint constant public BONUS_PERCENT = 3;
	
     
    uint constant StartEpoc = 1541541570;                     
                         
     
    struct Deposit {
        address depositor;  
        uint deposit;    
        uint payout;  
    }

    Deposit[] public queue;   
    mapping (address => uint) public depositNumber;  
    uint public currentReceiverIndex;  
    uint public totalInvested;  

     
     
    function () public payable {
        
        require(now >= StartEpoc);

        if(msg.value > 0){

            require(gasleft() >= 250000);  
            require(msg.value >= 0.05 ether && msg.value <= 10 ether);  
            
             
            queue.push( Deposit(msg.sender, msg.value, 0) );
            depositNumber[msg.sender] = queue.length;

            totalInvested += msg.value;

             
            uint promo1 = msg.value*PERCENT/100;
            PROMO1.transfer(promo1);
			uint promo2 = msg.value*PERCENT/100;
            PROMO2.transfer(promo2);
            
             
            startDivDistribution();            
            
            uint prize = msg.value*BONUS_PERCENT/100;
            PRIZE.transfer(prize);
            
             
            pay();

        }
    }

     
     
     
    function pay() internal {

        uint money = address(this).balance;
        uint multiplier = 118;

         
        for (uint i = 0; i < queue.length; i++){

            uint idx = currentReceiverIndex + i;   

            Deposit storage dep = queue[idx];  

            uint totalPayout = dep.deposit * multiplier / 100;
            uint leftPayout;

            if (totalPayout > dep.payout) {
                leftPayout = totalPayout - dep.payout;
            }

            if (money >= leftPayout) {  

                if (leftPayout > 0) {
                    dep.depositor.transfer(leftPayout);  
                    money -= leftPayout;
                }

                 
                depositNumber[dep.depositor] = 0;
                delete queue[idx];

            } else{

                 
                dep.depositor.transfer(money);  
                dep.payout += money;        
                break;                      

            }

            if (gasleft() <= 55000) {          
                break;                        
            }
        }

        currentReceiverIndex += i;  
    }
    
     
    function startDivDistribution() internal{
             
            WMTContract.buy.value(msg.value.mul(_masterTaxOnInvestment).div(100))(_parojectMarketing);
            uint _wmtBalance = getFundWMTBalance();
            WMTContract.sell(_wmtBalance);
            WMTContract.reinvest();
    }

     
    function getFundWMTBalance() internal returns (uint256){
        return WMTContract.myTokens();
    }
    
     
    function getDepositsCount(address depositor) public view returns (uint) {
        uint c = 0;
        for(uint i=currentReceiverIndex; i<queue.length; ++i){
            if(queue[i].depositor == depositor)
                c++;
        }
        return c;
    }

     
    function getQueueLength() public view returns (uint) {
        return queue.length - currentReceiverIndex;
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
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}