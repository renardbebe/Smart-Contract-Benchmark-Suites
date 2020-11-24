 

pragma solidity ^0.4.18;
 
 
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }    
}

 

contract admined {
    address public admin;  
    address public allowed; 

    bool public locked = true;  
     
    function admined() internal {
        admin = msg.sender;  
        Admined(admin);
    }

    modifier onlyAdmin() {  
        require(msg.sender == admin || msg.sender == allowed);
        _;
    }

    modifier lock() {  
        require(locked == false);
        _;
    }


    function allowedAddress(address _allowed) onlyAdmin public {
        allowed = _allowed;
        Allowed(_allowed);
    }
     
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        require(_newAdmin != address(0));
        admin = _newAdmin;
        TransferAdminship(admin);
    }
     
    function lockSupply(bool _locked) onlyAdmin public {
        locked = _locked;
        LockedSupply(locked);
    }

     
    event TransferAdminship(address newAdmin);
    event Admined(address administrador);
    event LockedSupply(bool status);
    event Allowed(address allow);
}


 
contract ERC20TokenInterface {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

contract ERC20Token is admined, ERC20TokenInterface {  
    using SafeMath for uint256;
    
    uint256 totalSupply_;
    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;  

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
      return balances[_owner];
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
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

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract SecureEgg is admined, ERC20Token {
    string public name = "Secure Egg";
    string public symbol = "SEG";
    string public version = "1.0";
    uint8 public decimals = 18;
    address public owner = 0xC365aa1d5C71A61c5b05Dc953a79a125D40ce472;

    function SecureEgg() public {
        totalSupply_ = 1000000000000 * (10**uint256(decimals));  
        balances[this] = totalSupply_;
        allowed[this][owner] = balances[this];  
        
        _transferTokenToOwner();

         
        Transfer(0, this, totalSupply_);
        Approval(this, msg.sender, balances[this]);

    }
    
    function _transferTokenToOwner() internal {
        balances[this] = balances[this].sub(totalSupply_);
        balances[owner] = balances[owner].add(totalSupply_);
        Transfer(this, owner, totalSupply_);
    }
     
    function() public {
        revert();
    }
}