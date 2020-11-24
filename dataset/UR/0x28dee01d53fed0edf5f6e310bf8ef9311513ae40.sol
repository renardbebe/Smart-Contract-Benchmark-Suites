 

pragma solidity 0.4.19;

contract BaseContract {
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);

        _;
    }

    modifier isZero(uint256 _amount) {
        require(_amount == 0);

        _;
    }

    modifier nonZero(uint256 _amount) {
        require(_amount != 0);

        _;
    }

    modifier notThis(address _address) {
        require(_address != address(this));

        _;
    }

    modifier onlyIf(bool condition) {
        require(condition);

        _;
    }

    modifier validIndex(uint256 arrayLength, uint256 index) {
        requireValidIndex(arrayLength, index);

        _;
    }

    modifier validAddress(address _address) {
        require(_address != 0x0);

        _;
    }

    modifier validString(string value) {
        require(bytes(value).length > 0);

        _;
    }

     
     
    modifier validParamData(uint256 numParams) {
        uint256 expectedDataLength = (numParams * 32) + 4;
        assert(msg.data.length >= expectedDataLength);

        _;
    }

    function requireValidIndex(uint256 arrayLength, uint256 index)
        internal
        pure
    {
        require(index >= 0 && index < arrayLength);
    }
}

contract Owned is BaseContract {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    function Owned()
        internal
    {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);

        _;
    }

     
     
     
     
    function transferOwnership(address _newOwner)
        public
        validParamData(1)
        onlyOwner
        onlyIf(_newOwner != owner)
    {
        newOwner = _newOwner;
    }

     
    function acceptOwnership()
        public
        onlyIf(msg.sender == newOwner)
    {
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}


contract IToken { 
    function totalSupply()
        public view
        returns (uint256);

    function balanceOf(address _owner)
        public view
        returns (uint256);

    function transfer(address _to, uint256 _value)
        public
        returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool);

    function approve(address _spender, uint256 _value)
        public
        returns (bool);

    function allowance(address _owner, address _spender)
        public view
        returns (uint256);
}








contract TokenRetriever is Owned {
    function TokenRetriever()
        internal
    {
    }

     
     
    function retrieveTokens(IToken _token)
        public
        onlyOwner
    {
        uint256 tokenBalance = _token.balanceOf(this);
        if (tokenBalance > 0) {
            _token.transfer(owner, tokenBalance);
        }
    }
}






 
library SafeMath {
    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        require(b > 0);  
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function min256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}


 

 
contract ERC20Token is BaseContract {
    using SafeMath for uint256;

    string public name = "";
    string public symbol = "";
    uint8 public decimals = 0;
    uint256 public totalSupply = 0;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
     
     
     
    function ERC20Token(string _name, string _symbol, uint8 _decimals)
        internal
        validString(_name)
        validString(_symbol)
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

     
     
     
     
     
    function transfer(address _to, uint256 _value)
        public
        validParamData(2)
        validAddress(_to)
        notThis(_to)
        returns (bool success)
    {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validParamData(3)
        validAddress(_from)
        validAddress(_to)
        notThis(_to)
        returns (bool success)
    {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
     
     
     
     
     
     
     
     
    function approve(address _spender, uint256 _value)
        public
        validParamData(2)
        validAddress(_spender)
        onlyIf(_value == 0 || allowance[msg.sender][_spender] == 0)
        returns (bool success)
    {
        uint256 currentAllowance = allowance[msg.sender][_spender];

        return changeApprovalCore(_spender, currentAllowance, _value);
    }

     
     
     
     
    function changeApproval(address _spender, uint256 _previousValue, uint256 _value)
        public
        validParamData(3)
        validAddress(_spender)
        returns (bool success)
    {
        return changeApprovalCore(_spender, _previousValue, _value);
    }

    function changeApprovalCore(address _spender, uint256 _previousValue, uint256 _value)
        private
        onlyIf(allowance[msg.sender][_spender] == _previousValue)
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        return true;
    }
}






contract XBPToken is BaseContract, Owned, TokenRetriever, ERC20Token {
    using SafeMath for uint256;

    bool public issuanceEnabled = true;

    event Issuance(uint256 _amount);

    function XBPToken()
        public
        ERC20Token("BlitzPredict", "XBP", 18)
    {
    }

     
     
    function disableIssuance()
        public
        onlyOwner
        onlyIf(issuanceEnabled)
    {
        issuanceEnabled = false;
    }

     
     
     
     
    function issue(address _to, uint256 _amount)
        public
        onlyOwner
        validParamData(2)
        validAddress(_to)
        onlyIf(issuanceEnabled)
        notThis(_to)
    {
        totalSupply = totalSupply.add(_amount);
        balanceOf[_to] = balanceOf[_to].add(_amount);

        Issuance(_amount);
        Transfer(this, _to, _amount);
    }
}