 

pragma solidity ^0.4.18;

 
library SafeMath {

   
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
    }

 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
    }
  
}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract BCSToken {
     
    using SafeMath for uint;
     
    string public name;
    string public symbol;
    uint256 public decimals = 8;
    uint256 public totalSupply;
    address private owner;
     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function BCSToken() public {
    	name = "BlockChainStore Token";                           
        symbol = "BCST";                                          
    	uint256 initialSupply = 100000000;			             
        totalSupply = initialSupply * (10 ** uint256(decimals)); 
        balanceOf[msg.sender] = totalSupply;                     
        owner = msg.sender;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(SafeMath.add(balanceOf[_to] ,_value) >= balanceOf[_to]);
         
        uint previousBalances = SafeMath.add(balanceOf[_from] , balanceOf[_to]);
         
        balanceOf[_from]=SafeMath.sub(balanceOf[_from] , _value);
         
        balanceOf[_to]=SafeMath.add(balanceOf[_to] , _value);
        emit Transfer(_from, _to, _value);
         
        assert(SafeMath.add(balanceOf[_from] , balanceOf[_to]) == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender]=SafeMath.sub(allowance[_from][msg.sender] , _value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);                           
        require(owner==msg.sender);                                         
        balanceOf[msg.sender]=SafeMath.sub(balanceOf[msg.sender],_value);   
        totalSupply = SafeMath.sub(totalSupply , _value);                   
        emit Burn(msg.sender, _value);
        return true;
    }

}