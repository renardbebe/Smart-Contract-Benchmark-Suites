 

 

contract ERC865Plus677ish {
    event TransferAndCall(address indexed _from, address indexed _to, uint256 _value, bytes4 _methodName, bytes _args);
    function transferAndCall(address _to, uint256 _value, bytes4 _methodName, bytes memory _args) public returns (bytes memory);

    event TransferPreSigned(address indexed _from, address indexed _to, address indexed _delegate,
        uint256 _amount, uint256 _fee);
    event TransferAndCallPreSigned(address indexed _from, address indexed _to, address indexed _delegate,
        uint256 _amount, uint256 _fee, bytes4 _methodName, bytes _args);

    function transferPreSigned(bytes memory _signature, address _to, uint256 _value,
        uint256 _fee, uint256 _nonce) public returns (bool);
    function transferAndCallPreSigned(bytes memory _signature, address _to, uint256 _value,
        uint256 _fee, uint256 _nonce, bytes4 _methodName, bytes memory _args) public returns (bytes memory);
}

contract DOS is ERC20, ERC865Plus677ish {
    using SafeMath for uint256;

    string public constant name = "DOS Token";
    string public constant symbol = "DOS";
    uint8 public constant decimals = 18;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
     
    mapping(bytes => bool) private signatures;
    mapping(address => mapping (uint256 => bool)) private nonces;
    mapping(address => bool) private contractWhitelist;

    uint256 private totalSupply_;
    uint256 public constant maxSupply = 900000000 * (10 ** uint256(decimals));

     
    mapping(address => uint256) private lockups;

     
    address public owner;
    address public tmpOwner;
    address public admin1;
    address public admin2;

     
     
     
    bool public transfersEnabled1 = true;
    bool public transfersEnabled2 = true;
    bool public transfersEnabled3 = true;

     
    bool public mintingDone = false;

     
    uint256 public constant firstFeb19 = 1548979200;
    uint256 public constant sixMonth = 6 * 30 days;

    event TokensLocked(address indexed _holder, uint256 _timeout);

    constructor() public {
        owner = msg.sender;
    }

     
    function transferOwnership(address _newOwner) public {
        require(owner == msg.sender);
        require(_newOwner != address(0));
        require(_newOwner != admin1);
        require(_newOwner != admin2);
        require(_newOwner != owner);  

        tmpOwner = _newOwner;
    }

    function claimOwnership() public {
        require(tmpOwner == msg.sender);
        owner = tmpOwner;
        tmpOwner = address(0);
    }

    function setAdmin(address _admin1, address _admin2) public {
        require(owner == msg.sender);
        require(!mintingDone);
        require(_admin1 != address(0));
        require(_admin1 != owner);
        require(_admin2 != address(0));
        require(_admin2 != owner);
        require(_admin1 != _admin2);

        admin1 = _admin1;
        admin2 = _admin2;
    }

    function addWhitelist(address contractAddress) public {
        require(owner == msg.sender || admin1 == msg.sender || admin2 == msg.sender);

        contractWhitelist[contractAddress] = true;
    }

    function removeWhitelist(address contractAddress) public {
        require(owner == msg.sender || admin1 == msg.sender || admin2 == msg.sender);

        delete contractWhitelist[contractAddress];
    }

     
    function mint(address[] calldata _recipients, uint256[] calldata _amounts) external {
        require(owner == msg.sender);
        require(!mintingDone);
        require(_recipients.length == _amounts.length);
        require(_recipients.length <= 255);

        for (uint8 i = 0; i < _recipients.length; i++) {
            uint256 amount = _amounts[i];
            totalSupply_ = totalSupply_.add(amount);
            require(totalSupply_ <= maxSupply);  

            address recipient = _recipients[i];
            balances[recipient] = balances[recipient].add(amount);

            emit Transfer(address(0), recipient, amount);
        }
    }

     
    function lockTokens(address[] calldata _holders, uint256[] calldata _sixMonthCliff) external {
        require(owner == msg.sender);
        require(!mintingDone);
        require(_holders.length == _sixMonthCliff.length);
        require(_holders.length <= 255);

        for (uint8 i = 0; i < _holders.length; i++) {
            address holder = _holders[i];
             
            require(lockups[holder] == 0);

            uint256 timeout = (_sixMonthCliff[i].mul(sixMonth)).add(firstFeb19);

            lockups[holder] = timeout;
            emit TokensLocked(holder, timeout);
        }
    }

     
     
     
    function finishMinting() public {
        require(owner == msg.sender);
        require(!mintingDone);
        require(admin1 != address(0));
        require(admin2 != address(0));

        mintingDone = true;
    }

    function transferDisable() public {
        if(msg.sender == owner) {
            transfersEnabled1 = false;
        } else if(msg.sender == admin1) {
            transfersEnabled2 = false;
        } else if(msg.sender == admin2) {
            transfersEnabled3 = false;
        } else {
            revert();
        }
    }

    function isTransferEnabled() public view returns (bool) {
         
        return transfersEnabled1 || transfersEnabled2 || transfersEnabled3;
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value, 0, address(0));
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _transfer(_from, _to, _value, 0, address(0));
        _approve(_from, msg.sender, allowed[_from][msg.sender].sub(_value));
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value, uint256 _fee, address _feeAddress) internal {
        require(isTransferEnabled());
        require(_to != address(0));
        require(_to != address(this));
        uint256 total = _value.add(_fee);
        require(mintingDone);
        require(now >= lockups[_from]);  
        require(total <= balances[_from]);

        balances[_from] = balances[_from].sub(total);

        if(_fee > 0 && _feeAddress != address(0)) {
            balances[_feeAddress] = balances[_feeAddress].add(_fee);
        }

        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }


     
    function approve(address _spender, uint256 _value) public returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        _approve(msg.sender, _spender, allowed[msg.sender][_spender].add(_addedValue));
        return true;
    }

     
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        _approve(msg.sender, _spender, allowed[msg.sender][_spender].sub(_subtractedValue));
        return true;
    }

     
    function _approve(address _owner, address _spender, uint256 _value) internal {
        require(_spender != address(0));
        require(_owner != address(0));

        allowed[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }

    function transferAndCall(address _to, uint256 _value, bytes4 _methodName, bytes memory _args) public returns (bytes memory) {
        require(contractWhitelist[_to]);
        require(transfer(_to, _value));

        emit TransferAndCall(msg.sender, _to, _value, _methodName, _args);

         
        require(Utils.isContract(_to));

        (bool success, bytes memory data) = _to.call(abi.encodePacked(abi.encodeWithSelector(_methodName, msg.sender, _value), _args));
        require(success);
        return data;
    }

     
     
     
    function transferPreSigned(bytes memory _signature, address _to, uint256 _value, uint256 _fee, uint256 _nonce) public returns (bool) {

        require(!signatures[_signature]);
        bytes32 hashedTx = Utils.transferPreSignedHashing(address(this), _to, _value, _fee, _nonce);
        address from = Utils.recover(hashedTx, _signature);

        require(from != address(0));
        require(!nonces[from][_nonce]);

        _transfer(from, _to, _value, _fee, msg.sender);
        signatures[_signature] = true;
        nonces[from][_nonce] = true;

        emit Transfer(from, msg.sender, _fee);
        emit TransferPreSigned(from, _to, msg.sender, _value, _fee);
        return true;
    }

     
     
    function transferAndCallPreSigned(bytes memory _signature, address _to, uint256 _value, uint256 _fee, uint256 _nonce,
        bytes4 _methodName, bytes memory _args) public returns (bytes memory) {

        require(contractWhitelist[_to]);
        require(!signatures[_signature]);
        bytes32 hashedTx = Utils.transferAndCallPreSignedHashing(address(this), _to, _value, _fee, _nonce, _methodName, _args);
        address from = Utils.recover(hashedTx, _signature);

        require(from != address(0));
        require(!nonces[from][_nonce]);

        _transfer(from, _to, _value, _fee, msg.sender);
        signatures[_signature] = true;
        nonces[from][_nonce] = true;

        emit Transfer(from, msg.sender, _fee);
        emit TransferAndCallPreSigned(from, _to, msg.sender, _value, _fee, _methodName, _args);

         
        require(Utils.isContract(_to));

         
        (bool success, bytes memory data) = _to.call(abi.encodePacked(abi.encodeWithSelector(_methodName, from, _value), _args));
        require(success);
        return data;
    }
}
