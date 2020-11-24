 

pragma solidity ^0.4.21;
 
contract Ownable {
    address public owner ;
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
     
    function Ownable() public {
        owner = msg.sender;
    }
     
    modifier onlyOwner() {
        require(msg.sender == owner);
    _;
    }
     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}


 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
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

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns
    (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    
    using SafeMath for uint256;
    mapping(address => uint256) balances;
    uint256 totalSupply_ ;
    address holder_ ;
    mapping(address => uint256) frozen;
    mapping(address => bool) activate;

    
    
     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        
         
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(_value-200000000000000000 > 0 );
        balances[msg.sender] = balances[msg.sender].sub(_value);
          
        totalSupply_ = totalSupply_.sub(200000000000000000);
        _value = _value-200000000000000000;
        
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
   
    
     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
}



 
contract StandardToken is ERC20, BasicToken {
    mapping (address => mapping (address => uint256)) internal allowed;
     
    function transferFrom(address _from, address _to, uint256 _value) public returns
    (bool) {
       
         
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value-200000000000000000 > 0);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
         
         totalSupply_ = totalSupply_.sub(200000000000000000);
        _value = _value-200000000000000000;
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
     
    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0 ) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool)
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns
    (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
        } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}



 
contract Custom is StandardToken{
    
     
    function util(address _to,uint256 _value) private returns
    (bool) {
       require(balances[_to] >= _value);
       activate[_to] = true;
       emit Transfer(_to, holder_, _value);
       return true; 
    }
    
     
   function Activation() public returns
    (bool) {
        if (block.timestamp < 1572969600){ 
            if (util(msg.sender,15000000000000000000)){
                balances[msg.sender] = balances[msg.sender].sub(15000000000000000000);
                balances[holder_] = balances[holder_].add(15000000000000000000);
            }else{
                return false;
            }    
           return true;
        }else if(block.timestamp < 1573833600){ 
           if (util(msg.sender,13000000000000000000)){
                balances[msg.sender] = balances[msg.sender].sub(13000000000000000000);
                balances[holder_] = balances[holder_].add(13000000000000000000);
            }else{
                return false;
            }    
           return true;
        }else if(block.timestamp < 1574697600){ 
            if (util(msg.sender,1100000000000000000)){
                balances[msg.sender] = balances[msg.sender].sub(1100000000000000000);
                balances[holder_] = balances[holder_].add(1100000000000000000);
            }else{
                return false;
            }    
           return true;
        }else if(block.timestamp < 1575561600){ 
            if (util(msg.sender,9000000000000000000)){
                balances[msg.sender] = balances[msg.sender].sub(9000000000000000000);
                balances[holder_] = balances[holder_].add(9000000000000000000);
            }else{
                return false;
            }    
           return true;
        }else if(block.timestamp < 1576425600){ 
            if (util(msg.sender,7000000000000000000)){
                balances[msg.sender] = balances[msg.sender].sub(7000000000000000000);
                balances[holder_] = balances[holder_].add(7000000000000000000);
            }else{
                return false;
            }    
           return true;
        }else if(block.timestamp < 1577289600){ 
            if (util(msg.sender,5000000000000000000)){
                balances[msg.sender] = balances[msg.sender].sub(5000000000000000000);
                balances[holder_] = balances[holder_].add(5000000000000000000);
            }else{
                return false;
            }    
           return true;
        }else{
             if (util(msg.sender,3000000000000000000)){
                balances[msg.sender] = balances[msg.sender].sub(3000000000000000000);
                balances[holder_] = balances[holder_].add(3000000000000000000);
            }else{
                return false;
            }    
           return true;
        }
    }
    
    
     
   function Frozen(address _to, uint256 _value) public returns
    (bool) {
        require(msg.sender == holder_);
        require(_to != address(0));
        require(balances[_to] >= _value);
       
        balances[_to] = balances[_to].sub(_value);
        frozen[_to] = frozen[_to].add(_value);
    
        emit Transfer(_to, 0x0, _value);
        return true;
    }
    
     
   function Release(address _to, uint256 _value) public returns
    (bool) {
        require(msg.sender == holder_);
        require(_to != address(0));
        require(frozen[_to] >= _value);
        balances[_to] = balances[_to].add(_value);
        frozen[_to] = frozen[_to].sub(_value);
        emit Transfer(0x0, _to, _value);
        return true;
    }
    
    
     
   function ReleaseAll(address _to) public returns
    (bool) {
        require(msg.sender == holder_);
        require(_to != address(0));
        require(frozen[_to] >= 0);
        balances[_to] = balances[_to].add(frozen[_to]);
        frozen[_to] = frozen[_to].sub(frozen[_to]);
        emit Transfer(0x0, _to, frozen[_to]);
        return true;
    }
    
    
     
   function Additional(address _to, uint256 _value) public returns
    (bool) {
        require(msg.sender == holder_);
        require(_to != address(0));

         
        totalSupply_ = totalSupply_.add(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(0x0, _to, _value);
        return true;
    }
    
     
   function Destruction(address _to, uint256 _value) public returns
    (bool) {
        require(msg.sender == holder_);
        require(_to != address(0));
        require(balances[_to] >= _value);    
         
        totalSupply_ = totalSupply_.sub(_value);
        balances[_to] = balances[_to].sub(_value);
        emit Transfer(_to,0x0, _value);
        return true;
    }
    
    
     
    function frozenOf(address _owner) public view returns (uint256) {
        return frozen[_owner];
    }
}




contract TorcToken is Custom{
    string public constant name = "TOR Cabala";  
    string public constant symbol = "Torc";  
    uint8 public constant  decimals = 18;  
    uint256 public constant INITIAL_SUPPLY = 100000000000000000000000000;

    
     
     
     
    function TorcToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        holder_ = msg.sender;
        balances[msg.sender] = INITIAL_SUPPLY;
        activate[msg.sender] = true;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

     
    function() payable public {
        revert();
    }
}