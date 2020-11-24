 

contract SimplePonzi {
    address public currentInvestor;
    uint public currentInvestment = 0;
    
    function () payable public {
        require(msg.value > currentInvestment);
        
         
        currentInvestor.send(currentInvestment);

         
        currentInvestor = msg.sender;
        currentInvestment = msg.value;

    }
}