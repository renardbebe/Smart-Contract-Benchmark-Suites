 

pragma solidity 0.4.24;
 

 
library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
}

 
contract token {
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}

 
contract admined {  
    address public admin;  
    address public allowed;  
    bool public transferLock;  

     
    constructor() internal {
        admin = msg.sender;  
        emit Admined(admin);
    }

    modifier onlyAdmin() {  
        require(msg.sender == admin);
        _;
    }

    modifier onlyAllowed() {  
        require(msg.sender == admin || msg.sender == allowed || transferLock == false);
        _;
    }

     
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        require(_newAdmin != address(0));
        admin = _newAdmin;
        emit TransferAdminship(_newAdmin);
    }

     
    function SetAllow(address _newAllowed) onlyAdmin public {
        allowed = _newAllowed;
        emit SetAllowed(_newAllowed);
    }

    
    function setTransferLock(bool _set) onlyAdmin public {  
        transferLock = _set;
        emit SetTransferLock(_set);
    }

     
    event SetTransferLock(bool _set);
    event SetAllowed(address _allowed);
    event TransferAdminship(address _newAdminister);
    event Admined(address _administer);

}

 
contract ERC20TokenInterface {
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
}


 
contract ERC20Token is admined,ERC20TokenInterface {  
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;  
    mapping (address => bool) frozen;  

     
    function balanceOf(address _owner) public constant returns (uint256 value) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) onlyAllowed public returns (bool success) {
        require(_to != address(0));  
        require(frozen[msg.sender]==false);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) onlyAllowed public returns (bool success) {
        require(_to != address(0));  
        require(frozen[_from]==false);
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

     
    function setFrozen(address _target,bool _flag) onlyAdmin public {
        frozen[_target]=_flag;
        emit FrozenStatus(_target,_flag);
    }

     
    function batch(address[] _target,uint256 _amount) onlyAdmin public {  
        uint256 size = _target.length;
        require( balances[msg.sender] >= size.mul(_amount));
        balances[msg.sender] = balances[msg.sender].sub(size.mul(_amount));

        for (uint i=0; i<size; i++) {  
            balances[_target[i]] = balances[_target[i]].add(_amount);
            emit Transfer(msg.sender, _target[i], _amount);
        }
    }

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event FrozenStatus(address _target,bool _flag);

}

 
contract Networth is ERC20Token {
    string public name = 'Networth';
    uint8 public decimals = 18;
    string public symbol = 'Googol';
    string public version = '1';

     
    constructor() public {
        totalSupply = 250000000 * 10 ** uint256(decimals);  
        balances[msg.sender] = totalSupply;
        emit Transfer(0, msg.sender, totalSupply);
    }

     
    function externalTokensRecovery(token _address) onlyAdmin public {
        uint256 remainder = _address.balanceOf(this);  
        _address.transfer(msg.sender,remainder);  
    }


     
    function() public {
        revert();
    }

}