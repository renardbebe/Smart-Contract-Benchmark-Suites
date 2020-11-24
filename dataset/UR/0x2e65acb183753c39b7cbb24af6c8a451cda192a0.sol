 

pragma solidity ^0.4.24;

 

contract Infinite3{
    
    using SafeMath for uint256;

    mapping(address => uint256) investments;
    mapping(address => uint256) joined;
    mapping(address => uint256) withdrawals;
    mapping(address => uint256) referrer;

    uint256 public minimum = 10000000000000000;
    uint256 public step = 3;
    address public ownerWallet;
    address public owner;
    address public bountyManager;
    address promoter = 0xf8EeAe7abe051A0B7a4ec5758af411F870A8Add3;

    event Invest(address investor, uint256 amount);
    event Withdraw(address investor, uint256 amount);
    event Bounty(address hunter, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
     
     
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

     
    function transferOwnership(address newOwner, address newOwnerWallet) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        ownerWallet = newOwnerWallet;
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
        ownerWallet.transfer(msg.value.div(1000).mul(5));
        promoter.transfer(msg.value.div(1000).mul(5));
        emit Invest(msg.sender, msg.value);
    }

     
    function getBalance(address _address) view public returns (uint256) {
        uint256 minutesCount = now.sub(joined[_address]).div(1 minutes);
        uint256 percent = investments[_address].mul(step).div(100);
        uint256 different = percent.mul(minutesCount).div(1440);
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
    
     
    function bounty() public {
        uint256 refBalance = checkReferral(msg.sender);
        if(refBalance >= minimum) {
             if (address(this).balance > refBalance) {
                referrer[msg.sender] = 0;
                msg.sender.transfer(refBalance);
                emit Bounty(msg.sender, refBalance);
             }
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

     
    function checkReferral(address _hunter) public view returns (uint256) {
        return referrer[_hunter];
    }
    
     
    function updateReferral(address _hunter, uint256 _amount) onlyBountyManager public {
        referrer[_hunter] = referrer[_hunter].add(_amount);
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