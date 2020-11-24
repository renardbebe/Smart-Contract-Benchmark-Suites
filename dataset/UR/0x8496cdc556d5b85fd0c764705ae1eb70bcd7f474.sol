 

pragma solidity >=0.4.0 < 0.7.0;

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract LOVEAirCoffee is ERC20 {
    
    address owner = msg.sender;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowed;
    
    bool public coinWasBlocked = false;
    bool public frozenCoin = false;
    
     
    string public name="LOVE Air Coffee";
    string public symbol="LAC";
    uint8 public decimals = 18;
    
    uint256 public tokensPerOneEther;
    
    uint256 public minEther;
    uint256 public maxEther;

    enum State { Disabled, Enabled }
    
    State public state = State.Disabled;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed from, uint256 value);

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
     
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
     
    constructor(uint256 initialSupply) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender]=totalSupply;
        emit Transfer(address(0),owner,totalSupply);
    }
    
     
    function startBuyingTokens(uint256 _minEther,uint256 _maxEther) public onlyOwner {
        require(state == State.Disabled);
        require(tokensPerOneEther > 0);
        require(_minEther > 0);
        require(_maxEther > _minEther);
        
         
        if(!coinWasBlocked){
            frozenCoin = true;   
            coinWasBlocked = true;
        }
        
        minEther = _minEther * 10 ** uint256(decimals);
        maxEther = _maxEther * 10 ** uint256(decimals);
        state = State.Enabled;
    }
    
     
    function stopBuyingTokens() public onlyOwner {
        require(state == State.Enabled);
        state = State.Disabled;
        frozenCoin = false;
    }

     
    function setPrices(uint256 newBuyPrice) onlyOwner public {
        tokensPerOneEther = newBuyPrice;
    }

     
    function () payable external {
        require(state == State.Enabled);
        require(tokensPerOneEther > 0);
        require(msg.value >= minEther && msg.value <= maxEther);
        
        uint256 tokens = (tokensPerOneEther * msg.value);
        _transfer(owner, msg.sender, tokens);    
        owner.transfer(msg.value);
    }
    
     
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
     
    function balanceOf(address _owner) constant public returns (uint256) {
        return balanceOf[_owner];
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal {
        require( _to != address(this)); 
        require (_to != address(0x0));                           
        require (balanceOf[_from] >= _value);                    
        require (balanceOf[_to] + _value >= balanceOf[_to]);     
        balanceOf[_from] -= _value;                              
        balanceOf[_to] += _value;                                
        emit Transfer(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(!frozenCoin);                
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(!frozenCoin);                                
        require(_value <= allowed[_from][msg.sender]);      
        allowed[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(!frozenCoin);                        
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);               
        require(_value <= allowed[_from][msg.sender]);     
        require(!frozenCoin);                              
        balanceOf[_from] -= _value;                        
        allowed[_from][msg.sender] -= _value;              
        totalSupply -= _value;                             
        emit Burn(_from, _value);
        return true;
    }
}