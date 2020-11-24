 

 



pragma solidity ^0.4.24;
contract Contractus {
    mapping (address => uint256) public balances;
    mapping (address => uint256) public timestamp;
    mapping (address => uint256) public receiveFunds;
    uint256 internal totalFunds;
    
    address support;
    address marketing;

    constructor() public {
        support = msg.sender;
        marketing = 0x53B83d7be0D19b9935363Af1911b7702Cc73805e;
    }

    function showTotal() public view returns (uint256) {
        return totalFunds;
    }

    function showProfit(address _investor) public view returns (uint256) {
        return receiveFunds[_investor];
    }

    function showBalance(address _investor) public view returns (uint256) {
        return balances[_investor];
    }

     
    function isLastWithdraw(address _investor) public view returns(bool) {
        address investor = _investor;
        uint256 profit = calcProfit(investor);
        bool result = !((balances[investor] == 0) || (balances[investor] * 2 > receiveFunds[investor] + profit));
        return result;
    }

    function calcProfit(address _investor) internal view returns (uint256) {
        uint256 profit = balances[_investor]*25/1000*(now-timestamp[_investor])/86400;  
        return profit;
    }


    function () external payable {
        require(msg.value > 0,"Zero. Access denied.");
        totalFunds +=msg.value;
        address investor = msg.sender;
        support.transfer(msg.value * 3 / 100);
        marketing.transfer(msg.value * 7 / 100);

        uint256 profit = calcProfit(investor);
        investor.transfer(profit);

        if (isLastWithdraw(investor)){
             
            balances[investor] = 0;
            receiveFunds[investor] = 0;
           
        }
        else {
        receiveFunds[investor] += profit;
        balances[investor] += msg.value;
            
        }
        timestamp[investor] = now;
    }

}