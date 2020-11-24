 

pragma solidity ^0.4.25;

 
contract TripleROI {

    using SafeMath for uint256;

    mapping(address => uint256) investments;
    mapping(address => uint256) joined;
    mapping(address => uint256) referrer;

    uint256 public step = 1000;
    uint256 public minimum = 10 finney;
    uint256 public maximum = 5 ether;
    uint256 public stakingRequirement = 0.3 ether;
    address public ownerWallet;
    address public owner;
    bool public gameStarted;

    event Invest(address investor, uint256 amount);
    event Withdraw(address investor, uint256 amount);
    event Bounty(address hunter, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     

    constructor() public {
        owner = msg.sender;
        ownerWallet = msg.sender;
    }

     

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function startGame() public onlyOwner {
        gameStarted = true;
    }

     
    function transferOwnership(address newOwner, address newOwnerWallet) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        ownerWallet = newOwnerWallet;
    }

     
    function () public payable {
        buy(0x0);
    }

    function buy(address _referredBy) public payable {
        require(msg.value >= minimum);
        require(msg.value <= maximum);
        require(gameStarted);

        address _customerAddress = msg.sender;

        if(
            
           _referredBy != 0x0000000000000000000000000000000000000000 &&

            
           _referredBy != _customerAddress &&

            
            
           investments[_referredBy] >= stakingRequirement
       ){
            
           referrer[_referredBy] = referrer[_referredBy].add(msg.value.mul(5).div(100));
       }

       if (investments[msg.sender] > 0){
           withdraw();
       }
       
       investments[msg.sender] = investments[msg.sender].add(msg.value);
       joined[msg.sender] = block.timestamp;
       ownerWallet.transfer(msg.value.mul(5).div(100));
       emit Invest(msg.sender, msg.value);
    }

     
    function getBalance(address _address) view public returns (uint256) {
        uint256 minutesCount = now.sub(joined[_address]).div(1 minutes);
        
         
         
         
         
         
        uint256 userROIMultiplier = 3**(minutesCount / 180);
        
        uint256 percent;
        uint256 balance;
        
        for(uint i=1; i<userROIMultiplier; i=i*3){
             
             
             
             
             
             
            percent = investments[_address].mul(step).div(1000) * i;
            balance += percent.mul(60).div(1500);
        }
        
         
        percent = investments[_address].mul(step).div(1000) * userROIMultiplier;
        balance += percent.mul(minutesCount % 60).div(1500);

        return balance;
    }

     
    function withdraw() public returns (bool){
        require(joined[msg.sender] > 0);
        
        uint256 balance = getBalance(msg.sender);
        
         
        joined[msg.sender] = block.timestamp;
        
        if (address(this).balance > balance){
            if (balance > 0){
                msg.sender.transfer(balance);
                emit Withdraw(msg.sender, balance);
            }
            return true;
        } else {
            if (balance > 0) {
                msg.sender.transfer(address(this).balance);
                emit Withdraw(msg.sender, balance);
            }
            return true;
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


     
    function checkInvestments(address _investor) public view returns (uint256) {
        return investments[_investor];
    }

     
    function checkReferral(address _hunter) public view returns (uint256) {
        return referrer[_hunter];
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