 

 

pragma solidity >=0.4.25 <0.6.0;

contract Ownable {
     
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

     
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can execute this function");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;  
        newOwner = address(0);  
    }
}

 

pragma solidity >=0.4.25 <0.6.0;


contract Freezable is Ownable { 
    mapping (address => bool) internal isFrozen;
        
    uint256 public _unfreezeDateTime = 1559390400;  

    event globalUnfreezeDatetimeModified(uint256);
    event FreezeFunds(address target, bool frozen);

     
    modifier onlyNotFrozen(address a) {
        require(!isFrozen[a], "Any account in this function must not be frozen");
        _;
    }

     
    modifier onlyAfterUnfreeze() {
        require(block.timestamp >= _unfreezeDateTime, "You cannot tranfer tokens before unfreeze date" );
        _;
    }
     
    function getUnfreezeDateTime() public view returns (uint256) {
        return _unfreezeDateTime;
    }

     
    function setUnfreezeDateTime(uint256 unfreezeDateTime) onlyOwner public {
        _unfreezeDateTime = unfreezeDateTime;
        emit globalUnfreezeDatetimeModified(unfreezeDateTime); 
    }

     
    function isAccountFrozen( address target ) public view returns (bool) {
        return isFrozen[target];
    }

     
    function freeze(address target, bool doFreeze) onlyOwner public {
        if( msg.sender == target ) {
            revert();
        }

        isFrozen[target] = doFreeze;
        emit FreezeFunds(target, doFreeze);
    }
}

 

pragma solidity >=0.4.25 <0.6.0;
 
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

 

pragma solidity >=0.4.25 <0.6.0;

 
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

 

pragma solidity >=0.4.25 <0.6.0;
 

contract TokenStorage  {
    uint256 internal _totalSupply;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping(address => uint256)) internal _allowed;
}

 

pragma solidity >=0.4.25 <0.6.0;

contract AddressGuard {
    modifier onlyAddressNotZero(address addr) {
        require(addr != address(0), "The address must not be 0x0");
        _;   
    }
}

 

pragma solidity >=0.4.25 <0.6.0;




 
contract TokenRescue is Ownable, AddressGuard {
    address internal rescueAddr;

    modifier onlyRescueAddr {
        require(msg.sender == rescueAddr);
        _;
    }

    function setRescueAddr(address addr) onlyAddressNotZero(addr) onlyOwner public{
        rescueAddr = addr;
    }

    function getRescueAddr() public view returns(address) {
        return rescueAddr;
    }

    function rescueLostTokensByOwn(IERC20 lostTokenContract, uint256 value) external onlyRescueAddr {
        lostTokenContract.transfer(rescueAddr, value);
    }

    function rescueLostTokenByThisTokenOwner (IERC20 lostTokenContract, uint256 value) external onlyOwner {
        lostTokenContract.transfer(rescueAddr, value);
    } 
    
}

 

pragma solidity >=0.4.25 <0.6.0;









 
contract FinentToken is IERC20, Ownable, Freezable, TokenStorage, AddressGuard, TokenRescue {
    using SafeMath for uint256;
    string private _name;

    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

     
    constructor() public {
        _name = "Finent Token";
        _symbol = "FNT";
        _decimals = 18;  
        _mint(msg.sender, 1000000000 * 10 ** uint256(_decimals));
    }

     
    function name() public view returns (string memory) {
        return _name;
    }
    
     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint256) {
        return _decimals;
    }

     
    function balanceOfZero() public view returns (uint256) {
        return _balances[address(0)];
    }

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply - _balances[address(0)];
    }

    
     
    function balanceOf(address owner) onlyAddressNotZero(owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) onlyAddressNotZero(owner) onlyAddressNotZero(spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address _to, uint256 _value) onlyNotFrozen(msg.sender) onlyNotFrozen(_to) onlyAfterUnfreeze onlyAddressNotZero(_to) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function approve(address spender, uint256 value) public onlyAddressNotZero(spender) returns (bool) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) onlyNotFrozen(msg.sender) onlyNotFrozen(_from) onlyNotFrozen(_to) onlyAfterUnfreeze public returns (bool) {
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        emit Approval(_from, msg.sender, _allowed[_from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) onlyAddressNotZero(spender) public returns (bool) {
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) onlyAddressNotZero(spender) public returns (bool) {
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function burn(address addr, uint256 value) onlyOwner onlyAddressNotZero(addr) public {
        _burn(addr, value);
    }

     
    function burnFromOwner(uint256 value) onlyOwner public {
        _burn(msg.sender, value);
    }

     
    function mint(uint256 value) onlyOwner public {
        _mint(msg.sender, value);
    }

     
    function distribute(address addr, uint256 value, bool doFreeze) onlyOwner public {
        _distribute(addr, value, doFreeze);
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal {
        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

     
    function _distribute(address to, uint256 value, bool doFreeze) onlyOwner internal {
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);

        if( doFreeze && msg.sender != to ) {
            freeze( to, true );
        }

        emit Transfer(msg.sender, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);    
    }

    
     
     
     
    function () external payable {
        revert();
    }

}