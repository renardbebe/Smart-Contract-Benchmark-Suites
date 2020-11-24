 

pragma solidity ^0.4.25;

 


 
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


 
contract ECRecovery {
    function recover(bytes32 hash, bytes sig) public pure returns (address);
}


 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
contract ApproveAndCallFallBack {
    function approveAndCall(address spender, uint tokens, bytes data) public;
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
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


 
contract Zer0netDbInterface {
     
    function getAddress(bytes32 _key) external view returns (address);
    function getBool(bytes32 _key)    external view returns (bool);
    function getBytes(bytes32 _key)   external view returns (bytes);
    function getInt(bytes32 _key)     external view returns (int);
    function getString(bytes32 _key)  external view returns (string);
    function getUint(bytes32 _key)    external view returns (uint);

     
    function setAddress(bytes32 _key, address _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setBytes(bytes32 _key, bytes _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setString(bytes32 _key, string _value) external;
    function setUint(bytes32 _key, uint _value) external;

     
    function deleteAddress(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
}


 
contract WETHInterface {
    function() public payable;
    function deposit() public payable ;
    function withdraw(uint wad) public;
    function totalSupply() public view returns (uint);
    function approve(address guy, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
    function transferFrom(address src, address dst, uint wad) public returns (bool);

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);
}


 
contract ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}


 
 
 
 


 
contract ZeroCache is Owned {
    using SafeMath for uint;

     
    address private _predecessor;

     
    address private _successor;
    
     
    uint private _revision;

     
    Zer0netDbInterface private _zer0netDb;

     
    mapping(address => mapping (address => uint)) private _balances;

     
    mapping(bytes32 => bool) private _expiredSignatures;
    
     
     
     
     
     
    uint private _MAX_REVISION_DEPTH = 0;
    
    event Deposit(
        address indexed token, 
        address owner, 
        uint tokens,
        bytes data
    );

    event Migrate(
        address indexed token, 
        address owner, 
        uint tokens
    );

    event Skipped(
        address sender, 
        address receiver, 
        address token,
        uint tokens
    );

    event Staek(
        address sender, 
        address staekholder, 
        uint tokens
    );

    event Transfer(
        address indexed token, 
        address sender, 
        address receiver, 
        uint tokens
    );

    event Withdraw(
        address indexed token, 
        address owner, 
        uint tokens
    );
    
     
    constructor() public {
         
        _predecessor = 0x0;

         
        if (_predecessor != 0x0) {
             
            uint lastRevision = ZeroCache(_predecessor).getRevision();
            
             
            _revision = lastRevision + 1;
        }
        
         
         
        _zer0netDb = Zer0netDbInterface(0xE865Fe1A1A3b342bF0E2fcB11fF4E3BCe58263af);
    }

     
    modifier onlyAuthBy0Admin() {
         
        require(_zer0netDb.getBool(keccak256(
            abi.encodePacked(msg.sender, '.has.auth.for.zerocache'))) == true);

        _;       
    }

     
    function () public payable {
         
        bool isWethContract = false;
        
         
        address[4] memory contracts;
        
         
        contracts[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

         
        contracts[1] = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

         
        contracts[2] = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;

         
        contracts[3] = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        
         
        for (uint i = 0; i < contracts.length; i++) {
             
            if (msg.sender == contracts[i]) {
                 
                isWethContract = true;
            }
        }

         
        if (!isWethContract) {
            _wrap(msg.sender);
        }
    }


     

     
    function wrap() external payable returns (bool success) {
         
        return _wrap(msg.sender);
    }
    
     
    function wrap(
        address _owner
    ) external payable returns (bool success) {
        return _wrap(_owner);
    }

     
    function _wrap(
        address _owner
    ) private returns (bool success) {
         
        address wethAddress = _weth();

         
         
        success = wethAddress.call
            .gas(200000)
            .value(msg.value)
            (abi.encodeWithSignature("deposit()"));
            
         
        if (success) {
             
            _balances[wethAddress][_owner] = 
                _balances[wethAddress][_owner].add(msg.value);
            
             
            bytes memory data;
    
             
            emit Deposit(
                wethAddress, 
                _owner, 
                msg.value, 
                data
            );
        } else {
             
            revert('An error occurred while wrapping your ETH.');
        }
    }

     
    function unwrap(
        uint _tokens
    ) public returns (bool success) {
        return _unwrap(msg.sender, _tokens);
    }

     
    function unwrap(
        address _owner, 
        uint _tokens
    ) onlyAuthBy0Admin external returns (bool success) {
        return _unwrap(_owner, _tokens);
    }

     
    function _unwrap(
        address _owner, 
        uint _tokens
    ) private returns (bool success) {
         
        address wethAddress = _weth();

         
        if (_balances[wethAddress][_owner] < _tokens) {
            revert('Oops! You DO NOT have enough WETH.');
        }

         
         
        _balances[wethAddress][_owner] = 
            _balances[wethAddress][_owner].sub(_tokens);

         
        success = wethAddress.call
            .gas(200000)
            (abi.encodeWithSignature("withdraw(uint256)", _tokens));

         
        if (success) {
             
            _owner.transfer(_tokens);
    
             
            emit Withdraw(
                wethAddress,
                _owner,
                _tokens
            );
        } else {
             
            revert('An error occurred while unwrapping your ETH.');
        }
    }
    
     
    function deposit(
        address _token, 
        address _from, 
        uint _tokens, 
        bytes _data
    ) external returns (bool success) {
         
        return _deposit(_token, _from, _tokens, _data);
    }

     
    function receiveApproval(
        address _from, 
        uint _tokens, 
        address _token, 
        bytes _data
    ) public returns (bool success) {
         
        return _deposit(_token, _from, _tokens, _data);
    }

     
    function _deposit(
        address _token,
        address _from, 
        uint _tokens,
        bytes _data
    ) private returns (bool success) {
         
         
        ERC20Interface(_token).transferFrom(
            _from, address(this), _tokens);
        
         
        address receiver = 0x0;
        
         
        if (_data.length == 20) {
             
            receiver = _bytesToAddress(_data);
        } else {
             
            receiver = _from;
        }

         
        _balances[_token][receiver] = 
            _balances[_token][receiver].add(_tokens);

         
        emit Deposit(_token, receiver, _tokens, _data);

         
        return true;
    }

     
    function withdraw(
        address _token, 
        uint _tokens
    ) public returns (bool success) {
        return _withdraw(msg.sender, _token, _tokens);
    }
    
     
    function withdraw(
        address _owner, 
        address _token, 
        uint _tokens
    ) onlyAuthBy0Admin external returns (bool success) {
        return _withdraw(_owner, _token, _tokens);
    }

     
    function _withdraw(
        address _owner, 
        address _token, 
        uint _tokens
    ) private returns (bool success) {
         
        if (_balances[_token][_owner] < _tokens) {
            revert('Oops! You DO NOT have enough tokens.');
        }

         
         
        _balances[_token][_owner] = 
            _balances[_token][_owner].sub(_tokens);

         
        ERC20Interface(_token).transfer(_owner, _tokens);

         
        emit Withdraw(_token, _owner, _tokens);
    
         
        return true;
    }

     
    function transfer(
        address _to,
        address _token,
        uint _tokens
    ) external returns (bool success) {
        return _transfer(
            msg.sender, _to, _token, _tokens);
    }

     
    function transfer(
        address _token,        
        address _from,         
        address _to,           
        uint _tokens,          
        address _staekholder,  
        uint _staek,           
        uint _expires,         
        uint _nonce,           
        bytes _signature       
    ) external returns (bool success) {
         
        bytes32 transferHash = keccak256(abi.encodePacked(
            address(this), 
            _token, 
            _from,
            _to,
            _tokens,
            _staekholder,
            _staek,
            _expires,
            _nonce
        ));

         
        bool requestHasAuthSig = _requestHasAuthSig(
            _from,
            transferHash,
            _expires,
            _signature
        );
        
         
        if (!requestHasAuthSig) {
            revert('Oops! This relay request is NOT valid.');
        }
        
         
        if (_staekholder != 0x0 && _staek > 0) {
            _addStaek(_from, _staekholder, _staek);
        }

         
        return _transfer(
            _from, _to, _token, _tokens);
    }

     
    function _transfer(
        address _from,
        address _to,
        address _token,
        uint _tokens
    ) private returns (bool success) {
         
        if (_balances[_token][_from] < _tokens) {
            revert('Oops! You DO NOT have enough tokens.');
        }

         
         
        _balances[_token][_from] = _balances[_token][_from].sub(_tokens);

         
        _balances[_token][_to] = _balances[_token][_to].add(_tokens);

         
        emit Transfer(
            _token, 
            _from, 
            _to, 
            _tokens
        );

         
        return true;
    }
    
     
    function multiTransfer(
        address[] _to,
        address[] _token,
        uint[] _tokens
    ) external returns (bool success) {
        return _multiTransfer(msg.sender, _to, _token, _tokens);
    }
    
     
     
     
     
     

     
    function _multiTransfer(
        address _from,
        address[] _to,
        address[] _token,
        uint[] _tokens
    ) private returns (bool success) {
         
        for (uint i = 0; i < _to.length; i++) {
             
            address token = _token[i];
           
             
            uint tokens = _tokens[i];
           
             
            address to = _to[i];
            
             
            if (_ownerIsContract(to)) {
                 
                emit Skipped(_from, to, token, tokens);
            } else {
                 
                _transfer(
                    _from, to, token, tokens);
            }
        }
        
         
        return true;
    }

     
    function _addStaek(
        address _owner,
        address _staekholder,
        uint _tokens
    ) private returns (bool success) {
         
        address zgAddress = _zeroGold();

         
        if (_balances[zgAddress][_owner] < _tokens) {
            revert('Oops! You DO NOT have enough ZeroGold to staek.');
        }

         
         
        _balances[zgAddress][_owner] = 
            _balances[zgAddress][_owner].sub(_tokens);

         
        _zeroGold().transfer(_staekholder, _tokens);

         
        emit Staek(
            _owner, 
            _staekholder, 
            _tokens
        );

         
        return true;
    }

     
    function cancel(
        address _token,        
        address _from,         
        address _to,           
        uint _tokens,          
        address _staekholder,  
        uint _staek,           
        uint _expires,         
        uint _nonce,           
        bytes _signature       
    ) external returns (bool success) {
         
        bytes32 cancelHash = keccak256(abi.encodePacked(
            address(this), 
            _token, 
            _from,
            _to,
            _tokens,
            _staekholder,
            _staek,
            _expires,
            _nonce
        ));

         
        bool requestHasAuthSig = _requestHasAuthSig(
            _from,
            cancelHash,
            _expires,
            _signature
        );
        
         
        if (!requestHasAuthSig) {
            revert('Oops! This cancel request is NOT valid.');
        }
        
         
        return true;
    }

     
    function migrate(
        address[] _tokens
    ) external returns (bool success) {
        return _migrate(msg.sender, _tokens);
    }
    
     

     
    function _migrate(
        address _owner, 
        address[] _tokens
    ) private returns (bool success) {
         
        bytes32 hash = keccak256('aname.zerocache');

         
        address latestCache = _zer0netDb.getAddress(hash);

         
        for (uint i = 0; i < _tokens.length; i++) {
             
            address token = _tokens[i];
            
             
             
             
            uint balance = balanceOf(token, _owner, 0);
            
             
             
            _balances[token][_owner] = 0;

             
            if (token == address(_weth())) {
                 
                address wethAddress = _weth();
        
                 
                success = wethAddress.call
                    .gas(100000)
                    (abi.encodeWithSignature("withdraw(uint256)", balance));
        
                 
                 
                success = latestCache.call
                    .gas(100000)
                    .value(balance)
                    (abi.encodeWithSignature("wrap(address)", _owner));
            } else {
                 
                 
                 
                bytes memory data = abi.encodePacked(_owner);

                 
                 
                ApproveAndCallFallBack(token)
                    .approveAndCall(latestCache, balance, data);

                 
                success = true;
            }

             
            emit Migrate(token, _owner, balance);
        }
    }
    

     

     
    function getRevision() public view returns (uint) {
        return _revision;
    }
    
     
    function getPredecessor() public view returns (address) {
        return _predecessor;
    }
    
     
    function getSuccessor() public view returns (address) {
        return _successor;
    }
    
     
    function balanceOf(
        address _token,
        address _owner
    ) external constant returns (uint balance) {
         
        return balanceOf(
            _token, _owner, _MAX_REVISION_DEPTH);
    }

     
    function balanceOf(
        address _token,
        address _owner,
        uint _depth
    ) public constant returns (uint balance) {
         
        balance = _balances[_token][_owner];
        
         
        address legacyInstance = getPredecessor();
        
         
        if (legacyInstance != 0x0) {
             
            uint totalLegacyBalance = 0;
            
             
            for (uint i = 0; i < _depth; i++) {
                 
                uint legacyBalance = ZeroCache(legacyInstance)
                    .balanceOf(_token, _owner);
                    
                 
                totalLegacyBalance = totalLegacyBalance.add(legacyBalance);
    
                 
                legacyInstance = ZeroCache(legacyInstance).getPredecessor();
                
                 
                if (legacyInstance == 0x0) {
                     
                    break;
                }
            }
            
             
            balance = balance.add(totalLegacyBalance);
        }
    }

    
     

     
    function setSuccessor(
        address _newSuccessor
    ) onlyAuthBy0Admin external returns (bool success) {
         
        _successor = _newSuccessor;
        
         
        return true;
    }


     

     
    function supportsInterface(
        bytes4 _interfaceID
    ) external pure returns (bool) {
         
        bytes4 InvalidId = 0xffffffff;
        bytes4 ERC165Id = 0x01ffc9a7;

         
        if (_interfaceID == InvalidId) {
            return false;
        }

         
        if (_interfaceID == ERC165Id) {
            return true;
        }
        
         
        
         
        return false;
    }

     
    function _ecRecovery() private view returns (
        ECRecovery ecrecovery
    ) {
         
        bytes32 hash = keccak256('aname.ecrecovery');
        
         
        address aname = _zer0netDb.getAddress(hash);
        
         
        ecrecovery = ECRecovery(aname);
    }

     
    function _weth() private view returns (
        WETHInterface weth
    ) {
         
         
        bytes32 hash = keccak256('aname.WETH');
        
         
        address aname = _zer0netDb.getAddress(hash);
        
         
        weth = WETHInterface(aname);
    }

     
    function _dai() private view returns (
        ERC20Interface dai
    ) {
         
         
        bytes32 hash = keccak256('aname.DAI');
        
         
        address aname = _zer0netDb.getAddress(hash);
        
         
        dai = ERC20Interface(aname);
    }

     
    function _zeroGold() private view returns (
        ERC20Interface zeroGold
    ) {
         
         
        bytes32 hash = keccak256('aname.0GOLD');
        
         
        address aname = _zer0netDb.getAddress(hash);
        
         
        zeroGold = ERC20Interface(aname);
    }


     

     
    function _requestHasAuthSig(
        address _from,
        bytes32 _authHash,
        uint _expires,
        bytes _signature
    ) private returns (bool success) {
         
        bytes32 sigHash = keccak256(abi.encodePacked(
            '\x19Ethereum Signed Message:\n32', _authHash));

         
        if (_expiredSignatures[sigHash]) {
            return false;
        }

         
         
        _expiredSignatures[sigHash] = true;
        
         
        if (block.number > _expires) {
            return false;
        }
        
         
        address authorizedAccount = 
            _ecRecovery().recover(sigHash, _signature);

         
        if (_from != authorizedAccount) {
            return false;
        }

             
        return true;
    }

     
    function _ownerIsContract(
        address _owner
    ) private view returns (bool isContract) {
         
        uint codeLength;

         
        assembly {
             
            codeLength := extcodesize(_owner)
        }
        
         
        isContract = (codeLength > 0);
    }

     
    function _bytesToAddress(bytes _address) private pure returns (address) {
        uint160 m = 0;
        uint160 b = 0;

        for (uint8 i = 0; i < 20; i++) {
            m *= 256;
            b = uint160(_address[i]);
            m += (b);
        }

        return address(m);
    }

     
    function transferAnyERC20Token(
        address _tokenAddress, 
        uint _tokens
    ) public onlyOwner returns (bool success) {
        return ERC20Interface(_tokenAddress).transfer(owner, _tokens);
    }
}