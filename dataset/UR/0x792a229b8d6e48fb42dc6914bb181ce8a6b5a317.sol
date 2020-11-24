 

pragma solidity ^0.5.2;
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
library ExtendedMath {
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {
        if(a > b) return b;
        return a;
    }
}

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}
contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);
    constructor () public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract ReduxToken is ERC20Interface, Owned {
   
    using SafeMath for uint;
    using ExtendedMath for uint;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
address _ContractSwap;
    uint public _totalBurned;
uint public _BurnAmount;
uint public _BurnRate;
uint public _ProjectFund;
uint public _AfterBurn;
    bool locked = false;
        mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

constructor () public onlyOwner{
       symbol = "RDX";
       name = "Redux token";
       decimals = 8;
       _totalSupply = 5000000 * 10**uint(decimals);
       _BurnRate=1;
       if(locked) revert();
       locked = true;
       _ContractSwap=address(0x9971109C62171eAf008207cD16624FccA3A04727);
  balances[_ContractSwap] = _totalSupply;
       emit Transfer(address(0), _ContractSwap,_totalSupply);
     
      
    }
    function totalSupply() public view returns (uint) {

        return _totalSupply ;

    }
  function balanceOf(address tokenOwner) public view returns (uint balance) {

        return balances[tokenOwner];

    }



  

    function transfer(address to, uint _tokens) public returns (bool success) {
      require(balances[msg.sender] >= _tokens);
      _BurnAmount = _tokens / 10000;
      if (_tokens >= 10000000000) _BurnAmount = _tokens / 1000;
      if (_tokens > 100000000000) _BurnAmount = _tokens / 200;
      _BurnRate = _BurnAmount / 2;
      _ProjectFund = _BurnAmount / 2;
       if (_totalSupply < 50000000000000)  {
_BurnRate=0;
 _ProjectFund = _BurnAmount ;
}   
      balances[msg.sender] = balances[msg.sender].sub(_tokens);
      _AfterBurn=_tokens - _BurnAmount;  
      balances[_ContractSwap] = balances[_ContractSwap].add(_ProjectFund);
        balances[to] = balances[to].add(_AfterBurn);
        _totalSupply -= _BurnRate;                       
          

        
        emit Transfer(msg.sender, to, _AfterBurn);
        emit Transfer(msg.sender, _ContractSwap, _ProjectFund);


        return true;

    }

    function approve(address spender, uint tokens) public returns (bool success) {

        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        return true;

    }



  
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(balances[from] >= tokens);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
          _BurnAmount = tokens / 10000;
      if (tokens >= 10000000000) _BurnAmount = tokens / 1000;
      if (tokens >  100000000000) _BurnAmount = tokens / 200;
      _BurnRate = _BurnAmount / 2;
      _ProjectFund = _BurnAmount / 2;
       if (_totalSupply < 50000000000000)  {
_BurnRate=0;
 _ProjectFund = _BurnAmount ;
}   
        _AfterBurn=tokens - _BurnAmount;  
        balances[_ContractSwap] = balances[_ContractSwap].add(_ProjectFund);
        balances[to] = balances[to].add(_AfterBurn);
        _totalSupply -= _BurnRate;   
        emit Transfer(from, to, tokens);
        emit Transfer(from, _ContractSwap, _ProjectFund);

return true;

    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {

        return allowed[tokenOwner][spender];

    }

 
 
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {

        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

      ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);

        return true;

    }
   function () external payable {

        revert();

    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {

        return ERC20Interface(tokenAddress).transfer(owner, tokens);

    }

}