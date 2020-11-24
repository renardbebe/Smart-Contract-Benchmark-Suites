 

pragma solidity ^0.4.10;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract TPLAYToken is owned {

     
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
     
    mapping (address => bool) public frozenAccount;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);

     
    function TPLAYToken(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits) public {
        balanceOf[msg.sender] = initialSupply;     
        totalSupply = initialSupply;
        name = tokenName;                          
        symbol = tokenSymbol;                      
        decimals = decimalUnits;                   
        owner = msg.sender;      		 
    }

    function () {
         
        revert();
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                                 
        require(balanceOf[_from] >= _value);                  
        require(balanceOf[_to] + _value >= balanceOf[_to]);   
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        Transfer(_from, _to, _value);
    }

     
    function mintToken(address target, uint256 mintedAmount) public onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }

     
    function burn(uint256 _value)  public onlyOwner returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        return true;
    }


}