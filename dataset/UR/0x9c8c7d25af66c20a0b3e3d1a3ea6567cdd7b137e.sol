 

pragma solidity ^0.4.11;

 

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract SNC is SafeMath, Pausable {

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply;

    address public owner;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function SNC() public {
        totalSupply = (10**8) * (10**8);
        balanceOf[this] = totalSupply;                       
        name = "Snow Coin";                                  
        symbol = "SNC";                                      
        decimals = 8;                                        
        owner = msg.sender;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);               
        require(balanceOf[_to] + _value >= balanceOf[_to]);     
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);    
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                  
        emit Transfer(msg.sender, _to, _value);                   
        return true;
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
        allowance[msg.sender][_spender] = _value;             
        emit Approval(msg.sender, _spender, _value);               
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
        require(balanceOf[_from] >= _value);                   
        require(balanceOf[_to] + _value >= balanceOf[_to]);    
        require(_value <= allowance[_from][msg.sender]);       
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);     
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);         
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function totalSupply() constant public returns (uint256 Supply) {
        return totalSupply;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balanceOf[_owner];
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }

    function() public payable {
        revert();
    }
}