 

pragma solidity 0.4.24;
 

 
library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

 
contract ERC20TokenInterface {

    function balanceOf(address _owner) public constant returns (uint256 value);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    }

 
contract admined {  
    address public admin;  
    mapping(address => uint256) public level;  
    bool public lockSupply;  

     
    constructor() public {
        admin = 0x6585b849371A40005F9dCda57668C832a5be1777;  
        level[admin] = 2;
        emit Admined(admin);
    }

    modifier onlyAdmin(uint8 _level) {  
        require(msg.sender == admin || level[msg.sender] >= _level);
        _;
    }

    modifier supplyLock() {  
        require(lockSupply == false);
        _;
    }

    
    function transferAdminship(address _newAdmin) onlyAdmin(2) public {  
        require(_newAdmin != address(0));
        admin = _newAdmin;
        level[_newAdmin] = 2;
        emit TransferAdminship(admin);
    }

    function setAdminLevel(address _target, uint8 _level) onlyAdmin(2) public {
        level[_target] = _level;
        emit AdminLevelSet(_target,_level);
    }

    
    function setSupplyLock(bool _set) onlyAdmin(2) public {  
        lockSupply = _set;
        emit SetSupplyLock(_set);
    }

     
    event SetSupplyLock(bool _set);
    event TransferAdminship(address newAdminister);
    event Admined(address administer);
    event AdminLevelSet(address _target,uint8 _level);

}

 
contract ERC20Token is ERC20TokenInterface, admined {  
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;  

     
    function balanceOf(address _owner) public constant returns (uint256 value) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));  
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));  
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));  
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function burnToken(address _target, uint256 _burnedAmount) onlyAdmin(2) supplyLock public {
        balances[_target] = SafeMath.sub(balances[_target], _burnedAmount);
        totalSupply = SafeMath.sub(totalSupply, _burnedAmount);
        emit Burned(_target, _burnedAmount);
    }

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burned(address indexed _target, uint256 _value);
    event FrozenStatus(address _target,bool _flag);
}

 
contract AssetGRP is ERC20Token {
    string public name = 'Gripo';
    uint8 public decimals = 18;
    string public symbol = 'GRP';
    string public version = '1';

    address writer = 0xA6bc924715A0B63C6E0a7653d3262D26F254EcFd;

    constructor() public {
        totalSupply = 200000000 * (10**uint256(decimals));  
        balances[writer] = totalSupply / 10000;  
        balances[admin] = totalSupply.sub(balances[writer]);

        emit Transfer(address(0), writer, balances[writer]);
        emit Transfer(address(0), admin, balances[admin]);
    }

     
    function() public {
        revert();
    }

}