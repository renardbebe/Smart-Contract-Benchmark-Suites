 

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

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public;

}

 
contract admined {  
    address public owner;  
    bool public lockTransfer;  
    address public allowedAddress;  

     
    constructor() internal {
        owner = msg.sender;  
        emit Admined(owner);
    }

    modifier onlyAdmin() {  
        require(msg.sender == owner);
        _;
    }

    
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        require(_newAdmin != 0);
        owner = _newAdmin;
        emit TransferAdminship(owner);
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


 
contract ERC20Token is admined, ERC20TokenInterface {  
    using SafeMath for uint256;  
    mapping (address => uint256) balances;  
    mapping (address => mapping (address => uint256)) allowed;  
    mapping (address => bool) frozen;  
    uint256 public totalSupply;

     
    function balanceOf(address _owner) public constant returns (uint256 bal) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(frozen[msg.sender] == false);
        require(_to != address(0));  
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(frozen[_from] == false && frozen[msg.sender] == false);
        require(_to != address(0));  
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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

    function setFrozen(address _owner, bool _flag) public onlyAdmin returns (bool success) {
      frozen[_owner] = _flag;
      emit Frozen(_owner,_flag);
      return true;
    }

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Frozen(address indexed _owner, bool _flag);

}

 
contract Asset is ERC20Token {
    string public name = 'VSTER';
    uint8 public decimals = 18;
    string public symbol = 'VAPP';
    string public version = '1';

    constructor() public {
        totalSupply = 50000000 * (10**uint256(decimals));  
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, balances[msg.sender]);
    }

     
    function claimTokens(token _address, address _to) onlyAdmin public{
        require(_to != address(0));
        uint256 remainder = _address.balanceOf(this);  
        _address.transfer(_to,remainder);  
    }


     
    function() public {
        revert();
    }

}