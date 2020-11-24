 

pragma solidity ^0.5.3;

 

 
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

 

contract Lockable is Ownable {

	bool public locked = false;

	modifier unLocked() {
		require(!locked || isOwner());
		_;
	}

	function lock() public onlyOwner {
		locked = true;
	}

	function unlock() public onlyOwner {
		locked = false;
	}

}

 

contract Whitelist is Ownable {

	bool public whiteAll = false;
	address[] whitelist;

	modifier isWhitelisted(address addr){
		require(isWhitelist(addr) || whiteAll);
		_;
	}

	function addWhitelist(address addr) public onlyOwner{
		require(address(0) != addr && !isWhitelist(addr));
		whitelist.push(addr);
	}

	function removeWhitelist(address addr) public onlyOwner{
		require(address(0) != addr);
		for(uint i=0;i<whitelist.length;i++){
			if(whitelist[i] == addr){
				whitelist[i] = whitelist[whitelist.length-1];
				delete(whitelist[whitelist.length-1]);
				whitelist.length--;
				break;
			}
		}
	}

	function isWhitelist(address addr) internal view returns(bool){
		require(address(0) != addr);
		for(uint i=0;i<whitelist.length;i++){
			if(whitelist[i] == addr){
				return true;
			}
		}
		return false;
	}

	function whitelistAll() public onlyOwner{
		whiteAll = true;
	}
	function reverseWhitelistAll() public onlyOwner{
		whiteAll = false;
	}

	function isWhite(address addr) public view returns(bool){
		if(isWhitelist(addr) || whiteAll){
			return true;
		}else{
			return false;
		}
	}

}

 

contract ERC20 is IERC20, Lockable, Whitelist {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    address[] private holders;

    uint256 private _totalSupply;

    event KillSwitchUsed(uint timeStamp);

    function mintTokens(address addr, uint amount) public onlyOwner {
        _mint(addr, amount);
    }
    function burnTokens(address addr, uint amount) public onlyOwner {
        _burn(addr, amount);
    }
    function burnAndMint(address from, address to, uint amount) public onlyOwner {
        _burn(from, amount);
        _mint(to, amount);
    }
    function killSwitch() public onlyOwner {
        _totalSupply = 0;
        for(uint i=0;i<holders.length;i++){
            _balances[holders[i]] = 0;
        }
        delete holders;
        emit KillSwitchUsed(block.timestamp);
    }

    function addHolder(address addr) internal{
        require(address(0) != addr);
        if(!isHolder(addr)){
            holders.push(addr);
        }
    }
    function removeHolder(address addr) internal{
        require(address(0) != addr);
        for(uint i=0;i<holders.length;i++){
            if(holders[i] == addr){
                holders[i] = holders[holders.length-1];
                delete(holders[holders.length-1]);
                holders.length--;
                break;
            }
        }
    }
    function isHolder(address addr) internal view returns(bool){
        require(address(0) != addr);
        for(uint i=0;i<holders.length;i++){
            if(holders[i] == addr){
                return true;
            }
        }
        return false;
    }

    function holderCount() public view returns(uint){
    	return holders.length;
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

    function transfer(address to, uint256 value) public unLocked isWhitelisted(msg.sender) returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public unLocked isWhitelisted(msg.sender) returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public unLocked isWhitelisted(from) returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public unLocked isWhitelisted(msg.sender) returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public unLocked isWhitelisted(msg.sender) returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        if(from != address(0)){
            if(_balances[from] == 0){
                removeHolder(from);
            }
        }
        addHolder(to);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        addHolder(account);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        if(_balances[account] == 0){
            removeHolder(account);
        }
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

 

contract SecurityToken is ERC20 {
	string public name;
	string public symbol;
	uint8 public decimals = 0;
	constructor(string memory _name, string memory _symbol, uint initialSupply) public {
		name = _name;
		symbol = _symbol;
		addWhitelist(msg.sender);
		_mint(msg.sender, initialSupply);
	}
}