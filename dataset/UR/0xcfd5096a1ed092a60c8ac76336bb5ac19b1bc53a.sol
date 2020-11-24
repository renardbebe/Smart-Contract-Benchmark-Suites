 

pragma solidity ^0.5.8;

interface Token {
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function transfer(address _to, uint256 _amount) external returns (bool);
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