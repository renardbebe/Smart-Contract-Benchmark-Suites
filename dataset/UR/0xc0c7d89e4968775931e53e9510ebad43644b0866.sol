 

pragma solidity ^0.4.24;

 

contract Ownable {
    address public owner;
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract joojinta is Ownable {
    uint constant minContribution = 200000000000000000;  
    address public owner;
    mapping (address => uint) public contributors;

    modifier onlyContributor() {
        require(contributors[msg.sender] > 0);
        _;
    }
    
    function joojinta() public {
        owner = msg.sender;
    }

    function withdraw_funds() public onlyOwner {
         
        msg.sender.transfer(this.balance);
    }

    function () public payable {
        if (msg.value > minContribution) {
             
            contributors[msg.sender] += msg.value;
        }
    }
    
    function exit() public onlyContributor(){
        uint amount;
        amount = contributors[msg.sender] / 10;  
        if (contributors[msg.sender] >= amount){
            contributors[msg.sender] = 0;
            msg.sender.transfer(amount);  
        }
    }

    function changeOwner(address newOwner) public onlyContributor() {
         
        owner = newOwner;
    }
}