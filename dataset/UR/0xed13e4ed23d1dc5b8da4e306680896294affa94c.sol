 

pragma solidity ^0.4.19;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
 
pragma solidity ^0.4.19;

 
contract ERC20_mtf{
    using SafeMath for uint256;

     

     
    uint256 constant MAX_UINT256 = 2**256 - 1;
    string public name = 'MetaFusion';               
    uint8 public decimals = 5;                       
    string public symbol = 'MTF';                    
    uint256 public totalSupply = 10000000000000;  
    uint256 public multiplier = 100000;
    mapping (address => uint256) balances;   

    function ERC20_mtf(
        address _owner
    ) public {
        balances[_owner] = totalSupply;                
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }


     
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
         
        if(_transfer(msg.sender, _to, _value)){
            return true;
        } else {
            return false;
        }
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns(bool success){
         
        require(_to != 0x0);
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        uint previousBalances = balances[_from] + balances[_to];
         
        balances[_from] = balances[_from].sub(_value);
         
        balances[_to] =  balances[_to].add(_value);

        Transfer(_from, _to, _value);

         
        assert(balances[_from] + balances[_to] == previousBalances);

        return true;
    }
}

 
 
pragma solidity ^0.4.19;

 
contract ERC20_mtf_allowance is ERC20_mtf {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) allowed;   

     
    function ERC20_mtf_allowance(
        address _owner
    ) public ERC20_mtf(_owner){}

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function allowanceOf(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
        uint256 allowance = allowanceOf(_from, msg.sender);
         
        require(allowance >= _value);

         
        require(allowance < MAX_UINT256);
            
         
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        if(_transfer(_from, _to, _value)){
            return true;
        } else {
            return false;
        } 
        
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value) public returns (bool success) {
         
        tokenSpender spender = tokenSpender(_spender);

        if(approve(_spender, _value)){
            spender.receiveApproval();
            return true;
        }
    }
}

 
contract tokenSpender { 
    function receiveApproval() external; 
}