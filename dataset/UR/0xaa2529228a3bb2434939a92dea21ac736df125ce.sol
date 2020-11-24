 

pragma solidity ^ 0.5 .7;
 
 
 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
     
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
         
        uint256 c = a / b;
         
        return c;
    }
     
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b <= a);
        return a - b;
    }
     
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}
 
contract ERC20Basic {
    function totalSupply() external view returns(uint256);

    function balanceOf(address who) external view returns(uint256);

    function transfer(address to, uint256 value) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ERC20 is ERC20Basic {
    uint256 public totalSupply;

    function allowance(address holder, address spender) external view returns(uint256);

    function transferFrom(address from, address to, uint256 value) external returns(bool);

    function approve(address spender, uint256 value) external returns(bool);
  
    event Approval(address indexed holder, address indexed spender, uint256 value);
}
contract Ownable {
    address public owner;
  
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
     
    constructor() public {
        owner = msg.sender;
    }
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
contract WCCToken is ERC20, Ownable {
    using SafeMath for uint256;
    string public constant name = "World currency conference coin";
    string public constant symbol = "WCC";
    uint8 public constant decimals = 18;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
  
     
     
     
    constructor() public {
        totalSupply = 900000000000 * (uint256(10) ** decimals);
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0x0), msg.sender, balances[msg.sender]);
    }
     
    function transfer(address _to, uint256 _value) external returns(bool) {
        require(_to != address(0));
        require(_to != address(this));
         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
     
    function balanceOf(address _holder) external view returns(uint256) {
        return balances[_holder];
    }
     
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool) {
        require(_to != address(0));
        require(_to != address(this));
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
     
    function approve(address _spender, uint256 _value) external returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
     
    function allowance(address _holder, address _spender) external view returns(uint256) {
        return allowed[_holder][_spender];
    }
}