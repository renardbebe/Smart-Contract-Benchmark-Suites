 

pragma solidity >= 0.5.0;


 
 
 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "Safe mul error");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "Safe div error");
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Safe sub error");
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Safe add error");

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "Safe mod error");
        return a % b;
    }
}

 

library ECDSA {
     
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

         
        if (signature.length != 65) {
            return (address(0));
        }

         
         
         
         
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
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

     
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
         
         
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
} 

 
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}

 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ECRecover {

    mapping (address => uint) public nonces;

    function recoverSigner(bytes32 _hash, bytes memory _signature) public pure returns (address) {
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(_hash);
        return ECDSA.recover(ethSignedMessageHash, _signature);
    }

    function validateNonceForSigner(address _signer, uint _nonce) internal {
        require(_signer != address(0), "Invalid signer");
        require(_nonce == nonces[_signer], "Invalid nonce");
        nonces[_signer]++;
    }

}

 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowed;

    uint256 internal _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
} 

 
interface IERC20X {

    function approveAndCall(address _spender, uint _value, bytes calldata _data) external returns (bool);
    event ApprovalAndCall(address indexed owner, address indexed spender, uint value, bytes data);
    
}

 
interface ITokenReceiver {

    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata data) external;
    
}

 
contract ERC20X is IERC20X, ERC20 {

    function approveAndCall(address _spender, uint _value, bytes memory _data) public returns (bool) {
        _approveAndCall(msg.sender, _spender, _value, _data);
        return true;
    }

    function _approveAndCall(address _owner, address _spender, uint _value, bytes memory _data) internal {
        require(_spender != address(0), "Spender cannot be address(0)");

        _allowed[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);

        ITokenReceiver(_spender).receiveApproval(_owner, _value, address(this), _data);
        emit ApprovalAndCall(_owner, _spender, _value, _data);
    }
    
}
 
 
contract ERC20Meta is ERC20X, ECRecover {

    function metaApproveAndCall(bytes memory _signature, uint _nonce, address _spender, uint _value, bytes memory _data, uint _reward)
    public returns (bool) 
    {   
        require(_spender != address(0), "Invalid spender address");

        bytes32 messageHash = metaApproveAndCallHash(_nonce, _spender, _value, _data, _reward);
        address signer = recoverSigner(messageHash, _signature);
        validateNonceForSigner(signer, _nonce);

        _approveAndCall(signer, _spender, _value, _data);

        if (_reward > 0) 
            _transfer(signer, msg.sender, _reward);
            
        return true;
    }

    function metaTransfer(bytes memory _signature, uint _nonce, address _to, uint _value, uint _reward) 
    public returns (bool) 
    {
        bytes32 messageHash = metaTransferHash(_nonce, _to, _value, _reward);
        address signer = recoverSigner(messageHash, _signature);
        validateNonceForSigner(signer, _nonce);
        _transfer(signer, _to, _value);

        if (_reward > 0) 
            _transfer(signer, msg.sender, _reward);
        
        return true;
    }

    function metaTransferFrom(bytes memory _signature, uint _nonce, address _from, address _to, uint _value, uint _reward) 
    public returns (bool) 
    {
        bytes32 messageHash = metaTransferFromHash(_nonce, _from, _to, _value, _reward);
        address signer = recoverSigner(messageHash, _signature);
        validateNonceForSigner(signer, _nonce);

        _allowed[_from][signer] = _allowed[_from][signer].sub(_value);  
        _transfer(_from, _to, _value);
        emit Approval(_from, signer, _allowed[_from][signer]);

        if (_reward > 0) 
            _transfer(signer, msg.sender, _reward);
        
        return true;
    }

    function metaApprove(bytes memory _signature, uint _nonce, address _spender, uint _value, uint _reward) 
    public returns (bool) 
    {
        require(_spender != address(0), "Invalid spender address");

        bytes32 messageHash = metaApproveHash(_nonce, _spender, _value, _reward);
        address signer = recoverSigner(messageHash, _signature);
        validateNonceForSigner(signer, _nonce);
    
        _allowed[signer][_spender] = _value;
       
        if (_reward > 0) 
            _transfer(signer, msg.sender, _reward);

        emit Approval(signer, _spender, _value);
        return true;
    }

    function metaIncreaseAllowance(bytes memory _signature, uint _nonce, address _spender, uint256 _addedValue, uint _reward) 
    public returns (bool) 
    {
        require(_spender != address(0), "Invalid spender address");

        bytes32 messageHash = metaIncreaseAllowanceHash(_nonce, _spender, _addedValue, _reward);
        address signer = recoverSigner(messageHash, _signature);
        validateNonceForSigner(signer, _nonce);

        _allowed[signer][_spender] = _allowed[signer][_spender].add(_addedValue);

        if (_reward > 0) 
            _transfer(signer, msg.sender, _reward);

        emit Approval(signer, _spender, _allowed[signer][_spender]);
        return true;
    }

    function metaDecreaseAllowance(bytes memory _signature, uint _nonce, address _spender, uint256 _subtractedValue, uint _reward) 
    public returns (bool) 
    {
        require(_spender != address(0), "Invalid spender address");

        bytes32 messageHash = metaDecreaseAllowanceHash(_nonce, _spender, _subtractedValue, _reward);
        address signer = recoverSigner(messageHash, _signature);
        validateNonceForSigner(signer, _nonce);

        _allowed[signer][_spender] = _allowed[signer][_spender].sub(_subtractedValue);

        if (_reward > 0) 
            _transfer(signer, msg.sender, _reward);
        
        emit Approval(signer, _spender, _allowed[signer][_spender]);
        return true;
    }

    function metaTransferHash(uint _nonce, address _to, uint _value, uint _reward) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), "metaTransfer", _nonce, _to, _value, _reward)); 
    }

    function metaApproveAndCallHash(uint _nonce, address _spender, uint _value, bytes memory _data, uint _reward) 
    public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), "metaApproveAndCall", _nonce, _spender, _value, _data, _reward)); 
    }

    function metaTransferFromHash(uint _nonce, address _from, address _to, uint _value, uint _reward) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), "metaTransferFrom", _nonce, _from, _to, _value, _reward)); 
    }

    function metaApproveHash(uint _nonce, address _spender, uint _value, uint _reward) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), "metaApprove", _nonce, _spender, _value, _reward)); 
    }

    function metaIncreaseAllowanceHash(uint _nonce, address _spender, uint256 _addedValue, uint _reward) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), "metaIncreaseAllowance", _nonce, _spender, _addedValue, _reward));
    }

    function metaDecreaseAllowanceHash(uint _nonce, address _spender, uint256 _subtractedValue, uint _reward) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), "metaDecreaseAllowance", _nonce, _spender, _subtractedValue, _reward));
    }
    
}

