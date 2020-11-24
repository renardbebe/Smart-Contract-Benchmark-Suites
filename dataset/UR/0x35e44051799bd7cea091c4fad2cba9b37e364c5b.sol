 

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

contract myPreICO is Ownable {
    uint public ETHRaised;
    uint public soft_cap = 1 ether;  
    uint public hard_cap = 10 ether; 
    address public owner = 0x0;
    uint public end_date;
    address[] public holders;
    mapping (address => uint) public holder_balance;
    
    function myICO() public {
        owner = msg.sender;
        end_date = now + 90 days;  
    }

    function sendFunds(address _addr) public onlyOwner {
        require (ETHRaised >= soft_cap);  
        _addr.transfer(address(this).balance);
    }

    function withdraw() public {
        uint amount;
        require(now > end_date); 
        require(ETHRaised < hard_cap); 
        amount = holder_balance[msg.sender];
        holder_balance[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
    
    function () public payable {
        require(msg.value > 0);
        holders.push(msg.sender);
        holder_balance[msg.sender] += msg.value;
        ETHRaised += msg.value;
    }

    function getFunds() public view returns (uint){
        return address(this).balance;
    }
}