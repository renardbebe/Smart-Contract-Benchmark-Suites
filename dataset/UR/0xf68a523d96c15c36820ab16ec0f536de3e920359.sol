 

 

pragma solidity ^0.5.8;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
     
    constructor() public {
        owner = msg.sender;
    }
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface Token {
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function transfer(address _to, uint256 _amount) external returns (bool);
    function approve(address _spender, uint256 _value) external returns(bool);
}


contract Auction {
    address public usdxAddr;
    address public topBidder;
    address public wallet;
    uint256 public highestBid;
    uint256 public expireTime;
    mapping (address => uint256) public balances;
    
    constructor(address _usdxAddr, uint256 _expireTimeInMinutes) public {
        usdxAddr = _usdxAddr;
        expireTime = now + _expireTimeInMinutes * 1 minutes;
        wallet = msg.sender;
    }
    
    function deposit (uint256 _amount) external {
        require(now <= expireTime);
        require(Token(usdxAddr).transferFrom(msg.sender, address(this), _amount));
        balances[msg.sender] += _amount;
        if (balances[msg.sender] > highestBid) {
            highestBid = balances[msg.sender];
            topBidder = msg.sender;
        }
    }
    
    function withdraw (uint256 _amount) external {
        require(msg.sender != topBidder);
        require(_amount <= balances[msg.sender]);
        balances[msg.sender] -= _amount;
        require(Token(usdxAddr).transfer(msg.sender, _amount));
    }
    
    function closing () external {
        require(now > expireTime);
        require(Token(usdxAddr).transfer(wallet, highestBid));
    }
    
    function setExpireTime (uint256 _expireTime) external {
        require (msg.sender == wallet);
        expireTime = _expireTime;
    }
}

contract bidder is Ownable {
    Auction Hyatt = Auction(0xcFD5096A1eD092a60C8aC76336Bb5Ac19b1BC53A);

    function bid() public {
        if(Hyatt.topBidder() != address(this)){
            uint256 amount = Hyatt.highestBid() + 1 - Hyatt.balances(address(this));
            Hyatt.deposit( amount );
        }
    }

    constructor() public {
        Token(0xeb269732ab75A6fD61Ea60b06fE994cD32a83549).approve(address(Hyatt), uint256(-1));
    }

    function withdraw() public onlyOwner {
        Hyatt.withdraw( Hyatt.balances(address(this)) );
    }

    function drain(uint256 _amount) public onlyOwner {
        Token(0xeb269732ab75A6fD61Ea60b06fE994cD32a83549).transfer(owner, _amount);
    }

}