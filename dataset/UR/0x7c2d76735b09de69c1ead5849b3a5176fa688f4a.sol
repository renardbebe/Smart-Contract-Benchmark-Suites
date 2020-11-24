 

 
pragma solidity ^0.4.25;

contract Highfiveeth {
    mapping (address => uint256) invested;
    mapping (address => uint256) atBlock;
    uint256 minValue; 
    address owner1;     
    address owner2;     
    address owner3;     
    event Withdraw (address indexed _to, uint256 _amount);
    event Invested (address indexed _to, uint256 _amount);
    
    constructor () public {
        owner1 = 0xA20AFFf23F2F069b7DE37D8bbf9E5ce0BA97989C;     
        owner2 = 0x9712dF59b31226C48F1c405E7C7e36c0D1c00031;     
        owner3 = 0xC0a411924b146c19e8E07c180aeE4cC945Cc28a2;     
        minValue = 0.01 ether;  
    }
    
     
        function getPercent(address _investor) internal view returns (uint256) {
        uint256 percent = 400;
        if(invested[_investor] >= 1 ether && invested[_investor] < 10 ether) {
            percent = 425;
        }

        if(invested[_investor] >= 10 ether && invested[_investor] < 20 ether) {
            percent = 450;
        }

        if(invested[_investor] >= 20 ether && invested[_investor] < 40 ether) {
            percent = 475;
        }

        if(invested[_investor] >= 40 ether) {
            percent = 500;
        }
        
        return percent;
    }
    
     
    function () external payable {
        require (msg.value == 0 || msg.value >= minValue,"Min Amount for investing is 0.01 Ether.");
        
        uint256 invest = msg.value;
        address sender = msg.sender;
         
        owner1.transfer(invest / 10);
        owner2.transfer(invest / 100);
        owner3.transfer(invest / 100);
            
        if (invested[sender] != 0) {
            uint256 amount = invested[sender] * getPercent(sender) / 10000 * (block.number - atBlock[sender]) / 5900;

             
            sender.transfer(amount);
            emit Withdraw (sender, amount);
        }

        atBlock[sender] = block.number;
        invested[sender] += invest;
        if (invest > 0){
            emit Invested(sender, invest);
        }
    }
    
     
    function showDeposit (address _deposit) public view returns(uint256) {
        return invested[_deposit];
    }

     
    function showLastChange (address _deposit) public view returns(uint256) {
        return atBlock[_deposit];
    }

     
    function showUnpayedPercent (address _deposit) public view returns(uint256) {
        uint256 amount = invested[_deposit] * getPercent(_deposit) / 10000 * (block.number - atBlock[_deposit]) / 5900;
        return amount;
    }


}