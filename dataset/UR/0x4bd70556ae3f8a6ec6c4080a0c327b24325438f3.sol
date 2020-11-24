 

pragma solidity ^0.4.24;

contract Owner {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Sender Not Authorized");
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract HxroTokenContract is Owner {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public lockedFund;
    string public version;
	
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    constructor (uint256 _initialSupply, string _tokenName, string _tokenSymbol, uint8 _decimals, uint256 _lockedFund) public {
        totalSupply = _initialSupply * 10 ** uint256(_decimals);
        lockedFund = _lockedFund * 10 ** uint256(_decimals);
        balanceOf[msg.sender] = totalSupply - lockedFund;
        decimals = _decimals;
        name = _tokenName;
        symbol = _tokenSymbol;
        version = "v6";
    }
    
	 
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0, "Valid Address Require");
         
        require(balanceOf[_from] >= _value, "Balance Insufficient");
         
        require(balanceOf[_to] + _value >= balanceOf[_to], "Amount Overflow");
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

	 
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

	 
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender], "Exceed Allowance");      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

	 
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
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
        require(balanceOf[msg.sender] >= _value, "Balance Insufficient");    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

	 
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value, "Balance Insufficient");                 
        require(_value <= allowance[_from][msg.sender], "Exceed Allowance");     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }

    function sweep(address _from, address _to, uint256 _value) public onlyOwner {
        require(_from != 0x0, "Invalid Sender Address");
        require(_to != 0x0, "Invalid Recipient Address");
        require(_value != 0, "Amount should not be 0");
        allowance[_from][msg.sender] += _value;
        transferFrom(_from, _to, _value);
    }

    function getMetaData() public view returns(string, string, uint8, uint256, string, address, uint256){
        return (name, symbol, decimals, totalSupply, version, owner, lockedFund);
    }

    function releaseLockedFund(address _to, uint256 _amount) public onlyOwner {
        require(_to != 0x0, "Valid Address Required!");
        require(_amount <= lockedFund, "Amount Exceeded Locked Fund");
        lockedFund -= _amount;
        balanceOf[_to] += _amount;
    }
}