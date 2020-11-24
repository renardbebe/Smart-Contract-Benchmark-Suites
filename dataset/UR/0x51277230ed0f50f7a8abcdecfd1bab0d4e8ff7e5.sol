 

pragma solidity 0.4.21;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256){
        assert(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256){
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) view public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) view public returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Ownable {
    address  owner;

    function Ownable() public{
        owner = msg.sender;
    }

     
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public{
        assert(newOwner != address(0));
        owner = newOwner;
    }
}


contract StandardToken is ERC20 {
    using SafeMath for uint256;
    mapping (address => mapping (address => uint256)) allowed;
    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool){
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) view public returns (uint256 balance){
        return balances[_owner];
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        uint256 _allowance = allowed[_from][msg.sender];
        require (balances[_from] >= _value);
        require (_allowance >= _value);
         
         
         
         
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool){
         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) view public returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
}


contract GamingCoin is StandardToken, Ownable {
    string public name = '';
    string public symbol = '';
    uint8 public  decimals = 0;
    uint256 public maxMintBlock = 0;

    event Mint(address indexed to, uint256 amount);

     
    function mint(address _to, uint256 _amount) onlyOwner  public returns (bool){
        require(maxMintBlock == 0);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(0,  _to, _amount);  
        maxMintBlock = 1;
        return true;
    }

     
    function multiTransfer(address[] destinations, uint256[] tokens) public returns (bool success){
         
         
        require(destinations.length > 0);
        require(destinations.length < 128);
        require(destinations.length == tokens.length);
         
        uint8 i = 0;
        uint256 totalTokensToTransfer = 0;
        for (i = 0; i < destinations.length; i++){
            require(tokens[i] > 0);            
             
            totalTokensToTransfer = totalTokensToTransfer.add(tokens[i]);
        }
         
         
         
        require (balances[msg.sender] > totalTokensToTransfer);        
         
        balances[msg.sender] = balances[msg.sender].sub(totalTokensToTransfer);
        for (i = 0; i < destinations.length; i++){
             
            balances[destinations[i]] = balances[destinations[i]].add(tokens[i]);
             
            emit Transfer(msg.sender, destinations[i], tokens[i]);
        }
        return true;
    }

    function GamingCoin(string _name , string _symbol , uint8 _decimals) public{
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }
}