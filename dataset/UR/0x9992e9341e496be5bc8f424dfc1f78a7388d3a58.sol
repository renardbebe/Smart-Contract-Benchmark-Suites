 

 

pragma solidity ^0.5.12;

 
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

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

         
         
         
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
         
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

     
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

     
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

         
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

 
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

     
    function callOptionalReturn(IERC20 token, bytes memory data) private {
         
         

         
         
         
         
         
        require(address(token).isContract(), "SafeERC20: call to non-contract");

         
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {  
             
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

 
 
 
 
contract DEXReserve is ERC20, ERC20Detailed, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint256 public feeInBIPS;
    uint256 public pendingFeeInBIPS;
    uint256 public feeChangeBlock;

    ERC20 public baseToken;
    ERC20 public token;
    event LogAddLiquidity(address _liquidityProvider, uint256 _tokenAmount, uint256 _baseTokenAmount);
    event LogDebug(uint256 _rcvAmount);
    event LogFeesChanged(uint256 _previousFeeInBIPS, uint256 _newFeeInBIPS);

    constructor (string memory _name, string memory _symbol, uint8 _decimals, ERC20 _baseToken, ERC20 _token, uint256 _feeInBIPS) public ERC20Detailed(_name, _symbol, _decimals) {
        baseToken = _baseToken;
        token = _token;
        feeInBIPS = _feeInBIPS;
        pendingFeeInBIPS = _feeInBIPS;
    }

     
    function recoverTokens(address _token) external onlyOwner {
        require(ERC20(_token) != baseToken && ERC20(_token) != token, "not allowed to recover reserve tokens");
        ERC20(_token).transfer(msg.sender, ERC20(_token).balanceOf(address(this)));
    }

     
     
    function updateFee(uint256 _pendingFeeInBIPS) external onlyOwner {
        if (_pendingFeeInBIPS == pendingFeeInBIPS) {
            require(block.number >= feeChangeBlock, "must wait 100 blocks before updating the fee");
            emit LogFeesChanged(feeInBIPS, pendingFeeInBIPS);
            feeInBIPS = pendingFeeInBIPS;
        } else {
             
             
            require(_pendingFeeInBIPS < 500, "fee must not exceed hard-coded limit");
            feeChangeBlock = block.number + 100;
            pendingFeeInBIPS = _pendingFeeInBIPS;
        }
    }

    function buy(address _to, address _from, uint256 _baseTokenAmount) external returns (uint256)  {
        require(totalSupply() != 0, "reserve has no funds");
        uint256 rcvAmount = calculateBuyRcvAmt(_baseTokenAmount);
        baseToken.safeTransferFrom(_from, address(this), _baseTokenAmount);
        token.safeTransfer(_to, rcvAmount);
        return rcvAmount;
    }

    function sell(address _to, address _from, uint256 _tokenAmount) external returns (uint256) {
        require(totalSupply() != 0, "reserve has no funds");
        uint256 rcvAmount = calculateSellRcvAmt(_tokenAmount);
        token.safeTransferFrom(_from, address(this), _tokenAmount);
        baseToken.safeTransfer(_to, rcvAmount);
        return rcvAmount;
    }

    function calculateBuyRcvAmt(uint256 _sendAmt) public view returns (uint256) {
        uint256 baseReserve = baseToken.balanceOf(address(this));
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 finalQuoteTokenAmount = (baseReserve.mul(tokenReserve)).div(baseReserve.add(_sendAmt));
        uint256 rcvAmt = tokenReserve.sub(finalQuoteTokenAmount);
        return _removeFees(rcvAmt);
    }

    function calculateSellRcvAmt(uint256 _sendAmt) public view returns (uint256) {
        uint256 baseReserve = baseToken.balanceOf(address(this));
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 finalBaseTokenAmount = (baseReserve.mul(tokenReserve)).div(tokenReserve.add(_sendAmt));
        uint256 rcvAmt = baseReserve.sub(finalBaseTokenAmount);
        return _removeFees(rcvAmt);
    }

    function removeLiquidity(uint256 _liquidity) external returns (uint256, uint256) {
        require(balanceOf(msg.sender) >= _liquidity, "insufficient balance");
        uint256 baseTokenAmount = calculateBaseTokenValue(_liquidity);
        uint256 quoteTokenAmount = calculateQuoteTokenValue(_liquidity);
        _burn(msg.sender, _liquidity);
        baseToken.safeTransfer(msg.sender, baseTokenAmount);
        token.safeTransfer(msg.sender, quoteTokenAmount);
        return (baseTokenAmount, quoteTokenAmount);
    }

    function addLiquidity(
        address _liquidityProvider, uint256 _maxBaseToken, uint256 _tokenAmount, uint256 _deadline
        ) external returns (uint256) {
        require(block.number <= _deadline, "addLiquidity request expired");
        uint256 liquidity = calculateExpectedLiquidity(_tokenAmount); 
        if (totalSupply() > 0) {
            require(_tokenAmount > 0, "token amount is less than allowed min amount");
            uint256 baseAmount = expectedBaseTokenAmount(_tokenAmount);
            require(baseAmount <= _maxBaseToken, "calculated base amount exceeds the maximum amount set");
            baseToken.safeTransferFrom(_liquidityProvider, address(this), baseAmount);
            emit LogAddLiquidity(_liquidityProvider, _tokenAmount, baseAmount);
        } else {
            baseToken.safeTransferFrom(_liquidityProvider, address(this), _maxBaseToken);
            emit LogAddLiquidity(_liquidityProvider, _tokenAmount, _maxBaseToken);
        }
        token.safeTransferFrom(msg.sender, address(this), _tokenAmount);
        _mint(_liquidityProvider, liquidity);
        return liquidity;
    }

    function calculateBaseTokenValue(uint256 _liquidity) public view returns (uint256) {
        require(totalSupply() != 0, "division by zero");
        uint256 baseReserve = baseToken.balanceOf(address(this));
        return (_liquidity * baseReserve)/totalSupply();
    }

    function calculateQuoteTokenValue(uint256 _liquidity) public view returns (uint256) {
        require(totalSupply() != 0,  "division by zero");
        uint256 tokenReserve = token.balanceOf(address(this));
        return (_liquidity * tokenReserve)/totalSupply();
    }

    function expectedBaseTokenAmount(uint256 _quoteTokenAmount) public view returns (uint256) {
        uint256 baseReserve = baseToken.balanceOf(address(this));
        uint256 tokenReserve = token.balanceOf(address(this));
        return (_quoteTokenAmount * baseReserve)/tokenReserve;
    }

    function calculateExpectedLiquidity(uint256 _tokenAmount) public view returns (uint256) {
        if (totalSupply() == 0) {
            return _tokenAmount*2;
        }
        return ((totalSupply()*_tokenAmount)/token.balanceOf(address(this)));
    }

    function _removeFees(uint256 _amount) internal view returns (uint256) {
        return (_amount * (10000 - feeInBIPS))/10000;
    }
}

   
contract BTC_DAI_Reserve is DEXReserve {
    constructor (ERC20 _baseToken, ERC20 _token, uint256 _feeInBIPS) public DEXReserve("Bitcoin Liquidity Token", "BTCLT", 8, _baseToken, _token, _feeInBIPS) {
    }
}

   
contract ZEC_DAI_Reserve is DEXReserve {
    constructor (ERC20 _baseToken, ERC20 _token, uint256 _feeInBIPS) public DEXReserve("ZCash Liquidity Token", "ZECLT", 8, _baseToken, _token, _feeInBIPS) {
    }
}

   
contract BCH_DAI_Reserve is DEXReserve {
    constructor (ERC20 _baseToken, ERC20 _token, uint256 _feeInBIPS) public DEXReserve("BitcoinCash Liquidity Token", "BCHLT", 8, _baseToken, _token, _feeInBIPS) {
    }
}

 
 
 
 
 
 
 
 
 
 
 
contract DEX is Claimable {
    mapping (address=>DEXReserve) public reserves;
    address public baseToken;

    event LogTrade(address _src, address _dst, uint256 _sendAmount, uint256 _recvAmount);

     
    constructor(address _baseToken) public {
        baseToken = _baseToken;
    }

     
     
    function recoverTokens(address _token) external onlyOwner {
        if (_token == address(0x0)) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(_token).transfer(msg.sender, ERC20(_token).balanceOf(address(this)));
        }
    }

     
     
     
     
    function registerReserve(address _erc20, DEXReserve _reserve) external onlyOwner {
        require(reserves[_erc20] == DEXReserve(0x0), "token reserve already registered");
        reserves[_erc20] = _reserve;
    }

     
     
     
     
     
    function trade(address _to, address _src, address _dst, uint256 _sendAmount) public returns (uint256) {
        uint256 recvAmount;
        if (_src == baseToken) {
            require(reserves[_dst] != DEXReserve(0x0), "unsupported token");
            recvAmount = reserves[_dst].buy(_to, msg.sender, _sendAmount);
        } else if (_dst == baseToken) {
            require(reserves[_src] != DEXReserve(0x0), "unsupported token");
            recvAmount = reserves[_src].sell(_to, msg.sender, _sendAmount);
        } else {
            require(reserves[_src] != DEXReserve(0x0) && reserves[_dst] != DEXReserve(0x0), "unsupported token");
            uint256 intermediteAmount = reserves[_src].sell(address(this), msg.sender, _sendAmount);
            ERC20(baseToken).approve(address(reserves[_dst]), intermediteAmount);
            recvAmount = reserves[_dst].buy(_to, address(this), intermediteAmount);
        }
        emit LogTrade(_src, _dst, _sendAmount, recvAmount);
        return recvAmount;
    }

     
     
     
     
     
    function calculateReceiveAmount(address _src, address _dst, uint256 _sendAmount) public view returns (uint256) {
        if (_src == baseToken) {
            return reserves[_dst].calculateBuyRcvAmt(_sendAmount);
        }
        if (_dst == baseToken) {
            return reserves[_src].calculateSellRcvAmt(_sendAmount);
        }
        return reserves[_dst].calculateBuyRcvAmt(reserves[_src].calculateSellRcvAmt(_sendAmount));
    }
}

 
library LinkedList {

     
    address public constant NULL = address(0);

     
    struct Node {
        bool inList;
        address previous;
        address next;
    }

     
    struct List {
        mapping (address => Node) list;
    }

     
    function insertBefore(List storage self, address target, address newNode) internal {
        require(!isInList(self, newNode), "LinkedList: already in list");
        require(isInList(self, target) || target == NULL, "LinkedList: not in list");

         
        address prev = self.list[target].previous;

        self.list[newNode].next = target;
        self.list[newNode].previous = prev;
        self.list[target].previous = newNode;
        self.list[prev].next = newNode;

        self.list[newNode].inList = true;
    }

     
    function insertAfter(List storage self, address target, address newNode) internal {
        require(!isInList(self, newNode), "LinkedList: already in list");
        require(isInList(self, target) || target == NULL, "LinkedList: not in list");

         
        address n = self.list[target].next;

        self.list[newNode].previous = target;
        self.list[newNode].next = n;
        self.list[target].next = newNode;
        self.list[n].previous = newNode;

        self.list[newNode].inList = true;
    }

     
    function remove(List storage self, address node) internal {
        require(isInList(self, node), "LinkedList: not in list");
        if (node == NULL) {
            return;
        }
        address p = self.list[node].previous;
        address n = self.list[node].next;

        self.list[p].next = n;
        self.list[n].previous = p;

         
         
        self.list[node].inList = false;
        delete self.list[node];
    }

     
    function prepend(List storage self, address node) internal {
         

        insertBefore(self, begin(self), node);
    }

     
    function append(List storage self, address node) internal {
         

        insertAfter(self, end(self), node);
    }

    function swap(List storage self, address left, address right) internal {
         

        address previousRight = self.list[right].previous;
        remove(self, right);
        insertAfter(self, left, right);
        remove(self, left);
        insertAfter(self, previousRight, left);
    }

    function isInList(List storage self, address node) internal view returns (bool) {
        return self.list[node].inList;
    }

     
    function begin(List storage self) internal view returns (address) {
        return self.list[NULL].next;
    }

     
    function end(List storage self) internal view returns (address) {
        return self.list[NULL].previous;
    }

    function next(List storage self, address node) internal view returns (address) {
        require(isInList(self, node), "LinkedList: not in list");
        return self.list[node].next;
    }

    function previous(List storage self, address node) internal view returns (address) {
        require(isInList(self, node), "LinkedList: not in list");
        return self.list[node].previous;
    }

}

