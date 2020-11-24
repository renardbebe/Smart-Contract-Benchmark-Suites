 

pragma solidity ^0.5.0;

 

 
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
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
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

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
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

 

 
contract LockedPosition is ERC20, Ownable {

    mapping (address => uint256) private _partners;
    mapping (address => uint256) private _release;

    bool public publish = false;
    uint256 public released = 0;

     
    function partner(address from, address to, uint256 value) internal {
        require(from != address(0), "The from address is empty");
        require(to != address(0), "The to address is empty");

        if(publish){
             
            _release[from] = _release[from].add(value);
        }else{
             
            if(owner() != from){
                _partners[from] = _partners[from].sub(value);
            }
            if(owner() != to){
                _partners[to] = _partners[to].add(value);
            }
        }
    }
     
    function checkPosition(address account, uint256 value) internal view returns (bool) {
        require(account != address(0), "The account address is empty");
         
        if (isOwner()){
            return true;
        } 
         
        if (!publish){
            return true;
        } 
         
        if (released >= 100) {
            return true;
        }
         
        if(_partners[account]==0){
            return true;
        }
         
        return ((_partners[account]/100) * released) >= _release[account] + value;
    }

     
    function locked() external onlyOwner {
        publish = true;
    }
     
    function release(uint256 percent) external onlyOwner {
        require(percent <= 100 && percent > 0, "The released must be between 0 and 100");
        released = percent;
    }
      
    function getPosition() external view returns(uint256) {
        return _partners[msg.sender];
    }

     
    function getRelease() external view returns(uint256) {
        return _release[msg.sender];
    }

     
    function positionOf(address account) external onlyOwner view returns(uint256) {
        require(account != address(0), "The account address is empty");
        return _partners[account];
    }

     
    function releaseOf(address account) external onlyOwner view returns(uint256) {
        require(account != address(0), "The account address is empty");
        return _release[account];
    }
    
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(checkPosition(msg.sender, value), "Insufficient positions");

        partner(msg.sender, to, value);

        return super.transfer(to, value);
    }

    function transferFrom(address from,address to, uint256 value) public returns (bool) {
        require(checkPosition(from, value), "Insufficient positions");

        partner(from, to, value);

        return super.transferFrom(from, to, value);
    }
}

 

contract XinTimeToken is ERC20Detailed, LockedPosition {
    uint256 private constant INITIAL_SUPPLY = 2 * (10**8) * (10**18);

    constructor () public ERC20Detailed("Xin Time Token", "XTT", 18){
        _mint(msg.sender, INITIAL_SUPPLY);
        emit Transfer(address(0), msg.sender, totalSupply());
    }

}