 

pragma solidity ^0.5.2;
 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
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

 
 
 

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b,"Invalid values");
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0,"Invalid values");
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a,"Invalid values");
        uint256 c = a - b;
        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a,"Invalid values");
        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0,"Invalid values");
        return a % b;
    }
}

contract SynchroBitcoin is IERC20 {
    using SafeMath for uint256;
    address private _owner;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    bool public _lockStatus = false;
    bool private isValue;
    uint256 public airdropcount = 0;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    mapping (address => uint256) private time;

    mapping (address => uint256) private _lockedAmount;

    constructor (string memory name, string memory symbol, uint8 decimals, uint256 totalSupply, address owner) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _totalSupply = totalSupply*(10**uint256(decimals));
        _balances[owner] = _totalSupply;
        _owner = owner;
    }

     

     
    function getowner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(),"You are not authenticate to make this transfer");
        _;
    }

     
    function isOwner() internal view returns (bool) {
        return msg.sender == _owner;
    }

     
    function transferOwnership(address newOwner) public onlyOwner returns (bool){
        _owner = newOwner;
        return true;
    }

     

     
    function setAllTransfersLockStatus(bool RunningStatusLock) external onlyOwner returns (bool)
    {
        _lockStatus = RunningStatusLock;
        return true;
    }

     
    function getAllTransfersLockStatus() public view returns (bool)
    {
        return _lockStatus;
    }

     
     function addLockingTime(address lockingAddress,uint8 lockingTime, uint256 amount) internal returns (bool){
        time[lockingAddress] = now + (lockingTime * 1 days);
        _lockedAmount[lockingAddress] = amount;
        return true;
     }

      
      function checkLockingTimeByAddress(address _address) public view returns(uint256){
         return time[_address];
      }
       
       function getLockingStatus(address userAddress) public view returns(bool){
           if (now < time[userAddress]){
               return true;
           }
           else{
               return false;
           }
       }

     
    function decreaseLockingTimeByAddress(address _affectiveAddress, uint _decreasedTime) external onlyOwner returns(bool){
          require(_decreasedTime > 0 && time[_affectiveAddress] > now, "Please check address status or Incorrect input");
          time[_affectiveAddress] = time[_affectiveAddress] - (_decreasedTime * 1 days);
          return true;
      }

       
    function increaseLockingTimeByAddress(address _affectiveAddress, uint _increasedTime) external onlyOwner returns(bool){
          require(_increasedTime > 0 && time[_affectiveAddress] > now, "Please check address status or Incorrect input");
          time[_affectiveAddress] = time[_affectiveAddress] + (_increasedTime * 1 days);
          return true;
      }

     
    modifier AllTransfersLockStatus()
    {
        require(_lockStatus == false,"All transactions are locked for this contract");
        _;
    }

     
     modifier checkLocking(address _address,uint256 requestedAmount){
         if(now < time[_address]){
         require(!( _balances[_address] - _lockedAmount[_address] < requestedAmount), "Insufficient unlocked balance");
         }
        else{
            require(1 == 1,"Transfer can not be processed");
        }
        _;
     }

     

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     

     
    function transfer(address to, uint256 value) public AllTransfersLockStatus checkLocking(msg.sender,value) returns (bool) {
            _transfer(msg.sender, to, value);
            return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public AllTransfersLockStatus checkLocking(from,value) returns (bool) {
             _transfer(from, to, value);
             _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
             return true;
    }

     
    function transferByOwner(address to, uint256 value, uint8 lockingTime) public AllTransfersLockStatus onlyOwner returns (bool) {
        addLockingTime(to,lockingTime,value);
        _transfer(msg.sender, to, value);
        return true;
    }

     
     function transferLockedTokens(address from, address to, uint256 value) external onlyOwner returns (bool){
        require((_lockedAmount[from] >= value) && (now < time[from]), "Insufficient unlocked balance");
        require(from != address(0) && to != address(0), "Invalid address");
        _lockedAmount[from] = _lockedAmount[from] - value;
        _transfer(from,to,value);
     }

      
      function airdropByOwner(address[] memory _addresses, uint256[] memory _amount) public AllTransfersLockStatus onlyOwner returns (bool){
          require(_addresses.length == _amount.length,"Invalid Array");
          uint256 count = _addresses.length;
          for (uint256 i = 0; i < count; i++){
               _transfer(msg.sender, _addresses[i], _amount[i]);
               airdropcount = airdropcount + 1;
          }
          return true;
      }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0),"Invalid to address");
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0),"Invalid address");
        require(owner != address(0),"Invalid address");
        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0),"Invalid account");
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function burn(uint256 value) public onlyOwner checkLocking(msg.sender,value){
        _burn(msg.sender, value);
    }
}