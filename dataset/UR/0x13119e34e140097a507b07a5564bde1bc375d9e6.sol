 

pragma solidity ^0.4.21;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 

contract Owned {
    constructor() public { owner = msg.sender; }
    address owner;
    
    
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 

contract IMTTokenIMTInterface is Owned {

     
    uint256 public totalSupply;

     
    
    function balanceOf(address _owner) public view returns (uint256 balance);


    
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
 
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
   
}

 
contract InitialMTTokenIMT is IMTTokenIMTInterface {
    
    using SafeMath for uint256;
    
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;



     
    event Burn(address indexed burner, uint256 value);

    
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    
    constructor (
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {

        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
    }
    
    
    function transfer(address _to, uint256 _value)  public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        _transferFrom(msg.sender, _from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    
    function burn(uint256 _value) public onlyOwner returns (bool success) {
       _burn(msg.sender, _value);
       return true;      
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }   

      
        
     
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success){
        return IMTTokenIMTInterface(tokenAddress).transfer(owner, tokens);
    }

     
    
    
     
    function _burn(address _who, uint256 _value) internal returns (bool success) {
     
        balances[_who] = balances[_who].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);

        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal  returns (bool success) {
         
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }

    function _transferFrom(address _who, address _from, address _to, uint256 _value) internal returns (bool success) {
        
        uint256 allow = allowed[_from][_who];
        require(balances[_from] >= _value && allow >= _value);

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][_who] = allowed[_from][_who].sub(_value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
}