contract Token is ERC20Meta, Ownable {
     
    mapping (bytes32 => uint64) internal chains;
     
    mapping (bytes32 => uint) internal freezings;
     
    mapping (address => uint) internal freezingBalance;

    event Freezed(address indexed to, uint64 release, uint amount);
    event Released(address indexed owner, uint amount);

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner) + freezingBalance[_owner];
    }

     
    function actualBalanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner);
    }

    function freezingBalanceOf(address _owner) public view returns (uint256 balance) {
        return freezingBalance[_owner];
    }

     
    function freezingCount(address _addr) public view returns (uint count) {
        uint64 release = chains[toKey(_addr, 0)];
        while (release != 0) {
            count++;
            release = chains[toKey(_addr, release)];
        }
    }

     
    function getFreezing(address _addr, uint _index) public view returns (uint64 _release, uint _balance) {
        for (uint i = 0; i < _index + 1; i++) {
            _release = chains[toKey(_addr, _release)];
            if (_release == 0) {
                return(0, 0);
            }
        }
        _balance = freezings[toKey(_addr, _release)];
    }

     
    function freezeTo(address _to, uint _amount, uint64 _until) public {
        _freezeTo(msg.sender, _to, _amount, _until);
    }

    function _freezeTo(address _from, address _to, uint _amount, uint64 _until) internal {
        require(_to != address(0));
        require(_amount <= _balances[_from]);

        _balances[_from] = _balances[_from].sub(_amount);

        bytes32 currentKey = toKey(_to, _until);
        freezings[currentKey] = freezings[currentKey].add(_amount);
        freezingBalance[_to] = freezingBalance[_to].add(_amount);

        freeze(_to, _until);
        emit Transfer(_from, _to, _amount);
        emit Freezed(_to, _until, _amount);
    }

     
    function releaseOnce() public {
        bytes32 headKey = toKey(msg.sender, 0);
        uint64 head = chains[headKey];
        require(head != 0);
        require(uint64(block.timestamp) > head);
        bytes32 currentKey = toKey(msg.sender, head);

        uint64 next = chains[currentKey];

        uint amount = freezings[currentKey];
        delete freezings[currentKey];

        _balances[msg.sender] = _balances[msg.sender].add(amount);
        freezingBalance[msg.sender] = freezingBalance[msg.sender].sub(amount);

        if (next == 0) {
            delete chains[headKey];
        } else {
            chains[headKey] = next;
            delete chains[currentKey];
        }
        emit Released(msg.sender, amount);
    }

     
    function releaseAll() public returns (uint tokens) {
        uint release;
        uint balance;
        (release, balance) = getFreezing(msg.sender, 0);
        while (release != 0 && block.timestamp > release) {
            releaseOnce();
            tokens += balance;
            (release, balance) = getFreezing(msg.sender, 0);
        }
    }

    function toKey(address _addr, uint _release) internal pure returns (bytes32 result) {
         
        result = 0x5749534800000000000000000000000000000000000000000000000000000000;
        assembly {
            result := or(result, mul(_addr, 0x10000000000000000))
            result := or(result, _release)
        }
    }

    function freeze(address _to, uint64 _until) internal {
        require(_until > block.timestamp);
        bytes32 key = toKey(_to, _until);
        bytes32 parentKey = toKey(_to, uint64(0));
        uint64 next = chains[parentKey];

        if (next == 0) {
            chains[parentKey] = _until;
            return;
        }

        bytes32 nextKey = toKey(_to, next);
        uint parent;

        while (next != 0 && _until > next) {
            parent = next;
            parentKey = nextKey;

            next = chains[nextKey];
            nextKey = toKey(_to, next);
        }

        if (_until == next) {
            return;
        }

        if (next != 0) {
            chains[key] = next;
        }

        chains[parentKey] = _until;
    }

     
     
     
    function transferAnyERC20Token(address _token, address _to, uint _value) public onlyOwner returns (bool) {
        return IERC20(_token).transfer(_to, _value);
    }
}

 
contract ALBToken is Token, ERC20Detailed {
    using SafeERC20 for ERC20;
	
    uint256 startdate;
	
    address beneficiary1;
    address beneficiary2;
    address beneficiary3;
    address beneficiary4;
    address beneficiary5;

    constructor() public ERC20Detailed("AllBeBet", "ALB", 0) {
        uint256 amount = 1000000000 * (10 ** uint256(decimals()));
        _mint(address(this), amount);
		
		startdate = 1566766800;

        beneficiary1 = 0x11308512672859E403C570996dA51EEb6F5d1cD3;
        beneficiary2 = 0x3c35a288d9EA25E8F727C7d45383c04E633B5bdC;
        beneficiary3 = 0xc643E129c49CAb15dfC964643f2deCC9Dbfc7091;
        beneficiary4 = 0x188f445c13F702cBB3734Df63fb4Cb96c474866d;
        beneficiary5 = 0xFd05e00091b947AaA3ebA36beC62C2CA6003BCE7;

        _freezeTo(address(this), beneficiary1, totalSupply().mul(375).div(1000), uint64(startdate + 183 days));
        _freezeTo(address(this), beneficiary1, totalSupply().mul(375).div(1000),uint64(startdate + 365 days));
        _freezeTo(address(this), beneficiary2, totalSupply().mul(15).div(1000), uint64(startdate + 183 days));
        _freezeTo(address(this), beneficiary2, totalSupply().mul(15).div(1000), uint64(startdate + 365 days));
        _freezeTo(address(this), beneficiary3, totalSupply().mul(5).div(100), uint64(startdate + 183 days));
        _freezeTo(address(this), beneficiary3, totalSupply().mul(5).div(100), uint64(startdate + 365 days));

        _transfer(address(this), beneficiary4, totalSupply().mul(9).div(100));
        _transfer(address(this), beneficiary5, totalSupply().mul(3).div(100));
    }
}