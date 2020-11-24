 

pragma solidity ^0.4.11;
 

 
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

 

contract admined {
    address public admin;  

    bool public locked = true;  
     
    function admined() internal {
        admin = msg.sender;  
        Admined(admin);
    }

    modifier onlyAdmin() {  
        require(msg.sender == admin);
        _;
    }

    modifier lock() {  
        require(locked == false);
        _;
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
}


 
contract ERC20TokenInterface {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    }


contract ERC20Token is admined, ERC20TokenInterface {  
    using SafeMath for uint256;
    uint256 totalSupply;
    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;  

     
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
     
    function increaseSupply(uint256 _amount, address _to) public onlyAdmin lock returns (bool success) {
      totalSupply = totalSupply.add(_amount);
      balances[_to] = balances[_to].add(_amount);
      Transfer(0, _to, _amount);
      return true;
    }
     
    function decreaseSupply(uint _amount, address _from) public onlyAdmin lock returns (bool success) {
      balances[_from] = balances[_from].sub(_amount);
      totalSupply = totalSupply.sub(_amount);  
      Transfer(_from, 0, _amount);
      return true;
    }

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract AssetMoira is admined, ERC20Token {
    string public name = 'Moira';
    uint8 public decimals = 18;
    string public symbol = 'Moi';
    string public version = '1';

    function AssetMoira(address _team) public {
        totalSupply = 666000000 * (10**uint256(decimals));
        balances[this] = 600000000 * (10**uint256(decimals));
        balances[_team] = 66000000 * (10**uint256(decimals));
        allowed[this][msg.sender] = balances[this];
         
        Transfer(0, this, balances[this]);
        Transfer(0, _team, balances[_team]);
        Approval(this, msg.sender, balances[_team]);

    }
     
    function() public {
        revert();
    }
}