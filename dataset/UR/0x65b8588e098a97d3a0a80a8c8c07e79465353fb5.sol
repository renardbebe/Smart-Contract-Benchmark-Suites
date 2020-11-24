 

pragma solidity 0.5.6;
 

 
library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

 
interface extToken {

    function balanceOf(address _owner) external returns(uint256 balance);

    function transfer(address _to, uint256 _value) external returns(bool success);

}

 
contract ERC20TokenInterface {

    function balanceOf(address _owner) public view returns(uint256 value);

    function transfer(address _to, uint256 _value) public returns(bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success);

    function approve(address _spender, uint256 _value) public returns(bool success);

    function allowance(address _owner, address _spender) public view returns(uint256 remaining);

}


 
contract admined {  
     
     
    address public owner;  
    mapping(address => uint256) public level;  
    bool public lockSupply;  
    bool public lockTransfer;  
    address public allowedAddress;  

     
    constructor() public {
        owner = 0xb4549c4CBbB5003beEb2b70098E6f5AD4CE4c2e6;  
        level[0xb4549c4CBbB5003beEb2b70098E6f5AD4CE4c2e6] = 2;
        emit Owned(owner);
    }

     
    function setAllowedAddress(address _to) onlyAdmin(2) public {
        allowedAddress = _to;
        emit AllowedSet(_to);
    }

    modifier onlyAdmin(uint8 _level) {  
        require(msg.sender == owner || level[msg.sender] >= _level);
        _;
    }

    modifier supplyLock() {  
        require(lockSupply == false);
        _;
    }

    modifier transferLock() {  
        require(lockTransfer == false || allowedAddress == msg.sender);
        _;
    }

     
    function transferOwnership(address _newOwner) onlyAdmin(2) public {  
        require(_newOwner != address(0));
        owner = _newOwner;
        level[_newOwner] = 2;
        emit TransferAdminship(owner);
    }

    function setAdminLevel(address _target, uint8 _level) onlyAdmin(2) public {
        level[_target] = _level;
        emit AdminLevelSet(_target, _level);
    }

     
    function setSupplyLock(bool _set) onlyAdmin(2) public {  
        lockSupply = _set;
        emit SetSupplyLock(_set);
    }

     
    function setTransferLock(bool _set) onlyAdmin(2) public {  
        lockTransfer = _set;
        emit SetTransferLock(_set);
    }

     
    event AllowedSet(address _to);
    event SetSupplyLock(bool _set);
    event SetTransferLock(bool _set);
    event TransferAdminship(address newAdminister);
    event Owned(address administer);
    event AdminLevelSet(address _target, uint8 _level);

}

 
contract ERC20Token is ERC20TokenInterface, admined {  
    using SafeMath
    for uint256;
    uint256 public totalSupply;
    mapping(address => uint256) balances;  
    mapping(address => mapping(address => uint256)) allowed;  
    mapping(address => bool) frozen;  

     
    function balanceOf(address _owner) public view returns(uint256 value) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) transferLock public returns(bool success) {
        require(frozen[msg.sender] == false);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) transferLock public returns(bool success) {
        require(frozen[_from] == false);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns(bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function burnToken(uint256 _burnedAmount) onlyAdmin(2) supplyLock public {
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _burnedAmount);
        totalSupply = SafeMath.sub(totalSupply, _burnedAmount);
        emit Burned(msg.sender, _burnedAmount);
    }

     
    function setFrozen(address _target, bool _flag) onlyAdmin(2) public {
        frozen[_target] = _flag;
        emit FrozenStatus(_target, _flag);
    }


     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burned(address indexed _target, uint256 _value);
    event FrozenStatus(address _target, bool _flag);
}

 
contract Asset is ERC20Token {
    string public name = 'ORIGIN Foundation Token';
    uint8 public decimals = 18;
    string public symbol = 'ORIGIN';
    string public version = '1';

    constructor() public {
        totalSupply = 100000000000 * (10 ** uint256(decimals));  
        balances[0xb4549c4CBbB5003beEb2b70098E6f5AD4CE4c2e6] = totalSupply;
        emit Transfer(address(0), 0xb4549c4CBbB5003beEb2b70098E6f5AD4CE4c2e6, balances[0xb4549c4CBbB5003beEb2b70098E6f5AD4CE4c2e6]);
    }

     
    function claimExtTokens(extToken _address, address _to) onlyAdmin(2) public {
        require(_to != address(0));
        uint256 remainder = _address.balanceOf(address(this));  
        _address.transfer(_to, remainder);  
    }

     
    function () external {
        revert();
    }

}