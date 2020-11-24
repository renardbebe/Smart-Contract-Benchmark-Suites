 

 

 
 

contract EtherTransferTo{
    address public owner;
    
    constructor() public {
    owner = msg.sender;
  }
  
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;

    }
    
    function () payable public {
         
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function withdraw(uint amount) onlyOwner returns(bool) {
        require(amount <= this.balance);
        owner.transfer(amount);
        return true;

    }
    

}