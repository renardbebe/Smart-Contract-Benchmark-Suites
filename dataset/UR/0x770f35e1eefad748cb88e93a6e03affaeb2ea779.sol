 

 

pragma solidity ^0.4.24;

 
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
        require(isOwner(), "The caller must be owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Cannot transfer control of the contract to the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
contract StandardToken is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowed;

    uint256 internal _totalSupply;
    
     
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
        require(to != address(0), "Cannot transfer to the zero address");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0), "Cannot approve to the zero address");
        require(owner != address(0), "Setter cannot be the zero address");

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

}

 
contract FreezableToken is StandardToken, Ownable {
    mapping(address=>bool) internal _frozenAccount;

    event FrozenAccount(address indexed target, bool frozen);

     
    function frozenAccount(address account) public view returns(bool){
        return _frozenAccount[account];
    }

    function frozen(address account) public view returns(bool){
        bool frozen = true;
        _frozenAccount[account] = frozen;
  	    emit FrozenAccount(account, frozen);
  	    return true;
    }

     
    function frozenCheck(address account) internal view {
        require(!frozenAccount(account), "Address has been frozen");
    }

     
    function freeze(address account, bool frozen) public onlyOwner {
  	    _frozenAccount[account] = frozen;
  	    emit FrozenAccount(account, frozen);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        frozenCheck(msg.sender);
        frozenCheck(_to);
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        frozenCheck(msg.sender);
        frozenCheck(_from);
        frozenCheck(_to);
        return super.transferFrom(_from, _to, _value);
    }    

     
    function _approve(address owner, address spender, uint256 value) internal {
        frozenCheck(owner);
        frozenCheck(spender);
        super._approve(owner, spender, value);
    }

}

 
contract MintableToken is FreezableToken {
     
    function _mint(address account, uint256 value) internal {
        require(account != address(0), "Cannot mint to the zero address");

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        frozenCheck(to);
        _mint(to, value);
        return true;
    }
}

 
contract BurnableToken is FreezableToken {

     
    function burn(uint256 _value) public onlyOwner {
        _burn(msg.sender, _value);
    }

     
    function burnFrom(address _from, uint256 _value) public onlyOwner {
        require(_value <= _allowed[_from][msg.sender], "Not enough allowance");
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
        _burn(_from, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= _balances[_who], "Not enough token balance");
         
         
        _balances[_who] = _balances[_who].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Transfer(_who, address(0), _value);
    }
}

contract Token is MintableToken, BurnableToken {
    string public  name;  
    string public  symbol;  
    uint8 public  decimals;
    
    constructor(string _name,
    string _symbol, 
    uint256 _initSupply, 
    uint8 _decimals
	) public {
		name = _name;
		symbol = _symbol;
		decimals = _decimals;
	}
    
     
    function airdrop(address[] memory addressList, uint256[] memory amountList) public onlyOwner returns (bool) {
        uint256 length = addressList.length;
        require(addressList.length == amountList.length, "Inconsistent array length");
        require(length > 0 && length <= 150, "Invalid number of transfer objects");
        uint256 amount;
        for (uint256 i = 0; i < length; i++) {
            frozenCheck(addressList[i]);
            require(amountList[i] > 0, "The transfer amount cannot be 0");
            require(addressList[i] != address(0), "Cannot transfer to the zero address");
            amount = amount.add(amountList[i]);
            _balances[addressList[i]] = _balances[addressList[i]].add(amountList[i]);
            emit Transfer(msg.sender, addressList[i], amountList[i]);
        }
        require(_balances[msg.sender] >= amount, "Not enough tokens to transfer");
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        return true;
    }        
}