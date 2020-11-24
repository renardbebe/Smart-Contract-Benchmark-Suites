 

pragma solidity 0.4.25;

 

 
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

 

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
library SafeERC20 {

  using SafeMath for uint256;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
     
     
     
    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance));
  }
}

 

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 

 
contract Vesting is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

     
    IERC20 private _token;

     
    struct Info {
        bool    known;           
        uint256 totalAmount;     
        uint256 receivedAmount;  
        uint256 startTime;       
        uint256 releaseTime;     
    }

     
    mapping(address => Info) private _info;

    constructor(
        IERC20 token
    )
        public
    {
        _token = token;
    }
    
     
    function addBeneficiary(
        address beneficiary,
        uint256 startTime,
        uint256 releaseTime,
        uint256 amount
    )
        external
        onlyOwner
    {
        Info storage info = _info[beneficiary];
        require(!info.known, "This address is already known to the contract.");
        require(releaseTime > startTime, "Release time must be later than the start time.");
        require(releaseTime > block.timestamp, "End of vesting period must be somewhere in the future.");

        info.startTime = startTime;  
        info.totalAmount = amount;  
        info.releaseTime = releaseTime;  
        info.known = true;  
    }

     
    function removeBeneficiary(address beneficiary) external onlyOwner {
        Info storage info = _info[beneficiary];
        require(info.known, "The address you are trying to remove is unknown to the contract");

        _release(beneficiary);  
        info.known = false;
        info.totalAmount = 0;
        info.receivedAmount = 0;
        info.startTime = 0;
        info.releaseTime = 0;
    }

     
    function withdraw(uint256 amount) external onlyOwner {
        _token.safeTransfer(owner(), amount);
    }

     
    function release() external {
        require(_info[msg.sender].known, "You are not eligible to receive tokens from this contract.");
        _release(msg.sender);
    }

     
    function check() external view returns (uint256, uint256, uint256, uint256) {
        return (
            _info[msg.sender].totalAmount, 
            _info[msg.sender].receivedAmount,
            _info[msg.sender].startTime, 
            _info[msg.sender].releaseTime
        );
    }

     
    function _release(address beneficiary) internal {
        Info storage info = _info[beneficiary];
        if (block.timestamp >= info.releaseTime) {
            uint256 remainingTokens = info.totalAmount.sub(info.receivedAmount);
            require(remainingTokens > 0, "No tokens left to take out.");

             
            info.receivedAmount = info.totalAmount;
            _token.safeTransfer(beneficiary, remainingTokens);
        } else if (block.timestamp > info.startTime) {
             
            uint256 diff = info.releaseTime.sub(info.startTime);
            uint256 tokensPerTick = info.totalAmount.div(diff);
            uint256 ticks = block.timestamp.sub(info.startTime);
            uint256 tokens = tokensPerTick.mul(ticks);
            uint256 receivableTokens = tokens.sub(info.receivedAmount);
            require(receivableTokens > 0, "No tokens to take out right now.");

             
            info.receivedAmount = info.receivedAmount.add(receivableTokens);
            _token.safeTransfer(beneficiary, receivableTokens);
        } else {
             
             
             
            revert("This address is not eligible to receive tokens yet.");
        }
    }
}