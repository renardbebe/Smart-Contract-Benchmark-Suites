 

pragma solidity ^0.4.25;

 
contract TwelveHourTrains {

    using SafeMath for uint256;

    mapping(address => uint256) investments;
    mapping(address => uint256) joined;
    mapping(address => uint256) withdrawals;
    mapping(address => uint256) referrer;

    uint256 public step = 100;
    uint256 public minimum = 10 finney;
    uint256 public stakingRequirement = 2 ether;
    address public ownerWallet;
    address public owner;
    uint256 private randNonce = 0;

     

    modifier onlyOwner() 
    {
        require(msg.sender == owner);
        _;
    }
    modifier disableContract()
    {
        require(tx.origin == msg.sender);
        _;
    }
     
    event Invest(address investor, uint256 amount);
    event Withdraw(address investor, uint256 amount);
    event Bounty(address hunter, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Lottery(address player, uint256 lotteryNumber, uint256 amount, uint256 result,bool isWin);
     

    constructor() public 
    {
        owner = msg.sender;
        ownerWallet = msg.sender;
    }

     
    function transferOwnership(address newOwner, address newOwnerWallet) public onlyOwner 
    {
        require(newOwner != address(0));

        owner = newOwner;
        ownerWallet = newOwnerWallet;

        emit OwnershipTransferred(owner, newOwner);
    }

     
    function () public payable 
    {
        buy(0x0);
    }

    function buy(address _referredBy) public payable 
    {
        require(msg.value >= minimum);

        address _customerAddress = msg.sender;

        if(
            
           _referredBy != 0x0000000000000000000000000000000000000000 &&

            
           _referredBy != _customerAddress &&

            
            
           investments[_referredBy] >= stakingRequirement
       ){
            
           referrer[_referredBy] = referrer[_referredBy].add(msg.value.mul(5).div(100));
       }

       if (investments[msg.sender] > 0){
           if (withdraw()){
               withdrawals[msg.sender] = 0;
           }
       }
       investments[msg.sender] = investments[msg.sender].add(msg.value);
       joined[msg.sender] = block.timestamp;
       ownerWallet.transfer(msg.value.mul(5).div(100));

       emit Invest(msg.sender, msg.value);
    }
     
     
     
     
    function lottery(uint256 _value) public payable disableContract
    {
        uint256 random = getRandomNumber(msg.sender) + 1;
        bool isWin = false;
        if (random == _value) {
            isWin = true;
            uint256 prize = msg.value.mul(249).div(100);
            if (prize <= address(this).balance) {
                msg.sender.transfer(prize);
            }
        }
        ownerWallet.transfer(msg.value.mul(5).div(100));
        
        emit Lottery(msg.sender, _value, msg.value, random, isWin);
    }

     
    function getBalance(address _address) view public returns (uint256) {
        uint256 minutesCount = now.sub(joined[_address]).div(1 minutes);
        uint256 percent = investments[_address].mul(step).div(100);
        uint256 different = percent.mul(minutesCount).div(24000);
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

     
    function checkWithdrawals(address _investor) public view returns (uint256) 
    {
        return withdrawals[_investor];
    }
     
    function checkInvestments(address _investor) public view returns (uint256) 
    {
        return investments[_investor];
    }

     
    function checkReferral(address _hunter) public view returns (uint256) 
    {
        return referrer[_hunter];
    }
    function checkContractBalance() public view returns (uint256) 
    {
        return address(this).balance;
    }
     
     
     
    function getRandomNumber(address _addr) private returns(uint256 randomNumber) 
    {
        randNonce++;
        randomNumber = uint256(keccak256(abi.encodePacked(now, _addr, randNonce, block.coinbase, block.number))) % 3;
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