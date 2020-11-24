 

pragma solidity 0.5.4;


 
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
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
 
library SafeERC20 {
    
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}
 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
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
contract TokenVesting is Ownable{
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    struct VestedToken{
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 releasedToken;
        uint256 totalToken;
        bool revoked;
    }
    
    mapping (address => VestedToken) public vestedUser; 
    
     
    uint256 private _cliff = 2592000;  
    uint256 private _duration = 93312000;  
    bool private _revoked = false;
    
    IERC20 public LCXToken;
    
    event TokenReleased(address indexed account, uint256 amount);
    event VestingRevoked(address indexed account);
    
      
    modifier onlyLCXTokenAndOwner() {
        require(msg.sender==owner() || msg.sender == address(LCXToken));
        _;
    }
    
     
     
    function setTokenAddress(IERC20 token) public onlyOwner returns(bool){
        LCXToken = token;
        return true;
    }
    
     
     
     function setDefaultVesting(address account, uint256 amount) public onlyLCXTokenAndOwner returns(bool){
         _setDefaultVesting(account, amount);
         return true;
     }
     
      
      
     function _setDefaultVesting(address account, uint256 amount)  internal {
         require(account!=address(0));
         VestedToken storage vested = vestedUser[account];
         vested.cliff = _cliff;
         vested.start = block.timestamp;
         vested.duration = _duration;
         vested.totalToken = amount;
         vested.releasedToken = 0;
         vested.revoked = _revoked;
     }
     
     
      
     
     function setVesting(address account, uint256 amount, uint256 cliff, uint256 duration, uint256 startAt ) public onlyLCXTokenAndOwner  returns(bool){
         _setVesting(account, amount, cliff, duration, startAt);
         return true;
     }
     
      
     
     function _setVesting(address account, uint256 amount, uint256 cliff, uint256 duration, uint256 startAt) internal {
         
         require(account!=address(0));
         require(cliff<=duration);
         VestedToken storage vested = vestedUser[account];
         vested.cliff = cliff;
         vested.start = startAt;
         vested.duration = duration;
         vested.totalToken = amount;
         vested.releasedToken = 0;
         vested.revoked = false;
     }

     
     
    function releaseMyToken() public returns(bool) {
        releaseToken(msg.sender);
        return true;
    }
    
      
    function releaseToken(address account) public {
       require(account != address(0));
       VestedToken storage vested = vestedUser[account];
       uint256 unreleasedToken = _releasableAmount(account);   
       require(unreleasedToken>0);
       vested.releasedToken = vested.releasedToken.add(unreleasedToken);
       LCXToken.safeTransfer(account,unreleasedToken);
       emit TokenReleased(account, unreleasedToken);
    }
    
     
    function _releasableAmount(address account) internal view returns (uint256) {
        return _vestedAmount(account).sub(vestedUser[account].releasedToken);
    }

  
     
    function _vestedAmount(address account) internal view returns (uint256) {
        VestedToken storage vested = vestedUser[account];
        uint256 totalToken = vested.totalToken;
        if(block.timestamp <  vested.start.add(vested.cliff)){
            return 0;
        }else if(block.timestamp >= vested.start.add(vested.duration) || vested.revoked){
            return totalToken;
        }else{
            uint256 numberOfPeriods = (block.timestamp.sub(vested.start)).div(vested.cliff);
            return totalToken.mul(numberOfPeriods.mul(vested.cliff)).div(vested.duration);
        }
    }
    
     
    function revoke(address account) public onlyOwner {
        VestedToken storage vested = vestedUser[account];
        require(!vested.revoked);
        uint256 balance = vested.totalToken;
        uint256 unreleased = _releasableAmount(account);
        uint256 refund = balance.sub(unreleased);
        vested.revoked = true;
        vested.totalToken = unreleased;
        LCXToken.safeTransfer(owner(), refund);
        emit VestingRevoked(account);
    }
    
    
    
    
}