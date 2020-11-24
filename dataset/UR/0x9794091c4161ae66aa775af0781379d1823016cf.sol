 

library SafeMath
{
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function GET_MAX_UINT256() pure internal returns(uint256){
        return MAX_UINT256;
    }

    function mul(uint a, uint b) internal returns(uint){
        uint c = a * b;
        assertSafe(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) pure internal returns(uint){
         
        uint c = a / b;
         
        return c;
    }

    function sub(uint a, uint b) internal returns(uint){
        assertSafe(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal returns(uint){
        uint c = a + b;
        assertSafe(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal view returns(uint64){
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal view returns(uint64){
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal view returns(uint256){
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal view returns(uint256){
        return a < b ? a : b;
    }

    function assertSafe(bool assertion) internal {
        if (!assertion) {
            revert();
        }
    }
}


contract ERC223Interface {
      
    function balanceOf(address _who) view public returns (uint);
    function transfer(address _to, uint _value) public returns (bool success);
    function transfer(address _to, uint _value, bytes _data) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function totalSupply() public view returns (uint256 supply);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Transfer(address indexed _from, address indexed _to, uint _value, bytes _data);
    event Approval(address indexed _from, address indexed _spender, uint256 _value);
    
}

contract ERC223Token is ERC223Interface {
    using SafeMath for uint;

    mapping(address => uint) balances;  
    mapping (address => mapping (address => uint256)) private allowances;
    
    uint256 public supply;
    
    function ERC223Token(uint256 _totalSupply) public
    {
        supply = _totalSupply;
    }       

     
    function transfer(address _to, uint _value, bytes _data) public returns (bool success){
         
         
        uint codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }

        emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer (msg.sender, _to, _value);

        return true;
    }
    
     
    function transfer(address _to, uint _value) public returns (bool success){
        uint codeLength;
        bytes memory empty;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }

        emit Transfer(msg.sender, _to, _value, empty);
        emit Transfer (msg.sender, _to, _value);

        return true;
    }

    
     
    function balanceOf(address _owner) view public returns (uint balance) {
        return balances[_owner];
    }

     

    function transferFrom (address _from, address _to, uint256 _value) public returns (bool success) {
        if (allowances [_from][msg.sender] < _value) return false;
        if (balances [_from] < _value) return false;

        allowances [_from][msg.sender] = allowances [_from][msg.sender].sub(_value);

        if (_value > 0 && _from != _to) {
            balances [_from] = balances [_from].sub(_value);
            balances [_to] = balances [_to].add(_value);
            emit Transfer (_from, _to, _value);
        }

        return true;
    }

    function approve (address _spender, uint256 _value) public returns (bool success) {
        allowances [msg.sender][_spender] = _value;
        emit Approval (msg.sender, _spender, _value);

        return true;
    }

    function allowance (address _owner, address _spender) view public returns (uint256 remaining) {
        return allowances [_owner][_spender];
    }
}

contract ERC223ReceivingContract { 
 
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract LykkeTokenErc223Base is ERC223Token {

    address internal _issuer;
    string public standard;
    string public name;
    string public symbol;
    uint8 public decimals;

    function LykkeTokenErc223Base(
        address issuer,
        string tokenName,
        uint8 divisibility,
        string tokenSymbol, 
        string version,
        uint256 totalSupply) ERC223Token(totalSupply) public{
        symbol = tokenSymbol;
        standard = version;
        name = tokenName;
        decimals = divisibility;
        _issuer = issuer;
    }
}

contract EmissiveErc223Token is LykkeTokenErc223Base {
    using SafeMath for uint;
    
    function EmissiveErc223Token(
        address issuer,
        string tokenName,
        uint8 divisibility,
        string tokenSymbol, 
        string version) LykkeTokenErc223Base(issuer, tokenName, divisibility, tokenSymbol, version, 0) public{
        balances [_issuer] = SafeMath.GET_MAX_UINT256();
    }

    function totalSupply () view public returns (uint256 supply) {
        return SafeMath.GET_MAX_UINT256().sub(balances [_issuer]);
    }

    function balanceOf (address _owner) view public returns (uint256 balance) {
        return _owner == _issuer ? 0 : ERC223Token.balanceOf (_owner);
    }
}

contract LyCI is EmissiveErc223Token {
    using SafeMath for uint;
    string public termsAndConditionsUrl;
    address public owner;

    function LyCI(
        address issuer,
        string tokenName,
        uint8 divisibility,
        string tokenSymbol, 
        string version) EmissiveErc223Token(issuer, tokenName, divisibility, tokenSymbol, version) public{
        owner = msg.sender;
    }

    function getTermsAndConditions () public view returns (string tc) {
        return termsAndConditionsUrl;
    }

    function setTermsAndConditions (string _newTc) public {
        if (msg.sender != owner){
            revert("Only owner is allowed to change T & C");
        }
        termsAndConditionsUrl = _newTc;
    }
}