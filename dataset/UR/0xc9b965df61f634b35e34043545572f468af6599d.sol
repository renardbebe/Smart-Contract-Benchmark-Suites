 

pragma solidity >0.5.0;
 
 
 
 
 
 
 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
    
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a>b) return a;
        return b;
    }
}
contract ERC20RcvContract { 
    function tokenFallback(address _from, uint _value) public;
}

contract ERC20  {

    using SafeMath for uint;

     
     
    function isContract(address _addr) private view returns (bool) {
        uint length;
         assembly {
              
             length := extcodesize(_addr)
         }
         return (length>0);
    }
 
     
     
     
    function transfer(address _to, uint _value) public returns (bool){

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(isContract(_to)) {
            ERC20RcvContract receiver = ERC20RcvContract(_to);
            receiver.tokenFallback(msg.sender, _value);
        }
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool){

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        if(isContract(_to)) {
            ERC20RcvContract receiver = ERC20RcvContract(_to);
            receiver.tokenFallback(msg.sender, _value);
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

     
     
     
     
    function approve(address _spender, uint _value) public returns (bool){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract TenToken is ERC20 { 

    string public symbol="GDEM";       
    string public name ="TEN Token";

    uint8 public decimals=6;          
    address public walletOwner;

    constructor() public 
    {
        totalSupply = 10**9 * (10**6);   
        balances[msg.sender] = totalSupply;               
        walletOwner = msg.sender;
         
         
        emit Transfer(0x0000000000000000000000000000000000000000, walletOwner, totalSupply);
    }

     
    function() external payable {
        revert();
    }
}