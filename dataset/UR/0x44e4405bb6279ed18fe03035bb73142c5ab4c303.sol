 

pragma solidity >=0.4.22 <0.6.0;

contract TIMOERC20 {
    string public name = "Timo Protocols";
    string public symbol = "TIMO";
    uint8 public decimals = 0;
     
    uint256 public totalSupply = 210000000;

     
    mapping (address => uint256) public balanceOf;
   
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
     
    event Burn(address indexed from, uint256 value);
  
     
    constructor() public { 
        balanceOf[msg.sender] = totalSupply;                     
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != address(0x0));
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
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

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        emit Burn(msg.sender, _value);
        return true;
    }

  
}