interface IShifter {
    function shiftIn(bytes32 _pHash, uint256 _amount, bytes32 _nHash, bytes calldata _sig) external returns (uint256);
    function shiftOut(bytes calldata _to, uint256 _amount) external returns (uint256);
    function shiftInFee() external view returns (uint256);
    function shiftOutFee() external view returns (uint256);
}

 
 
contract ShifterRegistry is Claimable {

     
     
    event LogShifterRegistered(string _symbol, string indexed _indexedSymbol, address indexed _tokenAddress, address indexed _shifterAddress);
    event LogShifterDeregistered(string _symbol, string indexed _indexedSymbol, address indexed _tokenAddress, address indexed _shifterAddress);
    event LogShifterUpdated(address indexed _tokenAddress, address indexed _currentShifterAddress, address indexed _newShifterAddress);

     
    uint256 numShifters = 0;

     
    LinkedList.List private shifterList;

     
    LinkedList.List private shiftedTokenList;

     
    mapping (address=>address) private shifterByToken;

     
    mapping (string=>address) private tokenBySymbol;

     
     
    function recoverTokens(address _token) external onlyOwner {
        if (_token == address(0x0)) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(_token).transfer(msg.sender, ERC20(_token).balanceOf(address(this)));
        }
    }

     
     
     
     
     
    function setShifter(address _tokenAddress, address _shifterAddress) external onlyOwner {
         
        require(!LinkedList.isInList(shifterList, _shifterAddress), "ShifterRegistry: shifter already registered");
        require(shifterByToken[_tokenAddress] == address(0x0), "ShifterRegistry: token already registered");
        string memory symbol = ERC20Shifted(_tokenAddress).symbol();
        require(tokenBySymbol[symbol] == address(0x0), "ShifterRegistry: symbol already registered");

         
        LinkedList.append(shifterList, _shifterAddress);

         
        LinkedList.append(shiftedTokenList, _tokenAddress);

        tokenBySymbol[symbol] = _tokenAddress;
        shifterByToken[_tokenAddress] = _shifterAddress;
        numShifters += 1;

        emit LogShifterRegistered(symbol, symbol, _tokenAddress, _shifterAddress);
    }

     
     
     
     
     
    function updateShifter(address _tokenAddress, address _newShifterAddress) external onlyOwner {
         
        address currentShifter = shifterByToken[_tokenAddress];
        require(shifterByToken[_tokenAddress] != address(0x0), "ShifterRegistry: token not registered");

         
        LinkedList.remove(shifterList, currentShifter);

         
        LinkedList.append(shifterList, _newShifterAddress);

        shifterByToken[_tokenAddress] = _newShifterAddress;

        emit LogShifterUpdated(_tokenAddress, currentShifter, _newShifterAddress);
    }

     
     
     
     
    function removeShifter(string calldata _symbol) external onlyOwner {
         
        address tokenAddress = tokenBySymbol[_symbol];
        require(tokenAddress != address(0x0), "ShifterRegistry: symbol not registered");

         
        address shifterAddress = shifterByToken[tokenAddress];

         
        shifterByToken[tokenAddress] = address(0x0);
        tokenBySymbol[_symbol] = address(0x0);
        LinkedList.remove(shifterList, shifterAddress);
        LinkedList.remove(shiftedTokenList, tokenAddress);
        numShifters -= 1;

        emit LogShifterDeregistered(_symbol, _symbol, tokenAddress, shifterAddress);
    }

     
    function getShifters(address _start, uint256 _count) external view returns (address[] memory) {
        uint256 count;
        if (_count == 0) {
            count = numShifters;
        } else {
            count = _count;
        }

        address[] memory shifters = new address[](count);

         
        uint256 n = 0;
        address next = _start;
        if (next == address(0)) {
            next = LinkedList.begin(shifterList);
        }

        while (n < count) {
            if (next == address(0)) {
                break;
            }
            shifters[n] = next;
            next = LinkedList.next(shifterList, next);
            n += 1;
        }
        return shifters;
    }

     
    function getShiftedTokens(address _start, uint256 _count) external view returns (address[] memory) {
        uint256 count;
        if (_count == 0) {
            count = numShifters;
        } else {
            count = _count;
        }

        address[] memory shiftedTokens = new address[](count);

         
        uint256 n = 0;
        address next = _start;
        if (next == address(0)) {
            next = LinkedList.begin(shiftedTokenList);
        }

        while (n < count) {
            if (next == address(0)) {
                break;
            }
            shiftedTokens[n] = next;
            next = LinkedList.next(shiftedTokenList, next);
            n += 1;
        }
        return shiftedTokens;
    }

     
     
     
     
    function getShifterByToken(address _tokenAddress) external view returns (IShifter) {
        return IShifter(shifterByToken[_tokenAddress]);
    }

     
     
     
     
    function getShifterBySymbol(string calldata _tokenSymbol) external view returns (IShifter) {
        return IShifter(shifterByToken[tokenBySymbol[_tokenSymbol]]);
    }

     
     
     
     
    function getTokenBySymbol(string calldata _tokenSymbol) external view returns (address) {
        return tokenBySymbol[_tokenSymbol];
    }
}

