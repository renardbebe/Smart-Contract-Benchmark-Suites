 

pragma solidity 0.4.20;
 

 
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

contract admined {  
    address public admin;  

    function admined() internal {
        admin = msg.sender;  
        Admined(admin);
    }

    modifier onlyAdmin() {  
        require(msg.sender == admin);
        _;
    }

    function transferAdminship(address _newAdmin) onlyAdmin public {  
        admin = _newAdmin;
        TransferAdminship(admin);
    }

     
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

 
contract ERC20TokenInterface {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    }


 
contract ERC20Token is admined,ERC20TokenInterface {  
    using SafeMath for uint256;  
    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;  
    uint256 public totalSupply;
    
     
    function balanceOf(address _owner) public constant returns (uint256 bal) {
      return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));  
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
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
    string public name = 'CT Global';
    uint8 public decimals = 18;
    string public symbol = 'CTG';
    string public version = '1';
    
     
    function Asset() public {

        address writer = 0xFAB6368b0F7be60c573a6562d82469B5ED9e7eE6;
        totalSupply = 1000000 * (10 ** uint256(decimals));  
        
        balances[msg.sender] = 999000 * (10 ** uint256(decimals));  
        balances[writer] = 1000 * (10 ** uint256(decimals));  
        
        Transfer(0, this, totalSupply);
        Transfer(this, msg.sender, balances[msg.sender]); 
        Transfer(this, writer, balances[writer]);       
    }
    
     
    function() public {
        revert();
    }

}