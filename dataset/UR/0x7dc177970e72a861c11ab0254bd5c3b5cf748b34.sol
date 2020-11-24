 

pragma solidity ^0.4.20;

contract EXTRADECOIN{
     
    string public name;
    string public symbol;
    address target;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Replay(address investorAddress, uint256 amount); 
    
     
    function EXTRADECOIN(
        string tokenName,
        string tokenSymbol,
        address _target
    ) public {
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        target = _target;
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
        
    }
    
    function () payable internal {
        target.transfer(msg.value);
        emit Replay(msg.sender, msg.value);
    }
}