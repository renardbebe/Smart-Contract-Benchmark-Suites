 

pragma solidity ^0.4.24;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract Ownable {
    
    address public owner;
  
     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused, "Contract Paused. Events/Transaction Paused until Further Notice");
        _;
    }

     
    modifier whenPaused() {
        require(paused, "Contract Functionality Resumed");
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

contract StandardToken is Pausable {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 supply;
    uint256 public initialSupply;
    uint256 public totalSupply;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() public {
        name = "Valorem";
        symbol = "VLR";
        decimals = 18;
        supply = 200000000;
        
        initialSupply = supply * (10 ** uint256(decimals));
        totalSupply = initialSupply;
        balances[owner] = totalSupply;
        balanceOf[msg.sender] = initialSupply;
        bountyTransfers();
    }

    function bountyTransfers() internal {

        address reserveAccount;
        address bountyAccount;

        uint256 reserveToken;
        uint256 bountyToken;


        reserveAccount = 0x000f1505CdAEb27197FB652FB2b1fef51cdc524e;
        bountyAccount = 0x00892214999FdE327D81250407e96Afc76D89CB9;

        reserveToken = ( totalSupply * 25 ) / 100;
        bountyToken = ( reserveToken * 7 ) / 100;

        balanceOf[msg.sender] = totalSupply - reserveToken;
        balanceOf[bountyAccount] = bountyToken;
        reserveToken = reserveToken - bountyToken;
        balanceOf[reserveAccount] = reserveToken;

        emit Transfer(msg.sender,reserveAccount,reserveToken);
        emit Transfer(msg.sender,bountyAccount,bountyToken);
    }

     
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view whenNotPaused returns (uint256) {
        return balances[_owner];
    }

     
    function transferFrom( address _from, address _to, uint256 _value ) public whenNotPaused returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view whenNotPaused returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval( address _spender, uint256 _addedValue ) public whenNotPaused returns (bool) {
        allowed[msg.sender][_spender] = ( allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval( address _spender, uint256 _subtractedValue ) public whenNotPaused returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract Valorem is StandardToken {

    using SafeMath for uint256;

    mapping (address => uint256) public freezed;

    event Burn(address indexed burner, uint256 value);
    event Mint(address indexed to, uint256 amount);
    event Withdraw(address indexed _from, address indexed _to, uint256 _value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);

     
    function burn(uint256 _value) public onlyOwner whenNotPaused {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
         
         
        balances[_who] = balances[_who].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

    function burnFrom(address _from, uint256 _value) public onlyOwner whenNotPaused {
        require(_value <= allowed[_from][msg.sender]);
         
         
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _burn(_from, _value);
    }

     
    function mint(address _to, uint256 _amount) public onlyOwner whenNotPaused returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function freeze(address _spender,uint256 _value) public onlyOwner whenNotPaused returns (bool success) {
        require(_value < balances[_spender]);
        require(_value >= 0); 
        balances[_spender] = balances[_spender].sub(_value);                     
        freezed[_spender] = freezed[_spender].add(_value);                               
        emit Freeze(_spender, _value);
        return true;
    }
	
    function unfreeze(address _spender,uint256 _value) public onlyOwner whenNotPaused returns (bool success) {
        require(freezed[_spender] < _value);
        require(_value <= 0); 
        freezed[_spender] = freezed[_spender].sub(_value);                      
        balances[_spender] = balances[_spender].add(_value);
        emit Unfreeze(_spender, _value);
        return true;
    }
    
    function withdrawEther(address _account) public onlyOwner whenNotPaused payable returns (bool success) {
        _account.transfer(address(this).balance);

        emit Withdraw(this, _account, address(this).balance);
        return true;
    }
    
    function newTokens(address _owner, uint256 _value) onlyOwner public{
        balanceOf[_owner] = balanceOf[_owner].add(_value);
        totalSupply = totalSupply.add(_value);
        emit Transfer(this, _owner, _value);
    }

    function() public payable {
        
    }
}