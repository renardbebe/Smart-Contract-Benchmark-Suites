 

pragma solidity ^0.4.11;

contract Ownable {
    address public owner;
    
    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }
    
    modifier protected() {
        if(msg.sender != address(this)) {
            throw;
        }
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) {
            throw;
        }
        owner = newOwner;
    }
}

contract InvestmentWithDividend is Ownable {

    event Transfer(
        uint amount,
        bytes32 message,
        address target,
        address currentOwner
    );
    
    struct Investor {
        uint investment;
        uint lastDividend;
    }

    mapping(address => Investor) investors;

    uint public minInvestment;
    uint public sumInvested;
    uint public sumDividend;
    
    function InvestmentWithDividend() public { 
        minInvestment = 1 ether;
    }
    
    function loggedTransfer(uint amount, bytes32 message, address target, address currentOwner) protected {
        if(! target.call.value(amount)() ) {
            throw;
        }
        Transfer(amount, message, target, currentOwner);
    }
    
    function invest() public payable {
        if (msg.value >= minInvestment) {
            sumInvested += msg.value;
            investors[msg.sender].investment += msg.value;
             
            investors[msg.sender].lastDividend = sumDividend;
        }
    }

    function divest(uint amount) public {
        if (investors[msg.sender].investment == 0 || amount == 0) {
            throw;
        }
         
        investors[msg.sender].investment -= amount;
        sumInvested -= amount; 
        this.loggedTransfer(amount, "", msg.sender, owner);
    }

    function calculateDividend() constant public returns(uint dividend) {
        uint lastDividend = investors[msg.sender].lastDividend;
        if (sumDividend > lastDividend) {
            throw;
        }
         
        dividend = (sumDividend - lastDividend) * investors[msg.sender].investment / sumInvested;
    }
    
    function getInvestment() constant public returns(uint investment) {
        investment = investors[msg.sender].investment;
    }
    
    function payDividend() public {
        uint dividend = calculateDividend();
        if (dividend == 0) {
            throw;
        }
        investors[msg.sender].lastDividend = sumDividend;
        this.loggedTransfer(dividend, "Dividend payment", msg.sender, owner);
    }
    
    function distributeDividends() public payable onlyOwner {
        sumDividend += msg.value;
    }
    
    function doTransfer(address target, uint amount) public onlyOwner {
        this.loggedTransfer(amount, "Owner transfer", target, owner);
    }
    
    function setMinInvestment(uint amount) public onlyOwner {
        minInvestment = amount;
    }
    
    function destroy() public onlyOwner {
        selfdestruct(msg.sender);
    }
    
    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    function withdraw(uint256 amount) public onlyOwner {
        owner.transfer(amount);
    }
    
    function () public payable {}
}