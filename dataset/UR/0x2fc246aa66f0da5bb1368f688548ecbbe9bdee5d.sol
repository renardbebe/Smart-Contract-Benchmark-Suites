 
contract TemcoToken is ERC20, Ownable, Lockable {
  
    using SafeMath for uint256;
      
    event OwnedValue(address owner, uint256 value);
    event Mint(address to, uint256 amount);
    event MintFinished();
    event Burn(address burner, uint256 value);
    
    mapping(address => uint256) public balances;    
    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 public totalSupply;
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
  
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    
    bool public mintingFinished = false;    
    
     
    constructor (
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    )public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        emit OwnedValue(msg.sender, 0);
        balances[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                              
    }
      
     
    function transfer(address _to, uint256 _value) public whenNotLockedUp returns (bool) {        
        emit OwnedValue(msg.sender, _value);
                
        require(_to != address(0));
        require(_to != address(this));
        require(_value <= balances[msg.sender]); 

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_to != address(this));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        if(nolockedUp(_from) == false){
            return false;
        }
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public whenNotLockedUp returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
  
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) whenNotLockedUp public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) whenNotLockedUp public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
  
     
    function burn(uint256 _value) external onlyOwner {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }
  
    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount) onlyOwner canMint external returns (bool) {
        require(_to != address(0) && _amount > 0);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function mintTo(address _from, address _to, uint256 _amount) onlyOwner canMint external returns (bool) {
        require(_from != address(0)  && _to != address(0) && _amount > 0);        
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);        
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint external returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
  
}
