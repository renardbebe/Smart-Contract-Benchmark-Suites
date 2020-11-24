 

pragma solidity ^0.4.25;

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}
contract TokenRecoverable is Ownable {
    using SafeERC20 for ERC20Basic;

    function recoverTokens(ERC20Basic token, address to, uint256 amount) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount);
        token.safeTransfer(to, amount);
    }
}
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract ERC820Registry {
    function getManager(address addr) public view returns(address);
    function setManager(address addr, address newManager) public;
    function getInterfaceImplementer(address addr, bytes32 iHash) public constant returns (address);
    function setInterfaceImplementer(address addr, bytes32 iHash, address implementer) public;
}


contract ERC820Implementer {
    ERC820Registry erc820Registry = ERC820Registry(0x991a1bcb077599290d7305493c9A630c20f8b798);

    function setInterfaceImplementation(string ifaceLabel, address impl) internal {
        bytes32 ifaceHash = keccak256(abi.encodePacked(ifaceLabel));
        erc820Registry.setInterfaceImplementer(this, ifaceHash, impl);
    }

    function interfaceAddr(address addr, string ifaceLabel) internal constant returns(address) {
        bytes32 ifaceHash = keccak256(abi.encodePacked(ifaceLabel));
        return erc820Registry.getInterfaceImplementer(addr, ifaceHash);
    }

    function delegateManagement(address newManager) internal {
        erc820Registry.setManager(this, newManager);
    }
}

contract ERC20Token {
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);
    function totalSupply() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function transfer(address to, uint256 amount) public returns (bool);
    function transferFrom(address from, address to, uint256 amount) public returns (bool);
    function approve(address spender, uint256 amount) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);

     
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

contract ERC777Token {
    function name() public view returns (string);
    function symbol() public view returns (string);
    function totalSupply() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function granularity() public view returns (uint256);

    function defaultOperators() public view returns (address[]);
    function isOperatorFor(address operator, address tokenHolder) public view returns (bool);
    function authorizeOperator(address operator) public;
    function revokeOperator(address operator) public;

    function send(address to, uint256 amount, bytes holderData) public;
    function operatorSend(address from, address to, uint256 amount, bytes holderData, bytes operatorData) public;

    function burn(uint256 amount, bytes holderData) public;
    function operatorBurn(address from, uint256 amount, bytes holderData, bytes operatorData) public;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes holderData,
        bytes operatorData
    );  
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes holderData, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}


contract ERC777TokensRecipient {
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint amount,
        bytes userData,
        bytes operatorData
    ) public;
}


contract ERC777TokensSender {
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint amount,
        bytes userData,
        bytes operatorData
    ) public;
}

