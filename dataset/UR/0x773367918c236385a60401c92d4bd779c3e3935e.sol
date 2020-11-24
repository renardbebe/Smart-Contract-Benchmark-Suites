 

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

 

contract admined {
    address public admin;  
    address public allowed; 

    bool public locked = true;  
     
    function admined() internal {
        admin = msg.sender;  
        emit Admined(admin);
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
        emit Allowed(_allowed);
    }
     
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        require(_newAdmin != address(0));
        admin = _newAdmin;
        emit TransferAdminship(admin);
    }
     
    function lockSupply(bool _locked) onlyAdmin public {
        locked = _locked;
        emit LockedSupply(locked);
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
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));  
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
      allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
    }

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Cowboy is admined, ERC20Token {
    
    string public name = "Cowboy Coin";
    string public symbol = "CWBY";
    string public version = "1.0";
    uint8 public decimals = 18;
    
     
    address public beneficiary = 0x9bF52817A5103A9095706FB0b9a027fCEA0e18Cf;

    function Cowboy() public {
        totalSupply_ = 100000000 * (10**uint256(decimals));
        balances[this] = totalSupply_;
         
        allowed[this][beneficiary] = balances[this];  
        
        _transferTokenToOwner();

         
        emit Transfer(0, this, totalSupply_);
        emit Approval(this, beneficiary, balances[this]);

    }
    
    function _transferTokenToOwner() internal {
        balances[this] = balances[this].sub(totalSupply_);
        balances[beneficiary] = balances[beneficiary].add(totalSupply_);
        emit Transfer(this, beneficiary, totalSupply_);
    }    
    
    function giveReward(address _from, address _buyer, uint256 _value) public returns (bool success) {
        require(_buyer != address(0));
        require(balances[_from] >= _value);

        balances[_buyer] = balances[_buyer].add(_value);
        balances[_from] = balances[_from].sub(_value);
        emit Transfer(_from, _buyer, _value);
        return true;
    }
    
     
    function() public {
        revert();
    }
}