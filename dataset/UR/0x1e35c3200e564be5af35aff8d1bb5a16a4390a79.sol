 

pragma solidity ^0.4.16;

 
library SafeMath {

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
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

 
contract ERC20Token is ERC20TokenInterface,admined {  
    using SafeMath for uint256;  
    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;  
    uint256 public totalSupply;

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
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

     
    function mintToken(address _target, uint256 _mintedAmount) onlyAdmin public {
        balances[_target] = SafeMath.add(balances[_target], _mintedAmount);
        totalSupply = SafeMath.add(totalSupply, _mintedAmount);
        Transfer(0, this, _mintedAmount);
        Transfer(this, _target, _mintedAmount);
    }

     
    function burnToken(address _target, uint256 _burnedAmount) onlyAdmin public {
        balances[_target] = SafeMath.sub(balances[_target], _burnedAmount);
        totalSupply = SafeMath.sub(totalSupply, _burnedAmount);
        Burned(_target, _burnedAmount);
    }

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burned(address indexed _target, uint256 _value);
}

 
contract RFL_Token is ERC20Token {
    string public name;
    uint256 public decimals = 18;
    string public symbol;
    string public version = '1';
    
     
    function RFL_Token(string _name, string _symbol, address _teamAddress) public {
        name = _name;
        symbol = _symbol;
        totalSupply = 100000000 * (10 ** decimals);  
        balances[this] = 80000000 * (10 ** decimals);  
        balances[_teamAddress] = 19000000 * (10 ** decimals);  
        balances[0xFAB6368b0F7be60c573a6562d82469B5ED9e7eE6] = 1000000 * (10 ** decimals);  
        allowed[this][msg.sender] = balances[this];  
        Transfer(0, this, balances[this]);
        Transfer(this, _teamAddress, balances[_teamAddress]);
        Transfer(this, 0xFAB6368b0F7be60c573a6562d82469B5ED9e7eE6, balances[0xFAB6368b0F7be60c573a6562d82469B5ED9e7eE6]);
        Approval(this, msg.sender, balances[this]);
    }
    
     
    function() public {
        revert();
    }

}