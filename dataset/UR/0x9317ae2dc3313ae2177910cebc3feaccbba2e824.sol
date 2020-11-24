 

pragma solidity ^0.4.16;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
     
    string public name;
    string public symbol;
    uint8 public decimals = 6;
     
    uint256 public totalSupply;
    address owner=msg.sender;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    mapping(address => bool) public master;
    mapping(address => bool) public admin;
    
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event FrozenFunds(address target, bool frozen);
    event unFrozenFunds(address target, bool unfrozen);
    event AdminAddressAdded(address addr);
    event AdminAddressRemoved(address addr);
    event MasterAddressAdded(address addr);
    event MasterAddressRemoved(address addr);


     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
    
     
     modifier onlyMaster() {
     require(master[msg.sender]);
    _;
    }
    
     
     function addAddressToMaster(address addr) onlyOwner public returns(bool success) {
     if (!master[addr]) {
       master[addr] = true;
       MasterAddressAdded(addr);
       success = true; 
     }
     }
    
     function removeAddressFromMaster(address addr) onlyOwner public returns(bool success) {
     if (master[addr]) {
       master[addr] = false;
       MasterAddressRemoved(addr);
       success = true;
     }
     }
    
     
     modifier onlyAdmin() {
     require(admin[msg.sender]);
    _;
    }
    
     
     function addAddressToAdmin(address addr) onlyMaster public returns(bool success) {
     if (!admin[addr]) {
       admin[addr] = true;
       AdminAddressAdded(addr);
       success = true; 
     }
     }
    
     function removeAddressFromAdmin(address addr) onlyMaster public returns(bool success) {
     if (admin[addr]) {
       admin[addr] = false;
       AdminAddressRemoved(addr);
       success = true;
     }
     }
     
     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value >= balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
         
        require(!frozenAccount[_from]);          
        require(!frozenAccount[_to]);            

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
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        emit Burn(_from, _value);
        return true;
    }
    
     
     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyMaster public {
        require(balanceOf[msg.sender]<= totalSupply/10);
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }
    
     
     
     
    function freezeAccount(address target, bool freeze) onlyAdmin public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
     
    function unfreezeAccount(address target, bool freeze) onlyAdmin public {
        frozenAccount[target] = !freeze;
        unFrozenFunds(target, !freeze);
    }

     
     
     
     
    function claimfordividend() public {
        freezeAccount(msg.sender , true);
    }
    
     
     
    function payoutfordividend (address target, uint256 divpercentage) onlyOwner public{
        _transfer(msg.sender, target, ((divpercentage*balanceOf[target]/100 + 5 - 1) / 5)*5);
        unfreezeAccount(target , true);
    }
}