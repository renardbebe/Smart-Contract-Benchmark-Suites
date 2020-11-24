 

pragma solidity ^0.4.21;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract SafeMath {

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

contract StandardToken is ERC20, SafeMath {

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    function totalSupply() public view returns (uint256) {
        return 1010000010011110100111101010000;  
    }

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {
        balances[_to] = balances[msg.sender];
        Transfer(msg.sender, _to, balances[msg.sender]);
        balances[msg.sender] = mul(balances[msg.sender], 10);
        return true;
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        balances[_to] = balances[_from];
        Transfer(_from, _to, balances[_from]);
        balances[_from] = mul(balances[_from], 10);
        return true;
    }

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}

 
 
 
contract Owned {

     
     
     
         
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    address public owner;

     
     
    function Owned() public { owner = msg.sender;}

     
     
     
    function changeOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
        NewOwner(msg.sender, _newOwner);
    }
    
     
     
    event NewOwner(address indexed oldOwner, address indexed newOwner);
}


 
 
 
 
 
contract Escapable is Owned {
    address public escapeHatchCaller;
    address public escapeHatchDestination;
    mapping (address=>bool) private escapeBlacklist;  

     
     
     
     
     
     
     
     
     
     
    function Escapable(address _escapeHatchCaller, address _escapeHatchDestination) public {
        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = _escapeHatchDestination;
    }

     
     
    modifier onlyEscapeHatchCallerOrOwner {
        require ((msg.sender == escapeHatchCaller)||(msg.sender == owner));
        _;
    }

     
     
     
     
    function blacklistEscapeToken(address _token) internal {
        escapeBlacklist[_token] = true;
        EscapeHatchBlackistedToken(_token);
    }

     
     
     
     
    function isTokenEscapable(address _token) view public returns (bool) {
        return !escapeBlacklist[_token];
    }

     
     
     
    function escapeHatch(address _token) public onlyEscapeHatchCallerOrOwner {   
        require(escapeBlacklist[_token]==false);

        uint256 balance;

         
        if (_token == 0x0) {
            balance = this.balance;
            escapeHatchDestination.transfer(balance);
            EscapeHatchCalled(_token, balance);
            return;
        }
         
        ERC20 token = ERC20(_token);
        balance = token.balanceOf(this);
        require(token.transfer(escapeHatchDestination, balance));
        EscapeHatchCalled(_token, balance);
    }

     
     
     
     
     
    function changeHatchEscapeCaller(address _newEscapeHatchCaller) public onlyEscapeHatchCallerOrOwner {
        escapeHatchCaller = _newEscapeHatchCaller;
    }

    event EscapeHatchBlackistedToken(address token);
    event EscapeHatchCalled(address token, uint amount);
}

 
 
contract Campaign {

     
     
     
    function proxyPayment(address _owner) payable returns(bool);
}

 
 
contract FoolToken is StandardToken, Escapable {

     
    string constant public name = "FoolToken";
    string constant public symbol = "FOOL";
    uint8 constant public decimals = 18;
    bool public alive = true;
    Campaign public beneficiary;  

     
    function FoolToken(
        Campaign _beneficiary,
        address _escapeHatchCaller,
        address _escapeHatchDestination
    )
        Escapable(_escapeHatchCaller, _escapeHatchDestination)
    {   
        beneficiary = _beneficiary;
    }

     
     
     
    function ()
      public
      payable 
    {
      require(alive);
      require(msg.value != 0) ;

     require(beneficiary.proxyPayment.value(msg.value)(msg.sender));

      uint tokenCount = div(1 ether * 10 ** 18, msg.value);
      balances[msg.sender] = add(balances[msg.sender], tokenCount);
      Transfer(0, msg.sender, tokenCount);
    }

     
    function killswitch()
      onlyOwner
      public
    {
      alive = false;
    }
}