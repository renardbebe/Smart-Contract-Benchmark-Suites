 

pragma solidity 0.4.19;
 

 
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
    bool public lockSupply;  

     
    function admined() internal {
        admin = msg.sender;  
        Admined(admin);
    }

    modifier onlyAdmin() {  
        require(msg.sender == admin);
        _;
    }

    modifier supplyLock() {  
        require(lockSupply == false);
        _;
    }

     
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        require(_newAdmin != address(0));
        admin = _newAdmin;
        TransferAdminship(admin);
    }

     
    function setSupplyLock(bool _set) onlyAdmin public {  
        lockSupply = _set;
        SetSupplyLock(_set);
    }

     
    event SetSupplyLock(bool _set);
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

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
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));  
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));  
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function burnToken(uint256 _burnedAmount) onlyAdmin supplyLock public {
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _burnedAmount);
        totalSupply = SafeMath.sub(totalSupply, _burnedAmount);
        Burned(msg.sender, _burnedAmount);
    }

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burned(address indexed _target, uint256 _value);
}

 
contract Asset is ERC20Token {
    string public name = 'ZECASH';
    uint8 public decimals = 18;
    string public symbol = 'ZCH';
    string public version = '1';

    function Asset() public {
        totalSupply = 500000000 * (10**uint256(decimals));  
        balances[msg.sender] = totalSupply;

        Transfer(0, this, totalSupply);
        Transfer(this, msg.sender, balances[msg.sender]);
    }
    
     
    function() public {
        revert();
    }

}