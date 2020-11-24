 

pragma solidity ^0.4.16;

contract ERC20Token{
     
    uint256 public totalSupply;
    
    function balanceOf(address _owner) public view returns (uint256 balance);
    
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
 
contract Ownable{
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  function Ownable() public {
    owner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

 
 
 
contract Safe is Ownable {
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
        Pause();
    }
   
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
    
     
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

     
    function safeSubtract(uint256 a, uint256 b) internal pure returns (uint256) {
        uint c = a - b;
        assert(b <= a && c <= a);
        return c;
    }
     
    function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        uint c = a * b;
        assert(a == 0 || (c / a) == b);
        return c;
    }

     
    function () public payable {
        require(msg.value == 0);
    }
}

 
 
 
 
contract insChainToken is Safe, ERC20Token {
    string public constant name = 'Guaranteed Ethurance Token Extra';               
    string public constant symbol = 'GETX';                                   
    uint8 public constant decimals = 18;                                      
    uint256 public constant INITIAL_SUPPLY = 1e9 * 10**uint256(decimals);
    uint256 public totalSupply;
    string public version = '2';
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => uint256) freeze;

    event Burn(address indexed burner, uint256 value);
    
    modifier whenNotFreeze() {
        require(freeze[msg.sender]==0);
        _;
    }
    
    function insChainToken() public {
        totalSupply = INITIAL_SUPPLY;                               
        balances[msg.sender] = INITIAL_SUPPLY;                      
        Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
    
    function transfer(address _to, uint256 _value)  whenNotPaused whenNotFreeze public returns (bool success) {
        require(_to != address(this));
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = safeSubtract(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused whenNotFreeze public returns (bool success) {
        require(_to != address(this));
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = safeSubtract(balances[_from],_value);
        balances[_to] = safeAdd(balances[_to],_value);
        allowed[_from][msg.sender] = safeSubtract(allowed[_from][msg.sender],_value);
        Transfer(_from, _to, _value);
        return true;
    }
    

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

   

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = safeAdd(allowed[msg.sender][_spender],_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

   
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
        } else {
        allowed[msg.sender][_spender] = safeSubtract(oldValue,_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function updateFreeze(address account) onlyOwner public returns(bool success){
        if (freeze[account]==0){
          freeze[account]=1;
        }else{
          freeze[account]=0;
        }
        return true;
    }

    function freezeOf(address account) public view returns (uint256 status) {
        return freeze[account];
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function burn(uint256 _value) public {
      require(_value <= balances[msg.sender]);
      address burner = msg.sender;
      balances[burner] = safeSubtract(balances[burner],_value);
      totalSupply = safeSubtract(totalSupply, _value);
      Burn(burner, _value);
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
        return true;
    }


}