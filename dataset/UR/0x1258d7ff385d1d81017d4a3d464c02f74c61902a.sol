 

 

pragma solidity ^0.5.12;


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        
        require(b > 0, errorMessage);
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    
    
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library ECDSA {
    
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        
        if (signature.length != 65) {
            revert("signature's length is invalid");
        }

        
        bytes32 r;
        bytes32 s;
        uint8 v;

        
        
        
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        
        
        
        
        
        
        
        
        
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert("signature's s is in the wrong range");
        }

        if (v != 27 && v != 28) {
            revert("signature's v is in the wrong range");
        }

        
        return ecrecover(hash, v, r, s);
    }

    
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        
        
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

contract Claimable {
    address private _pendingOwner;
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
        require(isOwner(), "Claimable: caller is not the owner");
        _;
    }

    
    modifier onlyPendingOwner() {
      require(msg.sender == _pendingOwner, "Claimable: caller is not the pending owner");
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
      _pendingOwner = newOwner;
    }

    
    function claimOwnership() public onlyPendingOwner {
      emit OwnershipTransferred(_owner, _pendingOwner);
      _owner = _pendingOwner;
      _pendingOwner = address(0);
    }
}

library String {

    
    
    function fromUint(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    
    function fromBytes32(bytes32 _value) internal pure returns(string memory) {
        bytes32 value = bytes32(uint256(_value));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(32 * 2 + 2);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 32; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i] & 0x0f))];
        }
        return string(str);
    }

    
    function fromAddress(address _addr) internal pure returns(string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(20 * 2 + 2);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }

    
    function add4(string memory a, string memory b, string memory c, string memory d) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d));
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
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

contract ERC20Shifted is ERC20, ERC20Detailed, Claimable {

    
    constructor(string memory _name, string memory _symbol, uint8 _decimals) public ERC20Detailed(_name, _symbol, _decimals) {}

    
    
    function recoverTokens(address _token) external onlyOwner {
        if (_token == address(0x0)) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(_token).transfer(msg.sender, ERC20(_token).balanceOf(address(this)));
        }
    }

    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}

contract zBTC is ERC20Shifted("Shifted BTC", "zBTC", 8) {}

contract zZEC is ERC20Shifted("Shifted ZEC", "zZEC", 8) {}

contract zBCH is ERC20Shifted("Shifted BCH", "zBCH", 8) {}

