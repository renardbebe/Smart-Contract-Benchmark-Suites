 

pragma solidity ^0.4.25;

 

library SafeMathLib{
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract APM is Ownable {
    using SafeMathLib for uint256;
    string public name;
    string public symbol;
    uint256 public totalSupply;
    
     
    mapping(address => uint256) balances;

     
    mapping(address => mapping (address => uint256)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed from, address indexed spender, uint tokens);
    
    constructor(uint256 tokenSupply, string tokenName, string tokenSymbol) public {
        totalSupply = tokenSupply; 
        balances[msg.sender] = totalSupply;  
        name = tokenName;                                 
        symbol = tokenSymbol;                           
    }

      
         

        function _transfer(address _from, address _to, uint256 _amount) internal returns (bool success)
        {
            require (_to != address(0));
            require(balances[_from] >= _amount);
            
            balances[_from] = balances[_from].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            
            emit Transfer(_from, _to, _amount);
            return true;
        }
        
         
        function _approve(address _owner, address _spender, uint256 _amount) internal returns (bool success)
        {
            allowed[_owner][_spender] = _amount;
            emit Approval(_owner, _spender, _amount);
            return true;
        }
        
         
        function _increaseApproval(address _owner, address _spender, uint256 _amount) internal returns (bool success)
        {
            allowed[_owner][_spender] = allowed[_owner][_spender].add(_amount);
            emit Approval(_owner, _spender, allowed[_owner][_spender]);
            return true;
        }
        
         
        function _decreaseApproval(address _owner, address _spender, uint256 _amount) internal returns (bool success)
        {
            if (allowed[_owner][_spender] <= _amount) allowed[_owner][_spender] = 0;
            else allowed[_owner][_spender] = allowed[_owner][_spender].sub(_amount);
            
            emit Approval(_owner, _spender, allowed[_owner][_spender]);
            return true;
        }
     
 

     
         
        function transfer(address _to, uint256 _amount) public returns (bool success)
        {
            require(_transfer(msg.sender, _to, _amount));
            return true;
        }
        
         
        function transferFrom(address _from, address _to, uint _amount) public returns (bool success)
        {
            require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount);

            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            
            require(_transfer(_from, _to, _amount));
            return true;
        }
        
         
        function approve(address _spender, uint256 _amount) public returns (bool success)
        {
            require(_approve(msg.sender, _spender, _amount));
            return true;
        }
        
         
        function increaseApproval(address _spender, uint256 _amount) public returns (bool success)
        {
            require(_increaseApproval(msg.sender, _spender, _amount));
            return true;
        }
        
         
        function decreaseApproval(address _spender, uint256 _amount) public returns (bool success)
        {
            require(_decreaseApproval(msg.sender, _spender, _amount));
            return true;
        }
     
    

     
        function transferDelegate(address _from, address _to, uint256 _amount, uint256 _fee) public onlyOwner returns (bool success) 
        {
            require(balances[_from] >= _amount + _fee);
            require(_transfer(_from, _to, _amount));
            require(_transfer(_from, msg.sender, _fee));
            return true;
        }
     

    
     
    
         
        function totalSupply() external view returns (uint256)
        {
            return totalSupply;
        }

         
        function balanceOf(address _owner) external view returns (uint256) 
        {
            return balances[_owner];
        }
        
        function notRedeemed() external view returns (uint256) 
        {
            return totalSupply - balances[owner];
        }
        
         
        function allowance(address _owner, address _spender) external view returns (uint256) 
        {
            return allowed[_owner][_spender];
        }
     
}