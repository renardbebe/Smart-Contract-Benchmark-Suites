 

pragma solidity ^0.4.18;
 

contract GiftCard2017{
    address owner;
    mapping (address => uint256) public authorizations;
    
     
    function GiftCard2017() public {
        owner = msg.sender;
    }
    
     
    function () public payable {                                
        uint256 _redemption = authorizations[msg.sender];       
        require (_redemption > 0);
        authorizations[msg.sender] = 0;                         
        msg.sender.transfer(_redemption * 1e15 + msg.value);    
    }
    
     
    function deposit() public payable OwnerOnly {
    }
    
     
    function withdraw(uint256 _amount) public OwnerOnly {
        owner.transfer(_amount);
    }

     
    function authorize(address _addr, uint256 _amount_mEth) public OwnerOnly {
        require (this.balance >= _amount_mEth);
        authorizations[_addr] = _amount_mEth;
    }
    
     
    modifier OwnerOnly () {
        require (msg.sender == owner);
        _;
    }
}