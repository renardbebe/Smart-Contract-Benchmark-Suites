 

pragma solidity ^0.4.24;

 

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}    

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract Leimen is owned{
    
 

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event FrozenFunds(address target, bool frozen);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    string public name;
    string public symbol;
    uint8 public decimals = 2;
    uint256 public totalSupply;
    
 

    function Leimen() public {
	    totalSupply = 1000000000 * 100 ;
    	balanceOf[msg.sender] = totalSupply ;
        name = "Leimen test";
        symbol = "Lts";         
    }
    
 

    mapping (address => bool) public frozenAccount;
    uint256 public eth_amount ;
    bool public stoptransfer ;
    bool public stopsell;
    

    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function set_prices(uint256 _eth_amount) onlyOwner {
        eth_amount  = _eth_amount  ;
    }

    function withdraw_Leim(uint256 amount)  onlyOwner {
        require(balanceOf[this] >= amount) ;
        balanceOf[this] -= amount ;
        balanceOf[msg.sender] += amount ;
    }
    
    function withdraw_Eth(uint amount_wei) onlyOwner {
        msg.sender.transfer(amount_wei) ;
    }
    
    function set_Name(string _name) onlyOwner {
        name = _name;
    }
    
    function set_symbol(string _symbol) onlyOwner {
        symbol = _symbol;
    }
    
    function set_stopsell(bool _stopsell) onlyOwner {
        stopsell = _stopsell;
    }
    
    function set_stoptransfer(bool _stoptransfer) onlyOwner {
        stoptransfer = _stoptransfer;
    }
    
    function burn(uint256 _value) onlyOwner {
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;            
        totalSupply -= _value;                      
        Burn(msg.sender, _value);
    }    

 

    function _transfer(address _from, address _to, uint _value) internal {
	    require(!frozenAccount[_from]);
	    require(!stoptransfer);
        require(_to != 0x0);
        
        require(_value >= 0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);

        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
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

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

 

    function () payable {
        buy();
    }

    function buy() payable returns (uint amount){
	    require(!stopsell);
        amount = msg.value * eth_amount / (10 ** 18) ;
        require(balanceOf[this] >= amount);           
        balanceOf[msg.sender] += amount;           
        balanceOf[this] -= amount; 
        Transfer(this, msg.sender, amount);         
        return amount;    
    }
}