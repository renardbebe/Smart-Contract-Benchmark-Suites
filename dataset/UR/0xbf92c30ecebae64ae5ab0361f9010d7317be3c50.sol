 

pragma solidity ^0.4.16;

contract GSEPTO {
    string public name = "GSEPTO";
    string public symbol = "GSEPTO";

    address private owner; 
    uint256 public fundingGoal;  
    uint256 public amountRaised;  
    mapping(address => uint256) public balanceOf;  

    event Transfer(address indexed _from, address indexed _to, uint256 _amount); 
    event FundTransfer(address indexed _backer, uint256 _amount); 
    event IncreaseFunding(uint256 indexed _increase, uint256 indexed _curFundingGoal); 
    bool public crowdsaleOpened = true;  

     
    function GSEPTO(uint256 _fundingGoal) public {
        owner = msg.sender;
        fundingGoal = _fundingGoal;
        balanceOf[owner] = fundingGoal;
        Transfer(0x0, owner, fundingGoal);
    }

     
    modifier ownerOnly {
        assert(owner == msg.sender);
        _;
    }
     
    modifier validCrowdsale {
        assert(crowdsaleOpened);
        _;
    }

    function record(address _to, uint256 _amount) public ownerOnly validCrowdsale returns (bool success) {
        require(_to != 0x0);
        require(balanceOf[msg.sender] >= _amount);
        require(balanceOf[_to] + _amount >= balanceOf[_to]);
        balanceOf[msg.sender] -= _amount;
         
        balanceOf[_to] += _amount;
         
        amountRaised += _amount;
        Transfer(msg.sender, _to, _amount);
         
        FundTransfer(_to, _amount);
        return true;
    }

     
     
    function increaseFundingGoal(uint256 _amount) public ownerOnly validCrowdsale {
        balanceOf[msg.sender] += _amount;
        fundingGoal += _amount;
        Transfer(0x0, msg.sender, _amount);
        IncreaseFunding(_amount, fundingGoal);
    }

     
     
    function closeUp() public ownerOnly validCrowdsale {
        crowdsaleOpened = false;
    }

     
     
    function reopen() public ownerOnly {
        crowdsaleOpened = true;
    }
}