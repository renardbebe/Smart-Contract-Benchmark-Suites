 

pragma solidity ^0.4.25;
 
 
contract EthLong{
   
    using SafeMath for uint256;
 
    mapping(address => uint256) investments;
    mapping(address => uint256) joined;
    mapping(address => uint256) withdrawals;
 
    uint256 public minimum = 10000000000000000;
    uint256 public step = 33;
    address public ownerWallet;
    address public owner;
    address public bountyManager;
    address promoter = 0xA4410DF42dFFa99053B4159696757da2B757A29d;
 
    event Invest(address investor, uint256 amount);
    event Withdraw(address investor, uint256 amount);
    event Bounty(address hunter, uint256 amount);
   
     
     
    constructor(address _bountyManager) public {
        owner = msg.sender;
        ownerWallet = msg.sender;
        bountyManager = _bountyManager;
    }
 
     
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
 
    modifier onlyBountyManager() {
        require(msg.sender == bountyManager);
        _;
    }
 
     
 
     
    function () external payable {
        require(msg.value >= minimum);
        if (investments[msg.sender] > 0){
            if (withdraw()){
                withdrawals[msg.sender] = 0;
            }
        }
        investments[msg.sender] = investments[msg.sender].add(msg.value);
        joined[msg.sender] = block.timestamp;
        ownerWallet.transfer(msg.value.div(100).mul(5));
        promoter.transfer(msg.value.div(100).mul(5));
        emit Invest(msg.sender, msg.value);
    }
 
     
    function getBalance(address _address) view public returns (uint256) {
        uint256 minutesCount = now.sub(joined[_address]).div(1 minutes);
        uint256 percent = investments[_address].mul(step).div(100);
        uint256 different = percent.mul(minutesCount).div(72000);
        uint256 balance = different.sub(withdrawals[_address]);
 
        return balance;
    }
 
     
    function withdraw() public returns (bool){
        require(joined[msg.sender] > 0);
        uint256 balance = getBalance(msg.sender);
        if (address(this).balance > balance){
            if (balance > 0){
                withdrawals[msg.sender] = withdrawals[msg.sender].add(balance);
                msg.sender.transfer(balance);
                emit Withdraw(msg.sender, balance);
            }
            return true;
        } else {
            return false;
        }
    }
   
 
     
    function checkBalance() public view returns (uint256) {
        return getBalance(msg.sender);
    }
 
     
    function checkWithdrawals(address _investor) public view returns (uint256) {
        return withdrawals[_investor];
    }
 
     
    function checkInvestments(address _investor) public view returns (uint256) {
        return investments[_investor];
    }
       
}
 
 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}