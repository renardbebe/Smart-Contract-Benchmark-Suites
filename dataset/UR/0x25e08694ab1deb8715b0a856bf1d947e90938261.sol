 

 
pragma solidity ^0.4.24;


 
library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
contract Halva_Token {

     
    using SafeMath for uint;

     
    address owner;

     
    mapping (address => uint) deposit;
     
    mapping (address => uint) withdrawn;
     
    mapping (address => uint) lastTimeWithdraw;

     
    function transferOwnership(address _newOwner) external {
        require(msg.sender == owner);
        require(_newOwner != address(0));
        owner = _newOwner;
    }

     
    function getInfo() public view returns(uint Deposit, uint Withdrawn, uint AmountToWithdraw) {
         
        Deposit = deposit[msg.sender];
         
        Withdrawn = withdrawn[msg.sender];
         
         
        AmountToWithdraw = (block.timestamp.sub(lastTimeWithdraw[msg.sender]).sub((block.timestamp.sub(lastTimeWithdraw[msg.sender])).mod(1 days))).mul(deposit[msg.sender].mul(3).div(100)).div(1 days);
    }

     
    constructor() public {
        owner = msg.sender;
    }

     
    function() external payable {
        invest();
    }

     
    function invest() public payable {
         
        require(msg.value > 10000000000000000);
         
        owner.transfer(msg.value.div(5));
         
        if (deposit[msg.sender] > 0) {
             
             
            uint amountToWithdraw = (block.timestamp.sub(lastTimeWithdraw[msg.sender]).sub((block.timestamp.sub(lastTimeWithdraw[msg.sender])).mod(1 days))).mul(deposit[msg.sender].mul(3).div(100)).div(1 days);
             
            if (amountToWithdraw != 0) {
                 
                withdrawn[msg.sender] = withdrawn[msg.sender].add(amountToWithdraw);
                 
                msg.sender.transfer(amountToWithdraw);
            }
             
            lastTimeWithdraw[msg.sender] = block.timestamp;
             
            deposit[msg.sender] = deposit[msg.sender].add(msg.value);
             
            return;
        }
         
         
        lastTimeWithdraw[msg.sender] = block.timestamp;
         
        deposit[msg.sender] = (msg.value);
    }

     
    function withdraw() public {
         
         
        uint amountToWithdraw = (block.timestamp.sub(lastTimeWithdraw[msg.sender]).sub((block.timestamp.sub(lastTimeWithdraw[msg.sender])).mod(1 days))).mul(deposit[msg.sender].mul(3).div(100)).div(1 days);
         
        if (amountToWithdraw == 0) {
            revert();
        }
         
        withdrawn[msg.sender] = withdrawn[msg.sender].add(amountToWithdraw);
         
         
        lastTimeWithdraw[msg.sender] = block.timestamp.sub((block.timestamp.sub(lastTimeWithdraw[msg.sender])).mod(1 days));
         
        msg.sender.transfer(amountToWithdraw);
    }
}