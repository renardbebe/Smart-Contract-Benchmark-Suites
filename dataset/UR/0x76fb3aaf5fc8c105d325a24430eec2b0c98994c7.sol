 

pragma solidity ^0.4.24;

 
 
 
 
 
 
 
 
 

contract EOSHate {

    string public name = "EOSHate";       
    string public symbol = "EOSHate";            
    uint256 public decimals = 18;             

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    mapping (uint => bool) public EosHaters;
    

    uint256 public totalSupply = 0;

    modifier validAddress {
        assert(0x0 != msg.sender);
        _;
    }
    
     
     
    
    function IHateEos(string reason) public {
        uint hash = uint(keccak256(bytes(reason)));
        if (!EosHaters[hash]){
             
             
            EosHaters[hash] = true; 
            balanceOf[msg.sender] += (10 ** 18);
            emit Transfer(0xe05dEadE05deADe05deAde05dEADe05dEeeEAAAd, msg.sender, 10**18);  
            emit NewEOSHate(msg.sender, reason);
            totalSupply += (10 ** 18);  
        }
    }

    function transfer(address _to, uint256 _value) public validAddress returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public validAddress returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public validAddress returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event NewEOSHate(address who, string reason);
}