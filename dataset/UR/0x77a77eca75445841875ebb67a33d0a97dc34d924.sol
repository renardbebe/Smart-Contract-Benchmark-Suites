 

pragma solidity ^0.4.11;

 
contract IOwned {
     
    function owner() public constant returns (address owner) { owner; }

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
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

 
contract IERC20Token {
     
    function name() public constant returns (string name) { name; }
    function symbol() public constant returns (string symbol) { symbol; }
    function decimals() public constant returns (uint8 decimals) { decimals; }
    function totalSupply() public constant returns (uint256 totalSupply) { totalSupply; }
    function balanceOf(address _owner) public constant returns (uint256 balance) { _owner; balance; }
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) { _owner; _spender; remaining; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

 
contract ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
}

 
contract TokenHolder is ITokenHolder, Owned {
     
    function TokenHolder() {
    }

     
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

     
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        assert(_token.transfer(_to, _amount));
    }
}

 
contract ITokenChanger {
    function changeableTokenCount() public constant returns (uint16 count);
    function changeableToken(uint16 _tokenIndex) public constant returns (address tokenAddress);
    function getReturn(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount) public constant returns (uint256 amount);
    function change(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256 amount);
}

 
contract ISmartToken is ITokenHolder, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

 
contract IBancorChanger is ITokenChanger {
    function token() public constant returns (ISmartToken _token) { _token; }
    function getReserveBalance(IERC20Token _reserveToken) public constant returns (uint256 balance);
}

 
contract IEtherToken is ITokenHolder, IERC20Token {
    function deposit() public payable;
    function withdraw(uint256 _amount) public;
}

 
contract BancorBuyer is TokenHolder {
    string public version = '0.1';
    IBancorChanger public tokenChanger;  
    IEtherToken public etherToken;       

     
    function BancorBuyer(IBancorChanger _changer, IEtherToken _etherToken)
        validAddress(_changer)
        validAddress(_etherToken)
    {
        tokenChanger = _changer;
        etherToken = _etherToken;

         
        tokenChanger.getReserveBalance(etherToken);
    }

     
    function buy() public payable returns (uint256 amount) {
        etherToken.deposit.value(msg.value)();  
        assert(etherToken.approve(tokenChanger, 0));  
        assert(etherToken.approve(tokenChanger, msg.value));  

        ISmartToken smartToken = tokenChanger.token();
        uint256 returnAmount = tokenChanger.change(etherToken, smartToken, msg.value, 1);  
        assert(smartToken.transfer(msg.sender, returnAmount));  
        return returnAmount;
    }

     
    function() payable {
        buy();
    }
}