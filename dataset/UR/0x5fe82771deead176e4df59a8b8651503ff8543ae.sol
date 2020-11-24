 

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





 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
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




 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
}






contract ClickgemToken is ERC20, Ownable, ERC20Detailed {
	uint public initialSupply = 1200000000;
	mapping (address => uint256) public freezeList;
	
	mapping (address => uint256) public whiteList;
	mapping (address => LockItem[]) public lockList;
	
    struct LockItem {
    uint256  time;
    uint256  amount;
    
}
	
	constructor() public ERC20Detailed("ClickGemToken", "CGMT", 18) 
	{  
		_mint(msg.sender, initialSupply*1000000000000000000);
	}

	function freeze(address freezeAddress) public onlyOwner returns (bool done)
	{
		freezeList[freezeAddress]=1;
		return isFreeze(freezeAddress);
    	}

	function unFreeze(address freezeAddress) public onlyOwner returns (bool done)
	{
		delete freezeList[freezeAddress];
		return !isFreeze(freezeAddress); 
	}

	function isFreeze(address freezeAddress) public view returns (bool isFreezed) 
	{
		return freezeList[freezeAddress]==1;
	}

	function addToWhiteList(address whiteListAddress) public onlyOwner returns (bool done)
	{
        whiteList[whiteListAddress]=1;
        return isWhiteList(whiteListAddress);
    }

	function removeFromWhiteList(address whiteListAddress) public onlyOwner returns (bool done)
	{
        delete whiteList[whiteListAddress];
        return !isWhiteList(whiteListAddress);
    }

	function isWhiteList(address whiteListAddress) public view returns (bool iswhiteList) 
	{
        return whiteList[whiteListAddress]==1;
    }

	function isLocked(address lockedAddress) public view returns (bool isLockedAddress)
	{
		if(lockList[lockedAddress].length>0)
		{
		    for(uint i=0; i< lockList[lockedAddress].length; i++)
		    {
		        if(lockList[lockedAddress][i].time - now > 0)
		        return true;
		    }
		}
		return false;
	}

	function transfer(address _receiver, uint256 _amount) public returns (bool success)
	{
		require(!isFreeze(msg.sender));
		if(!isWhiteList(_receiver))
		{
		    if(!isLocked(_receiver)){
		        uint256 remain = balanceOf(msg.sender).sub(_amount);
		        
		       require(remain>=getLockedAmount(msg.sender));
		    }
		}
        return ERC20.transfer(_receiver, _amount);
	}

	function transferAndLock(address _receiver, uint256 _amount, uint256 time) public returns (bool success)
	{
        transfer(_receiver, _amount);
    	LockItem memory item = LockItem({amount:_amount, time:time+now});
		lockList[_receiver].push(item);
        return true;
	}
	
	function getLockedListSize(address lockedAddress) public view returns(uint256 _lenght)
	{
	    return lockList[lockedAddress].length;
	}
	
	function getLockedAmountAt(address lockedAddress, uint8 index) public view returns(uint256 _amount)
	{
	    return lockList[lockedAddress][index].amount;
	}
	
	function getLockedTimeAt(address lockedAddress, uint8 index) public view returns(uint256 _time)
	{
	    return lockList[lockedAddress][index].time.sub(now);
	}
	
	function getLockedAmount(address lockedAddress) public view returns(uint256 _amount)
	{
	    uint256 lockedAmount =0;
	    if(isLocked(lockedAddress))
	    {
	       for(uint8 j=0;j<lockList[lockedAddress].length;j++)
	       {
	        if(getLockedTimeAt(lockedAddress, j) > now )
	        {
	            lockedAmount=lockedAmount.add(getLockedAmountAt(lockedAddress, j));
	        }
	       }
	    }
	    return lockedAmount;
	}


}