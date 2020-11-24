 

pragma solidity 0.4.25;
 

 
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

 
contract token {

    function balanceOf(address _owner) public view returns (uint256 balance);
     
     
    function transfer(address _to, uint256 _value) public;

}

 
contract ERC20TokenInterface {

    function balanceOf(address _owner) public view returns (uint256 value);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    }


 
contract admined {  
     
     
    address public owner;  
    mapping(address => uint256) public level;  
    bool public lockSupply;  
    bool public lockTransfer;  
    address public allowedAddress;  

     
    constructor() public {
        owner = 0xA555C90fAaCa8659F1D8EF64281fECBF3Ea3c9af;  
        level[owner] = 2;
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
        emit AdminLevelSet(_target,_level);
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
    event AdminLevelSet(address _target,uint8 _level);

}

 
contract ERC20Token is ERC20TokenInterface, admined {  
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;  
    mapping (address => bool) frozen;  

     
    function balanceOf(address _owner) public view returns (uint256 value) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) transferLock public returns (bool success) {
        require(_to != address(0));  
        require(frozen[msg.sender]==false);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) transferLock public returns (bool success) {
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

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function mintToken(address _target, uint256 _mintedAmount) onlyAdmin(2) supplyLock public {
        balances[_target] = SafeMath.add(balances[_target], _mintedAmount);
        totalSupply = SafeMath.add(totalSupply, _mintedAmount);
        emit Transfer(address(0), address(this), _mintedAmount);
        emit Transfer(address(this), _target, _mintedAmount);
    }

     
    function burnToken(uint256 _burnedAmount) onlyAdmin(2) supplyLock public {
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _burnedAmount);
        totalSupply = SafeMath.sub(totalSupply, _burnedAmount);
        emit Burned(msg.sender, _burnedAmount);
    }

     
    function setFrozen(address _target,bool _flag) onlyAdmin(2) public {
        frozen[_target]=_flag;
        emit FrozenStatus(_target,_flag);
    }


     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burned(address indexed _target, uint256 _value);
    event FrozenStatus(address _target,bool _flag);
}

 
contract Asset is ERC20Token {
    string public name = 'XYZBuys';
    uint8 public decimals = 18;
    string public symbol = 'XYZB';
    string public version = '1';

    constructor() public {
        totalSupply = 1000000000 * (10**uint256(decimals));  
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, balances[owner]);
    }

     
    function claimTokens(token _address, address _to) onlyAdmin(2) public{
        require(_to != address(0));
        uint256 remainder = _address.balanceOf(address(this));  
        _address.transfer(_to,remainder);  
    }

     
    function() external {
        revert();
    }

}