contract Shifter is Claimable {
    using SafeMath for uint256;

    uint8 public version = 2;

    uint256 constant BIPS_DENOMINATOR = 10000;
    uint256 public minShiftAmount;

    
    ERC20Shifted public token;

    
    address public mintAuthority;

    
    
    
    
    address public feeRecipient;

    
    uint16 public shiftInFee;

    
    uint16 public shiftOutFee;

    
    mapping (bytes32=>bool) public status;

    
    
    uint256 public nextShiftID = 0;

    event LogShiftIn(
        address indexed _to,
        uint256 _amount,
        uint256 indexed _shiftID,
        bytes32 indexed _signedMessageHash
    );
    event LogShiftOut(
        bytes _to,
        uint256 _amount,
        uint256 indexed _shiftID,
        bytes indexed _indexedTo
    );

    
    
    
    
    
    
    
    
    constructor(ERC20Shifted _token, address _feeRecipient, address _mintAuthority, uint16 _shiftInFee, uint16 _shiftOutFee, uint256 _minShiftOutAmount) public {
        minShiftAmount = _minShiftOutAmount;
        token = _token;
        mintAuthority = _mintAuthority;
        shiftInFee = _shiftInFee;
        shiftOutFee = _shiftOutFee;
        updateFeeRecipient(_feeRecipient);
    }

    
    
    function recoverTokens(address _token) external onlyOwner {
        if (_token == address(0x0)) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(_token).transfer(msg.sender, ERC20(_token).balanceOf(address(this)));
        }
    }

    

    
    
    
    function claimTokenOwnership() public {
        token.claimOwnership();
    }

    
    function transferTokenOwnership(Shifter _nextTokenOwner) public onlyOwner {
        token.transferOwnership(address(_nextTokenOwner));
        _nextTokenOwner.claimTokenOwnership();
    }

    
    
    
    function updateMintAuthority(address _nextMintAuthority) public onlyOwner {
        mintAuthority = _nextMintAuthority;
    }

    
    
    
    function updateMinimumShiftOutAmount(uint256 _minShiftOutAmount) public onlyOwner {
        minShiftAmount = _minShiftOutAmount;
    }

    
    
    
    function updateFeeRecipient(address _nextFeeRecipient) public onlyOwner {
        
        require(_nextFeeRecipient != address(0x0), "Shifter: fee recipient cannot be 0x0");

        feeRecipient = _nextFeeRecipient;
    }

    
    
    
    function updateShiftInFee(uint16 _nextFee) public onlyOwner {
        shiftInFee = _nextFee;
    }

    
    
    
    function updateShiftOutFee(uint16 _nextFee) public onlyOwner {
        shiftOutFee = _nextFee;
    }

    
    
    
    
    
    
    
    
    
    function shiftIn(bytes32 _pHash, uint256 _amount, bytes32 _nHash, bytes memory _sig) public returns (uint256) {
        
        bytes32 signedMessageHash = hashForSignature(_pHash, _amount, msg.sender, _nHash);
        require(status[signedMessageHash] == false, "Shifter: nonce hash already spent");
        if (!verifySignature(signedMessageHash, _sig)) {
            
            
            
            revert(
                String.add4(
                    "Shifter: invalid signature - hash: ",
                    String.fromBytes32(signedMessageHash),
                    ", signer: ",
                    String.fromAddress(ECDSA.recover(signedMessageHash, _sig))
                )
            );
        }
        status[signedMessageHash] = true;

        
        uint256 absoluteFee = (_amount.mul(shiftInFee)).div(BIPS_DENOMINATOR);
        uint256 receivedAmount = _amount.sub(absoluteFee);
        token.mint(msg.sender, receivedAmount);
        token.mint(feeRecipient, absoluteFee);

        
        emit LogShiftIn(msg.sender, receivedAmount, nextShiftID, signedMessageHash);
        nextShiftID += 1;

        return receivedAmount;
    }

    
    
    
    
    
    
    
    
    function shiftOut(bytes memory _to, uint256 _amount) public returns (uint256) {
        
        
        require(_to.length != 0, "Shifter: to address is empty");
        require(_amount >= minShiftAmount, "Shifter: amount is less than the minimum shiftOut amount");

        
        uint256 absoluteFee = (_amount.mul(shiftOutFee)).div(BIPS_DENOMINATOR);
        token.burn(msg.sender, _amount);
        token.mint(feeRecipient, absoluteFee);

        
        uint256 receivedValue = _amount.sub(absoluteFee);
        emit LogShiftOut(_to, receivedValue, nextShiftID, _to);
        nextShiftID += 1;

        return receivedValue;
    }

    
    
    function verifySignature(bytes32 _signedMessageHash, bytes memory _sig) public view returns (bool) {
        return mintAuthority == ECDSA.recover(_signedMessageHash, _sig);
    }

    
    function hashForSignature(bytes32 _pHash, uint256 _amount, address _to, bytes32 _nHash) public view returns (bytes32) {
        return keccak256(abi.encode(_pHash, _amount, address(token), _to, _nHash));
    }
}

contract BTCShifter is Shifter {
    constructor(ERC20Shifted _token, address _feeRecipient, address _mintAuthority, uint16 _shiftInFee, uint16 _shiftOutFee, uint256 _minShiftOutAmount)
        Shifter(_token, _feeRecipient, _mintAuthority, _shiftInFee, _shiftOutFee, _minShiftOutAmount) public {
        }
}

contract ZECShifter is Shifter {
    constructor(ERC20Shifted _token, address _feeRecipient, address _mintAuthority, uint16 _shiftInFee, uint16 _shiftOutFee, uint256 _minShiftOutAmount)
        Shifter(_token, _feeRecipient, _mintAuthority, _shiftInFee, _shiftOutFee, _minShiftOutAmount) public {
        }
}

contract BCHShifter is Shifter {
    constructor(ERC20Shifted _token, address _feeRecipient, address _mintAuthority, uint16 _shiftInFee, uint16 _shiftOutFee, uint256 _minShiftOutAmount)
        Shifter(_token, _feeRecipient, _mintAuthority, _shiftInFee, _shiftOutFee, _minShiftOutAmount) public {
        }
}