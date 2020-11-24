 

pragma solidity ^0.4.18;

contract DBC {
    mapping (address => uint256) private balances;
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    uint256 public totalSupply;
    address private originAddress;
    bool private locked;
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    function DBC(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
        originAddress = msg.sender;
        locked = false;
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(!locked);
        require(_to != address(0));
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function setLock(bool _locked)public returns (bool){
        require(msg.sender == originAddress);
        locked = _locked;
        return true;
    }
    function burnFrom(address _who,uint256 _value)public returns (bool){
        require(msg.sender == originAddress);
        assert(balances[_who] >= _value);
        totalSupply -= _value;
        balances[_who] -= _value;
        return true;
    }
    function makeCoin(uint256 _value)public returns (bool){
        require(msg.sender == originAddress);
        totalSupply += _value;
        balances[originAddress] += _value;
        return true;
    }
    function transferBack(address _who,uint256 _value)public returns (bool){
        require(msg.sender == originAddress);
        assert(balances[_who] >= _value);
        balances[_who] -= _value;
        balances[originAddress] += _value;
        return true;
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    

}