 

 

contract Vulnerable {
    address public owner;
    bool public claimed;
    
    constructor() public payable {
        owner = msg.sender;
    }
    
    function() external payable {}

    function claimOwnership() public payable {
        require(msg.value >= 0.1 ether);
        
        if (claimed == false) {
            owner = msg.sender;
            claimed = true;
        }
    }
    
    function retrieve() public {
        require(msg.sender == owner);
        
        msg.sender.transfer(address(this).balance);
    }
}