 

pragma solidity ^0.4.24;
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }
contract BeeAppToken {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply = 1500000000000000000000000000;
     
    mapping (address => uint256) public balanceOf;
     
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
     
     
     
     
    constructor(
        
        
        
    ) public {
         
        balanceOf[msg.sender] = totalSupply;                 
        name = "Bee App Token";                                    
        symbol = "BTO";                                
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
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      
        require(_value <= balanceOf[_from]);
        
         
        _transfer(_from, _to, _value);
        return true;
    }
}