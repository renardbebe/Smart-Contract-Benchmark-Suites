 

pragma solidity >0.4.24 <0.6.0;

 
contract SafeMath{
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0); 
        uint256 c = a / b;
        assert(a == b * c + a % b); 
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract LEASToken is SafeMath{
    string public name = "Linked Ecological Available System";
    string public symbol = "LEAS";
    uint8 public decimals = 18;
    uint256 public totalSupply = 200 * 10 ** 8 * 10 ** uint256(decimals);

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public{
        balanceOf[msg.sender] = totalSupply;     
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success){
        if (_to == 0x0000000000000000000000000000000000000000) revert();                                                
        if (_value <= 0) revert(); 
        if (balanceOf[msg.sender] < _value) revert();                            
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();                  
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);     
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);                   
        emit Transfer(msg.sender, _to, _value);      
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value <= 0) revert();
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (_to == 0x0000000000000000000000000000000000000000) revert();                                    
        if (_value <= 0) revert();
        if (balanceOf[_from] < _value) revert();                     
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();      
        if (_value > allowance[_from][msg.sender]) revert();         
        balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);   
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);       
        allowance[_from][msg.sender] = SafeMath.sub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);       
        return true;
    }
}