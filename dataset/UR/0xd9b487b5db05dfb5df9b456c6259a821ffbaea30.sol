 

pragma solidity ^0.4.17;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract OysterPrePearl {
     
    string public name = "Oyster PrePearl";
    string public symbol = "PREPRL";
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;
    uint256 public funds = 0;
    address public owner;
    bool public saleClosed = false;
    bool public transferFreeze = false;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function OysterPrePearl() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function closeSale() public onlyOwner {
        saleClosed = true;
    }

    function openSale() public onlyOwner {
        saleClosed = false;
    }
    
    function freeze() public onlyOwner {
        transferFreeze = true;
    }
    
    function thaw() public onlyOwner {
        transferFreeze = false;
    }
    
    function () payable public {
        require(!saleClosed);
        require(msg.value >= 100 finney);
        require(funds + msg.value <= 8000 ether);
        uint buyPrice;
        if (msg.value >= 50 ether) {
            buyPrice = 8000; 
        }
        else if (msg.value >= 5 ether) {
            buyPrice = 7000; 
        }
        else buyPrice = 6000; 
        uint256 amount;
        amount = msg.value * buyPrice;                     
        totalSupply += amount;                             
        balanceOf[msg.sender] += amount;                   
        funds += msg.value;                                
        Transfer(this, msg.sender, amount);                
    }
    
    function withdrawFunds() public onlyOwner {
        owner.transfer(this.balance);
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(!transferFreeze);
         
        require(_to != 0x0);
         
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

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
}