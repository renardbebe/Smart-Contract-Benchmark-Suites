 

pragma solidity ^0.4.19;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract mETHNetwork {
     
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public funds;
    address public director;
    bool public saleClosed;
    bool public directorLock;
    uint256 public claimAmount;
    uint256 public payAmount;
    uint256 public feeAmount;

     
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public buried;
    mapping (address => uint256) public claimed;

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event Burn(address indexed _from, uint256 _value);
    
     
    event Claim(address indexed _target, address indexed _payout, address indexed _fee);

     
    function mETHNetwork() public {
        director = msg.sender;
        name = "mETH";
        symbol = "METH";
        decimals = 10;
        saleClosed = true;
        directorLock = false;
        funds = 0;
        totalSupply = 0;
        
        }
    
     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    modifier onlyDirector {
         
         
        require(!directorLock);
        
         
        require(msg.sender == director);
        _;
    }
    
    modifier onlyDirectorForce {
         
        require(msg.sender == director);
        _;
    }
    
     
    function transferDirector(address newDirector) public onlyDirectorForce {
        director = newDirector;
    }
    
     
    function withdrawFunds() public onlyDirectorForce {
        director.transfer(this.balance);
    }
    
     
    function closeSale() public onlyDirector returns (bool success) {
         
        require(!saleClosed);
        
         
        saleClosed = true;
        return true;
    }

     
    function openSale() public onlyDirector returns (bool success) {
         
        require(saleClosed);
        
         
        saleClosed = false;
        return true;
    }
 
     
    function () public payable {
         
        require(!saleClosed);
        
         
        uint256 amount = msg.value * 100000000;
        
         
        require(totalSupply + amount <= (9000000000 * 10 ** uint256(decimals)));
        
         
        totalSupply += amount;
        
         
        balances[msg.sender] += amount;
        
         
        funds += msg.value;
        
         
        Transfer(this, msg.sender, amount);
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(!buried[_from]);
        

        
         
        require(_to != 0x0);
        
         
        require(balances[_from] >= _value);
        
         
        require(balances[_to] + _value > balances[_to]);
        
         
        uint256 previousBalances = balances[_from] + balances[_to];
        
         
        balances[_from] -= _value;
        
         
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        
         
        assert(balances[_from] + balances[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
         
        require(!buried[msg.sender]);
        
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
         
        require(!buried[msg.sender]);
        
         
        require(balances[msg.sender] >= _value);
        
         
        balances[msg.sender] -= _value;
        
         
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
         
        require(!buried[_from]);
        
         
        require(balances[_from] >= _value);
        
         
        require(_value <= allowance[_from][msg.sender]);
        
         
        balances[_from] -= _value;
        
         
        allowance[_from][msg.sender] -= _value;
        
         
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}