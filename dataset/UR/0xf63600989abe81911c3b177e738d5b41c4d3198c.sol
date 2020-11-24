 

contract SimplePonzi {
    address public currentInvestor;
    uint public currentInvestment = 0;
    
    function () payable public {
        require(msg.value > currentInvestment);
        
         
        currentInvestor.send(msg.value);

         
        currentInvestor = msg.sender;
        currentInvestment = msg.value;

    }
}