contract ERC777BaseToken is ERC777Token, ERC820Implementer {
    using SafeMath for uint256;

    string internal mName;
    string internal mSymbol;
    uint256 internal mGranularity;
    uint256 internal mTotalSupply;


    mapping(address => uint) internal mBalances;
    mapping(address => mapping(address => bool)) internal mAuthorized;

    address[] internal mDefaultOperators;
    mapping(address => bool) internal mIsDefaultOperator;
    mapping(address => mapping(address => bool)) internal mRevokedDefaultOperator;

     
     
     
     
     
     
    constructor(string _name, string _symbol, uint256 _granularity, address[] _defaultOperators) internal {
        mName = _name;
        mSymbol = _symbol;
        mTotalSupply = 0;
        require(_granularity >= 1);
        mGranularity = _granularity;

        mDefaultOperators = _defaultOperators;
        for (uint i = 0; i < mDefaultOperators.length; i++) { mIsDefaultOperator[mDefaultOperators[i]] = true; }

        setInterfaceImplementation("ERC777Token", this);
    }

     
     
     
    function name() public view returns (string) { return mName; }

     
    function symbol() public view returns (string) { return mSymbol; }

     
    function granularity() public view returns (uint256) { return mGranularity; }

     
    function totalSupply() public view returns (uint256) { return mTotalSupply; }

     
     
     
    function balanceOf(address _tokenHolder) public view returns (uint256) { return mBalances[_tokenHolder]; }

     
     
    function defaultOperators() public view returns (address[]) { return mDefaultOperators; }

     
     
     
    function send(address _to, uint256 _amount, bytes _userData) public {
        doSend(msg.sender, msg.sender, _to, _amount, _userData, "", true);
    }

     
     
    function authorizeOperator(address _operator) public {
        require(_operator != msg.sender);
        if (mIsDefaultOperator[_operator]) {
            mRevokedDefaultOperator[_operator][msg.sender] = false;
        } else {
            mAuthorized[_operator][msg.sender] = true;
        }
        emit AuthorizedOperator(_operator, msg.sender);
    }

     
     
    function revokeOperator(address _operator) public {
        require(_operator != msg.sender);
        if (mIsDefaultOperator[_operator]) {
            mRevokedDefaultOperator[_operator][msg.sender] = true;
        } else {
            mAuthorized[_operator][msg.sender] = false;
        }
        emit RevokedOperator(_operator, msg.sender);
    }

     
     
     
     
    function isOperatorFor(address _operator, address _tokenHolder) public view returns (bool) {
        return (_operator == _tokenHolder
            || mAuthorized[_operator][_tokenHolder]
            || (mIsDefaultOperator[_operator] && !mRevokedDefaultOperator[_operator][_tokenHolder]));
    }

     
     
     
     
     
     
    function operatorSend(address _from, address _to, uint256 _amount, bytes _userData, bytes _operatorData) public {
        require(isOperatorFor(msg.sender, _from));
        doSend(msg.sender, _from, _to, _amount, _userData, _operatorData, true);
    }

    function burn(uint256 _amount, bytes _holderData) public {
        doBurn(msg.sender, msg.sender, _amount, _holderData, "");
    }

    function operatorBurn(address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData) public {
        require(isOperatorFor(msg.sender, _tokenHolder));
        doBurn(msg.sender, _tokenHolder, _amount, _holderData, _operatorData);
    }

     
     
     
     
    function requireMultiple(uint256 _amount) internal view {
        require(_amount.div(mGranularity).mul(mGranularity) == _amount);
    }

     
     
     
    function isRegularAddress(address _addr) internal view returns(bool) {
        if (_addr == 0) { return false; }
        uint size;
        assembly { size := extcodesize(_addr) }  
        return size == 0;
    }

     
     
     
     
     
     
     
     
     
     
     
    function doSend(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData,
        bool _preventLocking
    )
        internal
    {
        requireMultiple(_amount);

        callSender(_operator, _from, _to, _amount, _userData, _operatorData);

        require(_to != address(0));           
        require(mBalances[_from] >= _amount);  

        mBalances[_from] = mBalances[_from].sub(_amount);
        mBalances[_to] = mBalances[_to].add(_amount);

        callRecipient(_operator, _from, _to, _amount, _userData, _operatorData, _preventLocking);

        emit Sent(_operator, _from, _to, _amount, _userData, _operatorData);
    }

     
     
     
     
     
     
    function doBurn(address _operator, address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData)
        internal
    {
        requireMultiple(_amount);
        require(balanceOf(_tokenHolder) >= _amount);

        mBalances[_tokenHolder] = mBalances[_tokenHolder].sub(_amount);
        mTotalSupply = mTotalSupply.sub(_amount);

        callSender(_operator, _tokenHolder, 0x0, _amount, _holderData, _operatorData);
        emit Burned(_operator, _tokenHolder, _amount, _holderData, _operatorData);
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function callRecipient(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData,
        bool _preventLocking
    )
        internal
    {
        address recipientImplementation = interfaceAddr(_to, "ERC777TokensRecipient");
        if (recipientImplementation != 0) {
            ERC777TokensRecipient(recipientImplementation).tokensReceived(
                _operator, _from, _to, _amount, _userData, _operatorData);
        } else if (_preventLocking) {
            require(isRegularAddress(_to));
        }
    }

     
     
     
     
     
     
     
     
     
     
    function callSender(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData
    )
        internal
    {
        address senderImplementation = interfaceAddr(_from, "ERC777TokensSender");
        if (senderImplementation == 0) { return; }
        ERC777TokensSender(senderImplementation).tokensToSend(_operator, _from, _to, _amount, _userData, _operatorData);
    }
}


contract ERC777ERC20BaseToken is ERC20Token, ERC777BaseToken {
    bool internal mErc20compatible;

    mapping(address => mapping(address => bool)) internal mAuthorized;
    mapping(address => mapping(address => uint256)) internal mAllowed;

    constructor(
        string _name,
        string _symbol,
        uint256 _granularity,
        address[] _defaultOperators
    )
        internal ERC777BaseToken(_name, _symbol, _granularity, _defaultOperators)
    {
        mErc20compatible = true;
        setInterfaceImplementation("ERC20Token", this);
    }

     
     
     
    modifier erc20 () {
        require(mErc20compatible);
        _;
    }

     
     
    function decimals() public erc20 view returns (uint8) { return uint8(18); }

     
     
     
     
    function transfer(address _to, uint256 _amount) public erc20 returns (bool success) {
        doSend(msg.sender, msg.sender, _to, _amount, "", "", false);
        return true;
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount) public erc20 returns (bool success) {
        require(_amount <= mAllowed[_from][msg.sender]);

         
        mAllowed[_from][msg.sender] = mAllowed[_from][msg.sender].sub(_amount);
        doSend(msg.sender, _from, _to, _amount, "", "", false);
        return true;
    }

     
     
     
     
     
    function approve(address _spender, uint256 _amount) public erc20 returns (bool success) {
        mAllowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
     
    function allowance(address _owner, address _spender) public erc20 view returns (uint256 remaining) {
        return mAllowed[_owner][_spender];
    }

    function doSend(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData,
        bool _preventLocking
    )
        internal
    {
        super.doSend(_operator, _from, _to, _amount, _userData, _operatorData, _preventLocking);
        if (mErc20compatible) { emit Transfer(_from, _to, _amount); }
    }

    function doBurn(address _operator, address _tokenHolder, uint256 _amount, bytes _holderData, bytes _operatorData)
        internal
    {
        super.doBurn(_operator, _tokenHolder, _amount, _holderData, _operatorData);
        if (mErc20compatible) { emit Transfer(_tokenHolder, 0x0, _amount); }
    }
}


 
library ECRecovery {

     
    function recover(bytes32 hash, bytes sig)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

         
        if (sig.length != 65) {
            return (address(0));
        }

         
         
         
         
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

         
        if (v < 27) {
            v += 27;
        }

         
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
         
            return ecrecover(hash, v, r, s);
        }
    }

     
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
         
         
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                hash
            )
        );
    }
}

