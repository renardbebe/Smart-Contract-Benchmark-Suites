 

pragma solidity ^0.4.24;

contract Ownable{}
contract CREDITS is Ownable {
    mapping (address => uint256) internal balanceOf;
    function transfer (address _to, uint256 _value) public returns (bool);
    
}

contract SwapContractDateumtoPDATA {
     
    address public owner;
    CREDITS public company_token;

    address public PartnerAccount;
    uint public originalBalance;
    uint public currentBalance;
    uint public alreadyTransfered;
    uint public startDateOfPayments;
    uint public endDateOfPayments;
    uint public periodOfOnePayments;
    uint public limitPerPeriod;
    uint public daysOfPayments;

     
    modifier onlyOwner
    {
        require(owner == msg.sender);
        _;
    }
  
  
     
    event Transfer(address indexed to, uint indexed value);
    event OwnerChanged(address indexed owner);


     
    constructor (CREDITS _company_token) public {
        owner = msg.sender;
        PartnerAccount = 0x9fb9Ec557A13779C69cfA3A6CA297299Cb55E992;
        company_token = _company_token;
         
         
         
         
         
         
         
         
    }


     
    function()
        public
        payable
    {
        revert();
    }




    function setOwner(address _owner) 
        public 
        onlyOwner 
    {
        require(_owner != 0);
     
        owner = _owner;
        emit OwnerChanged(owner);
    }
  
    function sendCurrentPayment() public {
        if (now > startDateOfPayments) {
             
             
             
            company_token.transfer(PartnerAccount, 1);
            
	    }
    }
}