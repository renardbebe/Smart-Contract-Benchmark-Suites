 

contract SimplePonzi {
    address public currentInvestor;
    uint public currentInvestment = 0;
    
    function () payable public {
         
        uint minimumInvestment = currentInvestment * 11 / 10;
        require(msg.value > minimumInvestment);

         
        address previousInvestor = currentInvestor;
        currentInvestor = msg.sender;
        currentInvestment = msg.value;

        
         
        previousInvestor.send(msg.value);
    }
}