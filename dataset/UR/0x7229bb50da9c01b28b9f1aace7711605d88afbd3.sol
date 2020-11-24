 

pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract OysterPrePearl {
     
    string public name = "Oyster PrePearl";
    string public symbol = "PREPRL";
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;
    uint256 public funds = 0;
    address public owner;
    address public partner;
    bool public saleClosed = false;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function OysterPrePearl() public {
        owner = msg.sender;
        partner = 0x0524Fe637b77A6F5f0b3a024f7fD9Fe1E688A291;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyAuth {
        require(msg.sender == owner || msg.sender == partner);
        _;
    }
    
    function closeSale() onlyOwner {
        saleClosed = true;
    }

    function openSale() onlyOwner {
        saleClosed = false;
    }
    
    function () payable {
        require(!saleClosed);
        require(msg.value >= 100 finney);
        require(funds + msg.value <= 5000 ether);
        uint buyPrice;
        if (msg.value >= 100 ether) {
            buyPrice = 17500; 
        }
        else if (msg.value >= 50 ether) {
            buyPrice = 12500; 
        }
        else if (msg.value >= 5 ether) {
            buyPrice = 10000; 
        }
        else buyPrice = 7500; 
        uint amount;
        amount = msg.value * buyPrice;                     
        totalSupply += amount;                             
        balanceOf[msg.sender] += amount;                   
        funds += msg.value;                                
        Transfer(this, msg.sender, amount);                
    }
    
    function withdrawFunds() onlyAuth {
        uint256 payout = (this.balance/2) - 2;
        owner.transfer(payout);
        partner.transfer(payout);
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
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