contract DEXAdapter {
    using SafeERC20 for ERC20;

    DEX public dex;
    ShifterRegistry public shifterRegistry;

    event LogTransferIn(address src, uint256 amount);
    event LogTransferOut(address dst, uint256 amount);

    constructor(DEX _dex, ShifterRegistry _shifterRegistry) public {
        shifterRegistry = _shifterRegistry;
        dex = _dex;
    }

     
     
    function recoverTokens(address _token) external {
        if (_token == address(0x0)) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(_token).transfer(msg.sender, ERC20(_token).balanceOf(address(this)));
        }
    }

     
    uint256 transferredAmt;

    function trade(
         
          address _src, address _dst, uint256 _minDstAmt, bytes calldata _to,
        uint256 _refundBN, bytes calldata _refundAddress,
         
        uint256 _amount, bytes32 _nHash, bytes calldata _sig
    ) external {
        transferredAmt;
        bytes32 pHash = hashTradePayload(_src, _dst, _minDstAmt, _to, _refundBN, _refundAddress);
         
        if (block.number >= _refundBN) {
            IShifter shifter = shifterRegistry.getShifterByToken(address(_src));
            if (shifter != IShifter(0x0)) {
                transferredAmt = shifter.shiftIn(pHash, _amount, _nHash, _sig);
                shifter.shiftOut(_refundAddress, transferredAmt);
            }
            return;
        }

        transferredAmt = _transferIn(_src, _amount, _nHash, pHash, _sig);
        emit LogTransferIn(_src, transferredAmt);
        _doTrade(_src, _dst, _minDstAmt, _to, transferredAmt);
    }

    function hashTradePayload(
          address _src, address _dst, uint256 _minDstAmt, bytes memory _to,
        uint256 _refundBN, bytes memory _refundAddress
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_src, _dst, _minDstAmt, _to, _refundBN, _refundAddress));
    }

    function hashLiquidityPayload(
        address _liquidityProvider,  uint256 _maxBaseToken, address _token,
        uint256 _refundBN, bytes memory _refundAddress
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_liquidityProvider, _maxBaseToken, _token, _refundBN, _refundAddress));
    }

    function addLiquidity(
        address _liquidityProvider,  uint256 _maxBaseToken, address _token, uint256 _deadline, bytes calldata _refundAddress,
        uint256 _amount, bytes32 _nHash, bytes calldata _sig
        ) external returns (uint256) {
            DEXReserve reserve = dex.reserves(_token);
            require(reserve != DEXReserve(0x0), "unsupported token");
            bytes32 lpHash = hashLiquidityPayload(_liquidityProvider, _maxBaseToken, _token, _deadline, _refundAddress);
            if (block.number > _deadline) {
                uint256 shiftedAmount = shifterRegistry.getShifterByToken(_token).shiftIn(lpHash, _amount, _nHash, _sig);
                shifterRegistry.getShifterByToken(_token).shiftOut(_refundAddress, shiftedAmount);
                return 0;
            }
            require(ERC20(dex.baseToken()).allowance(_liquidityProvider, address(reserve)) >= _maxBaseToken,
                "insufficient base token allowance");
            uint256 transferredAmount = _transferIn(_token, _amount, _nHash, lpHash, _sig);
            ERC20(_token).approve(address(reserve), transferredAmount);
            return reserve.addLiquidity(_liquidityProvider, _maxBaseToken, transferredAmount, _deadline);
    }

    function removeLiquidity(address _token, uint256 _liquidity, bytes calldata _tokenAddress) external {
        DEXReserve reserve = dex.reserves(_token);
        require(reserve != DEXReserve(0x0), "unsupported token");
        ERC20(reserve).safeTransferFrom(msg.sender, address(this), _liquidity);
        (uint256 baseTokenAmount, uint256 quoteTokenAmount) = reserve.removeLiquidity(_liquidity);
        reserve.baseToken().safeTransfer(msg.sender, baseTokenAmount);
        shifterRegistry.getShifterByToken(address(reserve.token())).shiftOut(_tokenAddress, quoteTokenAmount);
    }

    function _doTrade(
        address _src, address _dst, uint256 _minDstAmt, bytes memory _to, uint256 _amount
    ) internal {
        uint256 recvAmt;
        address to;
        IShifter shifter = shifterRegistry.getShifterByToken(address(_dst));

        if (shifter != IShifter(0x0)) {
            to = address(this);
        } else {
            to = _bytesToAddress(_to);
        }

        if (_src == dex.baseToken()) {
            ERC20(_src).approve(address(dex.reserves(_dst)), _amount);
        } else {
            ERC20(_src).approve(address(dex.reserves(_src)), _amount);
        }
        recvAmt = dex.trade(to, _src, _dst, _amount);

        require(recvAmt > 0 && recvAmt >= _minDstAmt, "invalid receive amount");
        if (shifter != IShifter(0x0)) {
            shifter.shiftOut(_to, recvAmt);
        }
        emit LogTransferOut(_dst, recvAmt);
    }

    function _transferIn(
          address _src, uint256 _amount,
        bytes32 _nHash, bytes32 _pHash, bytes memory _sig
    ) internal returns (uint256) {
        IShifter shifter = shifterRegistry.getShifterByToken(address(_src));
        if (shifter != IShifter(0x0)) {
            return shifter.shiftIn(_pHash, _amount, _nHash, _sig);
        } else {
            ERC20(_src).safeTransferFrom(msg.sender, address(this), _amount);
            return _amount;
        }
    }

    function _bytesToAddress(bytes memory _addr) internal pure returns (address) {
        address addr;
           
        assembly {
            addr := mload(add(_addr, 20))
        }
        return addr;
    }

    function calculateReceiveAmount(address _src, address _dst, uint256 _sendAmount) public view returns (uint256) {
        uint256 sendAmount = _sendAmount;

         
        IShifter srcShifter = shifterRegistry.getShifterByToken(_dst);
        if (srcShifter != IShifter(0x0)) {
            sendAmount = removeFee(_sendAmount, srcShifter.shiftInFee());
        }

        uint256 receiveAmount = dex.calculateReceiveAmount(_src, _dst, sendAmount);

         
        IShifter dstShifter = shifterRegistry.getShifterByToken(_dst);
        if (dstShifter != IShifter(0x0)) {
            receiveAmount = removeFee(receiveAmount, dstShifter.shiftOutFee());
        }

        return receiveAmount;
    }

    function removeFee(uint256 _amount, uint256 _feeInBips) private view returns (uint256) {
        return _amount - (_amount * _feeInBips)/10000;
    }
}