 

pragma solidity ^0.4.24;

contract TokenRelay {
    using SafeMath for uint256;
    
    uint256 constant Ilen = 5;
    
    struct Interval {
        uint256 start;
        address contractAddr;
        uint256[Ilen] tick;
        uint256[Ilen] fee;  
    }
    
    mapping (address => uint256) private balances;
    mapping (address => Interval) private position;
    address private feeOwner;
    
    event Deposit(address _tokenAddr, address _beneficary, uint256 _amount);
    event Redeem(address _addr, uint256 _amount, uint256 _fee);
    
    constructor() public {
        feeOwner = msg.sender;
    }
    
    function tokenStorage(
        address _tokenAddr,
        address _beneficary,
        uint256 _amount,
        uint256[Ilen] _tick,
        uint256[Ilen] _fee
    ) public {
        require(balances[_beneficary] <= 0, "Require balance of this address is zero.");
        balances[_beneficary] = 0;
        ERC20Token erc20 = ERC20Token(_tokenAddr);
        if (erc20.transferFrom(msg.sender, address(this), _amount) == true) {
            balances[_beneficary] = _amount;
            position[_beneficary] = Interval(block.timestamp, _tokenAddr, _tick, _fee);
        }
        emit Deposit(_tokenAddr, _beneficary, _amount);
    }
    
    function redeem(uint256 _amount) public {
        require(_amount > 0, "You should give a number more than zero!");
        require(balances[msg.sender] > _amount, "You don't have enough balance to redeem!");
        
        uint256 feeRatio = getRedeemFee(msg.sender);
        uint256 total = _amount;
        balances[msg.sender] =  balances[msg.sender].sub(_amount);
        uint256 fee = total.mul(feeRatio).div(100);
        uint256 left = total.sub(fee);
        
        ERC20Token erc20 = ERC20Token(position[msg.sender].contractAddr);
        if (erc20.transfer(msg.sender, left) == true) {
            balances[feeOwner].add(fee);
        }
        emit Redeem(msg.sender, left, fee);
    }
    
     
    function getRedeemFee(address _addr) internal view returns(uint256) {
        for (uint i = 0; i < Ilen; i++) {
            if (block.timestamp <= position[_addr].tick[i]) {
                return position[_addr].fee[i];
            }
        }
        return position[_addr].fee[4];
    }

     
    function balanceOf(address _addr) public view returns(uint256) {
        return balances[_addr];
    }
    
    function redeemFee(address _addr) public view returns(uint256 feeInRatio) {
        return getRedeemFee(_addr);
    }
    
    function redeemInterval(address _addr) public view returns(uint256 start, uint256[5] tick, uint256[5] fee) {
        start = position[_addr].start;
        tick = position[_addr].tick;
        fee = position[_addr].fee;
    }
    
}

interface ERC20Token {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function transfer(address _to, uint256 _value) external returns (bool success);
}


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}