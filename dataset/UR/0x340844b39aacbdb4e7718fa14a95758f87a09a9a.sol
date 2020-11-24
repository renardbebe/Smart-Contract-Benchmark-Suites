 

 
pragma solidity ^0.4.20;

contract Ownable {
    address Owner = msg.sender;
    modifier onlyOwner() { if (Owner == msg.sender) { _; } }
    function transferOwner(address _owner) public onlyOwner {
        address previousOwner;
        if (address(this).balance == 0) {
            previousOwner = Owner;
            Owner = _owner;
        }
    }
}

contract DepositCapsule is Ownable {
    address public Owner;
    mapping (address=>uint) public deposits;
    uint public openDate;
    
    function init(uint openOnDate) public {
        Owner = msg.sender;
        openDate = openOnDate;
    }
    
    function() public payable {  }
    
    function deposit() public payable {
        if (msg.value >= 0.5 ether) {
            deposits[msg.sender] += msg.value;
        }
    }

    function withdraw(uint amount) public onlyOwner {
        if (now >= openDate) {
            uint max = deposits[msg.sender];
            if (amount <= max && max > 0) {
                if (!msg.sender.send(amount))
                    revert();
            }
        }
    }
}