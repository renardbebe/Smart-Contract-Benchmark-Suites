 

pragma solidity ^0.4.16;

contract WEAToken {
    using SetLibrary for SetLibrary.Set;

    string public name;
    string public symbol;
    uint8 public decimals = 0;

    uint256 public totalSupply;


    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    SetLibrary.Set private allOwners;
    function amountOfOwners() public view returns (uint256)
    {
        return allOwners.size();
    }
    function ownerAtIndex(uint256 _index) public view returns (address)
    {
        return address(allOwners.values[_index]);
    }
    function getAllOwners() public view returns (uint256[])
    {
        return allOwners.values;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Burn(address indexed from, uint256 value);

    function WEAToken() public {
        totalSupply = 18000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        Transfer(0x0, msg.sender, totalSupply);
        allOwners.add(msg.sender);
        name = "Weaste Coin";
        symbol = "WEA";
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
        
         
        if (balanceOf[_from] == 0)
        {
            allOwners.remove(_from);
        }
        if (_value > 0)
        {
            allOwners.add(_to);
        }
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
        allowance[msg.sender][_spender] = _value;
        return true;
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

 

pragma solidity ^0.4.18;

library SetLibrary
{
    struct ArrayIndexAndExistsFlag
    {
        uint256 index;
        bool exists;
    }
    struct Set
    {
        mapping(uint256 => ArrayIndexAndExistsFlag) valuesMapping;
        uint256[] values;
    }
    function add(Set storage self, uint256 value) public returns (bool added)
    {
         
        if (self.valuesMapping[value].exists == true) return false;
        
         
        self.valuesMapping[value] = ArrayIndexAndExistsFlag({index: self.values.length, exists: true});
        
         
        self.values.push(value);
        
        return true;
    }
    function contains(Set storage self, uint256 value) public view returns (bool contained)
    {
        return self.valuesMapping[value].exists;
    }
    function remove(Set storage self, uint256 value) public returns (bool removed)
    {
         
        if (self.valuesMapping[value].exists == false) return false;
        
         
        self.valuesMapping[value].exists = false;
        
         
         
         
        if (self.valuesMapping[value].index < self.values.length-1)
        {
            uint256 valueToMove = self.values[self.values.length-1];
            uint256 indexToMoveItTo = self.valuesMapping[value].index;
            self.values[indexToMoveItTo] = valueToMove;
            self.valuesMapping[valueToMove].index = indexToMoveItTo;
        }
        
         
         
         
         
         
        
         
         
        self.values.length--;
        
         
         
        delete self.valuesMapping[value];
        
        return true;
    }
    function size(Set storage self) public view returns (uint256 amountOfValues)
    {
        return self.values.length;
    }
    
     
    function add(Set storage self, address value) public returns (bool added) { return add(self, uint256(value)); }
    function add(Set storage self, bytes32 value) public returns (bool added) { return add(self, uint256(value)); }
    function contains(Set storage self, address value) public view returns (bool contained) { return contains(self, uint256(value)); }
    function contains(Set storage self, bytes32 value) public view returns (bool contained) { return contains(self, uint256(value)); }
    function remove(Set storage self, address value) public returns (bool removed) { return remove(self, uint256(value)); }
    function remove(Set storage self, bytes32 value) public returns (bool removed) { return remove(self, uint256(value)); }
}