contract FilesFMToken is TokenRecoverable, ERC777ERC20BaseToken {
    using SafeMath for uint256;
    using ECRecovery for bytes32;

    string private constant name_ = "Files.fm Token";
    string private constant symbol_ = "FFM";
    uint256 private constant granularity_ = 1;
    
    mapping(bytes => bool) private signatures;
    address public tokenMinter;
    address public tokenBag;
    bool public throwOnIncompatibleContract = true;
    bool public burnEnabled = false;
    bool public transfersEnabled = false;
    bool public defaultOperatorsComplete = false;

    event TokenBagChanged(address indexed oldAddress, address indexed newAddress, uint256 balance);
    event DefaultOperatorAdded(address indexed operator);
    event DefaultOperatorRemoved(address indexed operator);
    event DefaultOperatorsCompleted();

     
    constructor() public ERC777ERC20BaseToken(name_, symbol_, granularity_, new address[](0)) {
    }

    modifier canTransfer(address from, address to) {
        require(transfersEnabled || from == tokenBag || to == tokenBag);
        _;
    }

    modifier canBurn() {
        require(burnEnabled);
        _;
    }

    modifier hasMintPermission() {
        require(msg.sender == owner || msg.sender == tokenMinter, "Only owner or token minter can mint tokens");
        _;
    }

    modifier canManageDefaultOperator() {
        require(!defaultOperatorsComplete, "Default operator list is not editable");
        _;
    }

     
     
    function disableERC20() public onlyOwner {
        mErc20compatible = false;
        setInterfaceImplementation("ERC20Token", 0x0);
    }

     
     
    function enableERC20() public onlyOwner {
        mErc20compatible = true;
        setInterfaceImplementation("ERC20Token", this);
    }

    function send(address _to, uint256 _amount, bytes _userData) public canTransfer(msg.sender, _to) {
        super.send(_to, _amount, _userData);
    }

    function operatorSend(
        address _from, 
        address _to, 
        uint256 _amount, 
        bytes _userData, 
        bytes _operatorData) public canTransfer(_from, _to) {
        super.operatorSend(_from, _to, _amount, _userData, _operatorData);
    }

    function transfer(address _to, uint256 _amount) public erc20 canTransfer(msg.sender, _to) returns (bool success) {
        return super.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public erc20 canTransfer(_from, _to) returns (bool success) {
        return super.transferFrom(_from, _to, _amount);
    }

     
     
     
     
     
     
     
    function mint(address _tokenHolder, uint256 _amount, bytes _operatorData) public hasMintPermission {
        doMint(_tokenHolder, _amount, _operatorData);
    }

    function mintToken(address _tokenHolder, uint256 _amount) public hasMintPermission {
        doMint(_tokenHolder, _amount, "");
    }

    function mintTokens(address[] _tokenHolders, uint256[] _amounts) public hasMintPermission {
        require(_tokenHolders.length > 0 && _tokenHolders.length <= 100);
        require(_tokenHolders.length == _amounts.length);

        for (uint256 i = 0; i < _tokenHolders.length; i++) {
            doMint(_tokenHolders[i], _amounts[i], "");
        }
    }

     
     
     
    function burn(uint256 _amount, bytes _holderData) public canBurn {
        super.burn(_amount, _holderData);
    }

    function permitTransfers() public onlyOwner {
        require(!transfersEnabled);
        transfersEnabled = true;
    }

    function setThrowOnIncompatibleContract(bool _throwOnIncompatibleContract) public onlyOwner {
        throwOnIncompatibleContract = _throwOnIncompatibleContract;
    }

    function permitBurning(bool _enable) public onlyOwner {
        burnEnabled = _enable;
    }

    function completeDefaultOperators() public onlyOwner canManageDefaultOperator {
        defaultOperatorsComplete = true;
        emit DefaultOperatorsCompleted();
    }

    function setTokenMinter(address _tokenMinter) public onlyOwner {
        tokenMinter = _tokenMinter;
    }

    function setTokenBag(address _tokenBag) public onlyOwner {
        uint256 balance = mBalances[tokenBag];
        
        if (_tokenBag == address(0)) {
            require(balance == 0, "Token Bag balance must be 0");
        } else if (balance > 0) {
            doSend(msg.sender, tokenBag, _tokenBag, balance, "", "", false);
        }

        emit TokenBagChanged(tokenBag, _tokenBag, balance);
        tokenBag = _tokenBag;
    }
    
    function renounceOwnership() public onlyOwner {
        tokenMinter = address(0);
        super.renounceOwnership();
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        tokenMinter = address(0);
        super.transferOwnership(_newOwner);
    }

     
     
     
     
     
     
     
     
    function sendWithSignature(address _to, uint256 _amount, uint256 _fee, bytes _data, uint256 _nonce, bytes _sig) public returns (bool) {
        doSendWithSignature(_to, _amount, _fee, _data, _nonce, _sig, true);
        return true;
    }

     
     
     
     
     
     
     
     
    function transferWithSignature(address _to, uint256 _amount, uint256 _fee, bytes _data, uint256 _nonce, bytes _sig) public returns (bool) {
        doSendWithSignature(_to, _amount, _fee, _data, _nonce, _sig, false);
        return true;
    }

    function addDefaultOperator(address _operator) public onlyOwner canManageDefaultOperator {
        require(_operator != address(0), "Default operator cannot be set to address 0x0");
        require(mIsDefaultOperator[_operator] == false, "This is already default operator");
        mDefaultOperators.push(_operator);
        mIsDefaultOperator[_operator] = true;
        emit DefaultOperatorAdded(_operator);
    }

    function removeDefaultOperator(address _operator) public onlyOwner canManageDefaultOperator {
        require(mIsDefaultOperator[_operator] == true, "This operator is not default operator");
        uint256 operatorIndex;
        uint256 count = mDefaultOperators.length;
        for (operatorIndex = 0; operatorIndex < count; operatorIndex++) {
            if (mDefaultOperators[operatorIndex] == _operator) {
                break;
            }
        }
        if (operatorIndex + 1 < count) {
            mDefaultOperators[operatorIndex] = mDefaultOperators[count - 1];
        }
        mDefaultOperators.length = mDefaultOperators.length - 1;
        mIsDefaultOperator[_operator] = false;
        emit DefaultOperatorRemoved(_operator);
    }

    function doMint(address _tokenHolder, uint256 _amount, bytes _operatorData) private {
        require(_tokenHolder != address(0), "Cannot mint to address 0x0");
        requireMultiple(_amount);

        mTotalSupply = mTotalSupply.add(_amount);
        mBalances[_tokenHolder] = mBalances[_tokenHolder].add(_amount);

        callRecipient(msg.sender, address(0), _tokenHolder, _amount, "", _operatorData, false);

        emit Minted(msg.sender, _tokenHolder, _amount, _operatorData);
        if (mErc20compatible) { emit Transfer(address(0), _tokenHolder, _amount); }
    }

    function doSendWithSignature(address _to, uint256 _amount, uint256 _fee, bytes _data, uint256 _nonce, bytes _sig, bool _preventLocking) private {
        require(_to != address(0));
        require(_to != address(this));  

        require(signatures[_sig] == false);
        signatures[_sig] = true;

        bytes memory packed;
        if (_preventLocking) {
            packed = abi.encodePacked(address(this), _to, _amount, _fee, _data, _nonce);
        } else {
            packed = abi.encodePacked(address(this), _to, _amount, _fee, _data, _nonce, "ERC20Compat");
        }

        address signer = keccak256(packed)
            .toEthSignedMessageHash()
            .recover(_sig);  
        
        require(signer != address(0));
        require(transfersEnabled || signer == tokenBag || _to == tokenBag);

        uint256 total = _amount.add(_fee);
        require(mBalances[signer] >= total);

        doSend(msg.sender, signer, _to, _amount, _data, "", _preventLocking);
        if (_fee > 0) {
            doSend(msg.sender, signer, msg.sender, _fee, "", "", _preventLocking);
        }
    }

     
     
     
     
     
     
     
     
     
     
     
    function callRecipient(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes _userData,
        bytes _operatorData,
        bool _preventLocking
    ) internal {
        address recipientImplementation = interfaceAddr(_to, "ERC777TokensRecipient");
        if (recipientImplementation != 0) {
            ERC777TokensRecipient(recipientImplementation).tokensReceived(
                _operator, _from, _to, _amount, _userData, _operatorData);
        } else if (throwOnIncompatibleContract && _preventLocking) {
            require(isRegularAddress(_to));
        }
    }
}