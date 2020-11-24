 

pragma solidity ^0.4.18;
 

 
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

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    }

 
contract admined {  
    address public admin;  
    bool public lockTransfer;  
    address public allowedAddress;  

     
    function admined() internal {
        admin = msg.sender;  
        allowedAddress = msg.sender;
        AllowedSet(allowedAddress);
        Admined(admin);
    }

     
    function setAllowedAddress(address _to) onlyAdmin public {
        allowedAddress = _to;
        AllowedSet(_to);
    }

    modifier onlyAdmin() {  
        require(msg.sender == admin);
        _;
    }

    modifier transferLock() {  
        require(lockTransfer == false || allowedAddress == msg.sender);
        _;
    }

     
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        require(_newAdmin != address(0x0));
        admin = _newAdmin;
        TransferAdminship(admin);
    }

     
    function setTransferLockFree() onlyAdmin public {  
        require(lockTransfer == true);
        lockTransfer = false;
        SetTransferLock(lockTransfer);
    }

     
    event AllowedSet(address _to);
    event SetTransferLock(bool _set);
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

 
contract ERC20Token is ERC20TokenInterface, admined {  
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;  
    
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
      return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) transferLock public returns (bool success) {
        require(_to != address(0));  
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) transferLock public returns (bool success) {
        require(_to != address(0));  
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function batch(address[] data,uint256[] amount) onlyAdmin public {  
        
        require(data.length == amount.length);
        uint256 length = data.length;
        address target;
        uint256 value;

        for (uint i=0; i<length; i++) {  
            target = data[i];  
            value = amount[i];  
            transfer(target,value);
        }
    }

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract Asset is ERC20Token {
    string public name = 'Pitch';
    uint8 public decimals = 18;
    string public symbol = 'PCH';
    string public version = '1';

    function Asset() public {
        totalSupply = 1500000000 * (10**uint256(decimals));  
        balances[0xFAB6368b0F7be60c573a6562d82469B5ED9e7eE6] = 1500000 * (10**uint256(decimals));  
        balances[msg.sender] = 1498500000 * (10**uint256(decimals));  
        
         
         
        lockTransfer = true;
        SetTransferLock(lockTransfer);
        
        Transfer(0, this, totalSupply);
        Transfer(this, 0xFAB6368b0F7be60c573a6562d82469B5ED9e7eE6, balances[0xFAB6368b0F7be60c573a6562d82469B5ED9e7eE6]);
        Transfer(this, msg.sender, balances[msg.sender]);
    }
    
     
    function() public {
        revert();
    }
}