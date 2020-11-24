 

pragma solidity ^0.4.14;

 
contract IOwned {
     
    function owner() public constant { owner; }

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

 
contract IERC20Token {
     
    function name() public constant returns (string) {}
    function symbol() public constant returns (string) {}
    function decimals() public constant returns (uint8) {}
    function totalSupply() public constant returns (uint256) {}
    function balanceOf(address _owner) public constant returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public constant returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}


 
contract IToken is IOwned, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}


 
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

     
    function Owned() {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

 
contract Utils {
     
    function Utils() {
    }

     
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

     
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

     

     
    function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}


 
contract ERC20Token is IERC20Token, Utils {
    string public standard = "Token 0.1";
    string public name = "";
    string public symbol = "";
    uint8 public decimals = 0;
    uint256 public totalSupply = 0;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function ERC20Token(string _name, string _symbol, uint8 _decimals) {
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0);  

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

     
    function transfer(address _to, uint256 _value)
        public
        validAddress(_to)
        returns (bool success)
    {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
         
        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}


 
contract PAIReceipt is IToken, Owned, ERC20Token {
    string public version = "0.1";

    bool public transfersEnabled = true;     

     
    event NewPAIReceipt(address _token);
     
    event Issuance(uint256 _amount);
     
    event Destruction(uint256 _amount);

     
    function PAIReceipt()
        ERC20Token("Phantom AI Token Receipt", "PAIR", 18)
    {
        NewPAIReceipt(address(this));
    }

     
    modifier transfersAllowed {
        assert(transfersEnabled);
        _;
    }

     
    function disableTransfers(bool _disable) public ownerOnly {
        transfersEnabled = !_disable;
    }

     
    function issue(address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_to)
        notThis(_to)
    {
        totalSupply = safeAdd(totalSupply, _amount);
        balanceOf[_to] = safeAdd(balanceOf[_to], _amount);

        Issuance(_amount);
        Transfer(this, _to, _amount);
    }

     
    function destroy(address _from, uint256 _amount) public {
        require(msg.sender == _from || msg.sender == owner);  

        balanceOf[_from] = safeSub(balanceOf[_from], _amount);
        totalSupply = safeSub(totalSupply, _amount);

        Transfer(_from, this, _amount);
        Destruction(_amount);
    }

     

     
    function transfer(address _to, uint256 _value) public transfersAllowed returns (bool success) {
        assert(super.transfer(_to, _value));
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed returns (bool success) {
        assert(super.transferFrom(_from, _to, _value));
        return true;
    }
}


 
contract ReceiptIssuer is Owned {

    bool public isFinalized = false;
    bool public isDistributed = false;

     
    PAIReceipt public pair;

    uint256 public startTime = 1508554800;
    uint256 public endTime = 1512097200;
    address public fundingRecipient;
     

     

    event TokensIssued(address indexed _to, uint256 _amount);

     
     
     
    function ReceiptIssuer(address _token, address _fundingRecipient) {
        require(_token != address(0));
        require(_fundingRecipient != address(0));

        pair = PAIReceipt(_token);
         

        fundingRecipient = _fundingRecipient;
    }

     
    function finalize() external ownerOnly {
        if (isFinalized) {
            revert();
        }

         
        pair.disableTransfers(false);

        isFinalized = true;
    }

     
     
     
    function issueReceipts(address _recipient, uint256 _amount) public ownerOnly {

        pair.issue(_recipient, _amount);

        TokensIssued(_recipient, _amount);
    }

     
     
     
     
     
     
     
    function transferPAIReceiptOwnership(address _newOwnerCandidate) external ownerOnly {
        pair.transferOwnership(_newOwnerCandidate);
    }

     
     
    function acceptPAIReceiptOwnership() external ownerOnly {
        pair.acceptOwnership();
    }
}