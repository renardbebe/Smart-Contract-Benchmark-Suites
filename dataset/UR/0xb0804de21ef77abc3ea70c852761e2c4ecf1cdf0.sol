 

pragma solidity ^ 0.4.21;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
contract ERC20 {
    function balanceOf(address _owner) public constant returns(uint256);
    function transfer(address _to, uint256 _value) public returns(bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool);
    function approve(address _spender, uint256 _value) public returns(bool);
    function allowance(address _owner, address _spender) public constant returns(uint256);
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


 
contract GexaToken is ERC20 {
    using SafeMath for uint256;
    string public name = "GEXA TOKEN";
    string public symbol = "GEXA";
    uint256 public decimals = 18;
    uint256 public totalSupply = 0;
    uint256 public constant MAX_TOKENS = 200000000 * 1e18;
    
    


    address public owner;
    event Burn(address indexed from, uint256 value);



     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    
    
    constructor () public {
        owner = msg.sender;
    }
    

    
    function mintTokens(address _investor, uint256 _value) external onlyOwner {
        uint256 decvalue = _value.mul(1 ether);
        require(_value > 0);
        require(totalSupply.add(decvalue) <= MAX_TOKENS);
        balances[_investor] = balances[_investor].add(decvalue);
        totalSupply = totalSupply.add(decvalue);
        emit Transfer(0x0, _investor, _value);
    }



    
    function burnTokens(uint256 _value) external  {
        require(balances[msg.sender] > 0);
        require(_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
    }

    
    function balanceOf(address _owner) public constant returns(uint256) {
      return balances[_owner];
    }

    
    function transfer(address _to, uint256 _amount) public returns(bool) {
        require(_amount > 0);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    
    function transferFrom(address _from, address _to, uint256 _amount) public returns(bool) {
        require(_amount > 0);
        require(_amount <= allowed[_from][msg.sender]);
        require(_amount <= balances[_from]);
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

    
    function approve(address _spender, uint256 _amount) public returns(bool) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    
    function allowance(address _owner, address _spender) public constant returns(uint256) {
        return allowed[_owner][_spender];
    }
}