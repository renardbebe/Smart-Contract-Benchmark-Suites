 

pragma solidity 0.5.9;

 

contract Retainer {
    
    address payable public beneficiary;  
    uint256 public fee;  
    
    address private admin;
    
    event Retained(address indexed, string request);  
    
    modifier onlyAdmin()  
    {
        require(
            msg.sender == admin,
            "Sender not authorized."
        );
        _;
    }
    
    constructor(uint256 _fee) public {  
        beneficiary = msg.sender;
        admin = msg.sender;
        fee = _fee;
    }

    function payRetainerFee(string memory request) public payable {  
        require(msg.value == fee);
        beneficiary.transfer(msg.value);
        emit Retained(msg.sender, request);
    }
    
     
    
    function updateFee(uint256 newFee) public onlyAdmin {  
        fee = newFee;
    }
    
    function assignBeneficiary(address payable newBeneficiary) public onlyAdmin {  
        beneficiary = newBeneficiary;
    }
}