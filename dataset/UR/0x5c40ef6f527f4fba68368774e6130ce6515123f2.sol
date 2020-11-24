 

contract ExtraBalToken {
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function transfer(address _to, uint256 _value) {
        if (balanceOf[msg.sender] < _value) throw;            
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
        balanceOf[msg.sender] -= _value;                      
        balanceOf[_to] += _value;                             
        Transfer(msg.sender, _to, _value);                    
    }

     
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balanceOf[_from] < _value) throw;                  
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;   
        if (_value > allowance[_from][msg.sender]) throw;    
        balanceOf[_from] -= _value;                           
        balanceOf[_to] += _value;                             
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

     
    function () {
        throw;      
    }

    uint constant D160 = 0x10000000000000000000000000000000000000000;

    address public owner;

    function ExtraBalToken() {
        owner = msg.sender;
    }

    bool public sealed;
     
     
    function fill(uint[] data) {
        if ((msg.sender != owner)||(sealed))
            throw;

        for (uint i=0; i<data.length; i++) {
            address a = address( data[i] & (D160-1) );
            uint amount = data[i] / D160;
            if (balanceOf[a] == 0) {    
                balanceOf[a] = amount;
                totalSupply += amount;
            }
        }
    }

    function seal() {
        if ((msg.sender != owner)||(sealed))
            throw;

        sealed= true;
    }

}