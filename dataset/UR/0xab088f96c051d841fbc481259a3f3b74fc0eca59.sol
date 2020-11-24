 

pragma solidity ^0.4.25;  
 

contract Hours25 {
    mapping (address => uint256) public balances;
    mapping (address => uint256) public time_stamp;
    mapping (address => uint256) public receive_funds;
    uint256 internal total_funds;
    
    address commission;
    address advertising;

    constructor() public {
        commission = msg.sender;
        advertising = 0xD93dFA3966dDac00C78D24286199CE318E1Aaac6;
    }

    function showTotal() public view returns (uint256) {
        return total_funds;
    }

    function showProfit(address _investor) public view returns (uint256) {
        return receive_funds[_investor];
    }

    function showBalance(address _investor) public view returns (uint256) {
        return balances[_investor];
    }

    function isLastWithdraw(address _investor) public view returns(bool) {
        address investor = _investor;
        uint256 profit = calcProfit(investor);
        bool result = !((balances[investor] == 0) || ((balances[investor]  * 1035) / 1000  > receive_funds[investor] + profit)); 
        return result;
    }

    function calcProfit(address _investor) internal view returns (uint256) {
        uint256 profit = balances[_investor]*69/100000*(now-time_stamp[_investor])/60;
        return profit;
    }


    function () external payable {
        require(msg.value > 0,"Zero. Access denied.");
        total_funds +=msg.value;
        address investor = msg.sender;
        commission.transfer(msg.value * 1 / 100);
        advertising.transfer(msg.value * 1 / 100);

        uint256 profit = calcProfit(investor);
        investor.transfer(profit);

        if (isLastWithdraw(investor)){
          
            balances[investor] = 0;
            receive_funds[investor] = 0;
           
        }
        else {
        receive_funds[investor] += profit;
        balances[investor] += msg.value;
            
        }
        time_stamp[investor] = now;
    }

}