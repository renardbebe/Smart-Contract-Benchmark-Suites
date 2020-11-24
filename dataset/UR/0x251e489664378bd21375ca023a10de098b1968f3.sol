 

pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        if (_a == 0) {
          return 0;
        }
        c = _a * _b;
        require(c / _a == _b);
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b != 0);  
        return _a / _b;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_a >= _b);  
        return _a - _b;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        require(c >= _a);
        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _who) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    event Approval(address indexed owner, address indexed spender, uint256 oldValue, uint256 value);   
    event Transfer(address indexed spender, address indexed from, address indexed to, uint256 value);  
    event Burn(address indexed burner, uint256 value);
}

contract Ownable {
    address public owner;
    event OwnershipRenounced( address indexed previousOwner );
    event OwnershipTransferred( address indexed previousOwner, address indexed newOwner );
    constructor() public {
        owner = msg.sender;
    }
 
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }
 
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
 
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract ERC20_CPM1_Token_v2 is Ownable, IERC20 {
    using SafeMath for uint256;
    mapping(address => uint256) internal balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 internal totalSupply_;
    string public name = "Cryptomillions Series 1";
    uint8 public decimals = 18;                
    string public symbol = "CPM-1";
    uint private TotalSupply = 600000000000000000000000000;
    string public version = '1.0';
    constructor() public {
        totalSupply_ = TotalSupply;
        balances[owner] = TotalSupply;
        emit Transfer(address(this), address(this), owner, TotalSupply);  
    }
 
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
 
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
 
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _transfer(_from, _to, _value);
        _approve(_from, msg.sender, _allowed[_from][msg.sender].sub(_value));
    
        return true;
    }
 
    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_from != address(0));
        require(_to != address(0));
         
        require(_to != address(this));
        require(balances[_from] >= _value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _from, _to, _value);  
    }
 
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }
 
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }
 
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        if (subtractedValue > _allowed[msg.sender][spender]) {  
        _allowed[msg.sender][spender] = 0;                      
        } 
        else {
            _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        }
        return true;
    }
 
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
 
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0));
        require(spender != address(0));
        uint256 _currentValue = _allowed[owner][spender];  
        if ( _allowed[owner][spender] == _currentValue ) {  
            _allowed[owner][spender] = value;    
        }
        emit Approval(owner, spender, _currentValue, value);  
    }
 
    function burnTokens(uint256 _value) public onlyOwner {
        _burn(msg.sender, _value);
    }
 
    function _burn(address _who, uint256 _value) internal {
        require(_value != 0);
        require(balances[_who] >= _value);
        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, _who, address(0), _value);  
    }
 
    function contractAddress() public view returns(address){
        return address(this);
    }
}