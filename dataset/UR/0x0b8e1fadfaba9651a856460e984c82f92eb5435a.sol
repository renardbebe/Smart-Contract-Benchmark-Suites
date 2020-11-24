 

pragma solidity ^0.5.9;
 
  
library SafeMath{
    function mul(uint a, uint b) internal pure returns (uint){
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
 
    function div(uint a, uint b) internal pure returns (uint){
        uint c = a / b;
        return c;
    }
 
    function sub(uint a, uint b) internal pure returns (uint){
        assert(b <= a); 
        return a - b; 
    } 
  
    function add(uint a, uint b) internal pure returns (uint){ 
        uint c = a + b; assert(c >= a);
        return c;
    }
}

 
contract BIPToken{
    using SafeMath for uint;
    
    string public constant name = "Blockchain Invest Platform Token";
    string public constant symbol = "BIP";
    uint32 public constant decimals = 18;

    address public constant addressICO = 0x6712397d604410b0F99A205Aa8f7ac1B1a358F91;
    address public constant addressInvestors = 0x83DBcaDD8e9c7535DD0Dc42356B8e0AcDccb8c2b;
    address public constant addressMarketing = 0x01D98aa48D98bae8F1E30Ebf2A31b532018C3C61;
    address public constant addressPreICO = 0xE556E2Dd0fE094032FD7242c7880F140c89f17B8;
    address public constant addressTeam = 0xa3C9E790979D226435Da43022e41AF1CA7f8080B;
    address public constant addressBounty = 0x9daf97360086e1454ea8379F61ae42ECe0935740;
    
    uint public totalSupply = 200000000 * 1 ether;
    mapping(address => uint) balances;
    mapping (address => mapping (address => uint)) internal allowed;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

     
    constructor() public{
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);

        _transfer(addressICO,       124000000 * 1 ether);
        _transfer(addressInvestors,  32000000 * 1 ether);
        _transfer(addressMarketing,  16000000 * 1 ether);
        _transfer(addressPreICO,     14000000 * 1 ether);
        _transfer(addressTeam,        8000000 * 1 ether);
        _transfer(addressBounty,      6000000 * 1 ether);
    }
    
     
    function balanceOf(address _owner) public view returns (uint){
        return balances[_owner];
    }
 
      
    function _transfer(address _to, uint _value) private returns (bool){
        require(msg.sender != address(0));
        require(_to != address(0));
        require(_value > 0 && _value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true; 
    }

      
    function transfer(address _to, uint _value) public returns (bool){
        return _transfer(_to, _value);
    } 
    
      
    function massTransfer(address[] memory _to, uint[] memory _value) public returns (bool){
        require(_to.length == _value.length);

        uint len = _to.length;
        for(uint i = 0; i < len; i++){
            if(!_transfer(_to[i], _value[i])){
                return false;
            }
        }
        return true;
    } 
    
      
    function transferFrom(address _from, address _to, uint _value) public returns (bool){
        require(msg.sender != address(0));
        require(_to != address(0));
        require(_value > 0 && _value <= balances[_from] && _value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
 
     
    function approve(address _spender, uint _value) public returns (bool){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
 
     
    function allowance(address _owner, address _spender) public view returns (uint){
        return allowed[_owner][_spender]; 
    } 
 
     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool){
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]); 
        return true; 
    }
 
     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool){
        uint oldValue = allowed[msg.sender][_spender];
        if(_subtractedValue > oldValue){
            allowed[msg.sender][_spender] = 0;
        }else{
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}