 

pragma solidity ^0.4.25;

 
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

contract ComplianceRegistry is Ownable{

    address public service;

    event ChangeService(address _old, address _new);

    constructor(address _service) public {
        service = _service;
    }

    modifier isContract(address _addr) {
        uint length;
        assembly { length := extcodesize(_addr) }
        require(length > 0);
        _;
    }

    function changeService(address _service) onlyOwner isContract(_service) public {
        address old = service;
        service = _service;
        emit ChangeService(old, service);
    }
}
contract ComplianceService {

    function check(address _token,address _spender,address _from,address _to,uint256 _amount) public view returns (uint8);

}
contract DefaultService is ComplianceService, Ownable {


    constructor()public{

    }

    function check(address _token,address _spender,address _from,address _to,uint256 _amount) public view returns (uint8){
        return 0;
    }

}
contract StandardERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string name, string symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns(string) {
        return _name;
    }

     
    function symbol() public view returns(string) {
        return _symbol;
    }

     
    function decimals() public view returns(uint8) {
        return _decimals;
    }
     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(
        address owner,
        address spender
    )
    public
    view
    returns (uint256)
    {
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

     
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
    public
    returns (bool)
    {
        require(value <= _allowed[from][msg.sender]);

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

     
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
    public
    returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
    public
    returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(value <= _balances[from]);
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != 0);
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
     
     
     
     
     
     
     
     

     
     
     
     
     
     
     
     
     
     
}


contract PropertyToken is StandardERC20,Ownable{

    using SafeMath for uint256;

    ComplianceRegistry public registry;


    event CheckStatus(uint8 errorCode, address indexed spender, address indexed from, address indexed to, uint256 value);

    constructor(string _name, string _symbol, uint8 _decimals,uint256 _totalSupply,ComplianceRegistry _registry) public
    StandardERC20(_name,_symbol,_decimals)
    {
        require(_registry != address(0));
        registry=_registry;
         
        _mint(msg.sender,_totalSupply);
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        if (_check(msg.sender, to, value)) {
             
            return super.transfer(to,value);
        } else {
            return false;
        }
    }
     
    function transferFrom(address from,address to,uint256 value) public returns (bool)
    {
        if (_check(from,to,value)) {
             
            return super.transferFrom(from,to,value);
        } else {
            return false;
        }
    }
     
    function approve(address spender, uint256 value) public returns (bool) {
        if (_check(msg.sender,spender,value)) {
            return super.approve(spender,value);
        } else {
            return false;
        }
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool)
    {
        if (_check(msg.sender,spender,addedValue)) {
            return super.increaseAllowance(spender,addedValue);
        } else {
            return false;
        }
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool)
    {
        if (_check(msg.sender,spender,subtractedValue)) {
            return  super.decreaseAllowance(spender,subtractedValue);
        } else {
            return false;
        }
    }

    function destory(address _adrs) public onlyOwner returns(bool){
        require(_adrs!=address(0));
        selfdestruct(_adrs);
        return true;
    }

    function _check(address _from, address _to, uint256 _value) private returns (bool) {
        ComplianceService service= _service();
        uint8 errorCode =service.check(this, msg.sender, _from, _to, _value);
        emit CheckStatus(errorCode, msg.sender, _from, _to, _value);
        return errorCode == 0;
    }

    function _service() public view returns (ComplianceService) {
        return ComplianceService(registry.service());
    }
}