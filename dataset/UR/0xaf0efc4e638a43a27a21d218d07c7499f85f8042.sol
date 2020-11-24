 

 

pragma solidity ^0.5.8;


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
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
        require(isOwner(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library ECDSA {
    
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        
        if (signature.length != 65) {
            return (address(0));
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
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        
        return ecrecover(hash, v, r, s);
    }

    
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        
        
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

library String {

    
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

contract ERC20 is IERC20 {
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
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
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
        require(isOwner(), "caller is not the owner");
        _;
    }

    
    modifier onlyPendingOwner() {
      require(msg.sender == _pendingOwner, "caller is not the pending owner");
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

contract ERC20Shifted is ERC20, ERC20Detailed, Claimable {

    
    constructor(string memory _name, string memory _symbol, uint8 _decimals) public ERC20Detailed(_name, _symbol, _decimals) {}

    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}

contract Shifter is Ownable {
    using SafeMath for uint256;

    uint8 public version = 2;

    uint256 constant BIPS_DENOMINATOR = 10000;
    uint256 public minShiftAmount;

    
    ERC20Shifted public token;

    
    address public mintAuthority;

    
    
    
    
    address public feeRecipient;

    
    uint16 public fee;

    
    mapping (bytes32=>bool) public status;

    
    
    uint256 public nextShiftID = 0;

    event LogShiftIn(
        address indexed _to,
        uint256 _amount,
        uint256 indexed _shiftID
    );
    event LogShiftOut(
        bytes _to,
        uint256 _amount,
        uint256 indexed _shiftID,
        bytes indexed _indexedTo
    );

    
    
    
    
    
    
    constructor(ERC20Shifted _token, address _feeRecipient, address _mintAuthority, uint16 _fee, uint256 _minShiftOutAmount) public {
        minShiftAmount = _minShiftOutAmount;
        token = _token;
        mintAuthority = _mintAuthority;
        fee = _fee;
        updateFeeRecipient(_feeRecipient);
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
        
        require(_nextFeeRecipient != address(0x0), "fee recipient cannot be 0x0");

        feeRecipient = _nextFeeRecipient;
    }

    
    
    
    function updateFee(uint16 _nextFee) public onlyOwner {
        fee = _nextFee;
    }

    
    
    
    
    
    
    
    
    
    function shiftIn(bytes32 _pHash, uint256 _amount, bytes32 _nHash, bytes memory _sig) public returns (uint256) {
        
        bytes32 signedMessageHash = hashForSignature(_pHash, _amount, msg.sender, _nHash);
        require(status[signedMessageHash] == false, "nonce hash already spent");
        if (!verifySignature(signedMessageHash, _sig)) {
            
            
            
            revert(
                String.add4(
                    "invalid signature - hash: ",
                    String.fromBytes32(signedMessageHash),
                    ", signer: ",
                    String.fromAddress(ECDSA.recover(signedMessageHash, _sig))
                )
            );
        }
        status[signedMessageHash] = true;

        
        uint256 absoluteFee = (_amount.mul(fee)).div(BIPS_DENOMINATOR);
        uint256 receivedAmount = _amount.sub(absoluteFee);
        token.mint(msg.sender, receivedAmount);
        token.mint(feeRecipient, absoluteFee);

        
        emit LogShiftIn(msg.sender, receivedAmount, nextShiftID);
        nextShiftID += 1;

        return receivedAmount;
    }

    
    
    
    
    
    
    
    
    function shiftOut(bytes memory _to, uint256 _amount) public returns (uint256) {
        
        
        require(_to.length != 0, "to address is empty");
        require(_amount >= minShiftAmount, "amount is less than the minimum shiftOut amount");

        
        uint256 absoluteFee = (_amount.mul(fee)).div(BIPS_DENOMINATOR);
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
    constructor(ERC20Shifted _token, address _feeRecipient, address _mintAuthority, uint16 _fee, uint256 _minShiftOutAmount)
        Shifter(_token, _feeRecipient, _mintAuthority, _fee, _minShiftOutAmount) public {
        }
}

contract ZECShifter is Shifter {
    constructor(ERC20Shifted _token, address _feeRecipient, address _mintAuthority, uint16 _fee, uint256 _minShiftOutAmount)
        Shifter(_token, _feeRecipient, _mintAuthority, _fee, _minShiftOutAmount) public {
        }
}

contract DEXReserve is ERC20 {
    uint256 FeeInBIPS;
    ERC20 public BaseToken;
    ERC20 public Token;
    event LogAddLiquidity(address _liquidityProvider, uint256 _tokenAmount, uint256 _baseTokenAmount);
    event LogDebug(uint256 _rcvAmount);

    constructor (ERC20 _baseToken, ERC20 _token, uint256 _feeInBIPS) public {
        BaseToken = _baseToken;
        Token = _token;
        FeeInBIPS = _feeInBIPS;
    }

    function buy(address _to, address _from, uint256 _baseTokenAmount) external returns (uint256)  {
        require(totalSupply() != 0, "reserve has no funds");
        uint256 rcvAmount = calculateBuyRcvAmt(_baseTokenAmount);
        BaseToken.transferFrom(_from, address(this), _baseTokenAmount);
        require(rcvAmount <= Token.balanceOf(address(this)), "insufficient balance");
        require(Token.transfer(_to, rcvAmount), "failed to transfer quote token");
        return rcvAmount;
    }

    function sell(address _to, address _from, uint256 _tokenAmount) external returns (uint256) {
        require(totalSupply() != 0, "reserve has no funds");
        uint256 rcvAmount = calculateSellRcvAmt(_tokenAmount);
        Token.transferFrom(_from, address(this), _tokenAmount);
        require(BaseToken.transfer(_to, rcvAmount), "failed to transfer base token");
        return rcvAmount;
    }

    function calculateBuyRcvAmt(uint256 _sendAmt) public view returns (uint256) {
        uint256 baseReserve = BaseToken.balanceOf(address(this));
        uint256 tokenReserve = Token.balanceOf(address(this));
        uint256 finalQuoteTokenAmount = (baseReserve.mul(tokenReserve)).div(baseReserve.add(_sendAmt));
        uint256 rcvAmt = tokenReserve.sub(finalQuoteTokenAmount);
        return _removeFees(rcvAmt);
    }

    function calculateSellRcvAmt(uint256 _sendAmt) public view returns (uint256) {
        uint256 baseReserve = BaseToken.balanceOf(address(this));
        uint256 tokenReserve = Token.balanceOf(address(this));
        uint256 finalBaseTokenAmount = (baseReserve.mul(tokenReserve)).div(tokenReserve.add(_sendAmt));
        uint256 rcvAmt = baseReserve.sub(finalBaseTokenAmount);
        return _removeFees(rcvAmt);
    }

    function removeLiquidity(uint256 _liquidity) external returns (uint256, uint256) {
        require(balanceOf(msg.sender) >= _liquidity, "insufficient balance");
        uint256 baseTokenAmount = calculateBaseTokenValue(_liquidity);
        uint256 quoteTokenAmount = calculateQuoteTokenValue(_liquidity);
        _burn(msg.sender, _liquidity);
        BaseToken.transfer(msg.sender, baseTokenAmount);
        Token.transfer(msg.sender, quoteTokenAmount);
        return (baseTokenAmount, quoteTokenAmount);
    }

    function addLiquidity(
        address _liquidityProvider, uint256 _maxBaseToken, uint256 _tokenAmount, uint256 _deadline
        ) external returns (uint256) {
        require(block.number <= _deadline, "addLiquidity request expired");
        if (totalSupply() > 0) {
            require(_tokenAmount > 0, "token amount is less than allowed min amount");
            uint256 baseAmount = expectedBaseTokenAmount(_tokenAmount);
            require(baseAmount <= _maxBaseToken, "calculated base amount exceeds the maximum amount set");
            require(BaseToken.transferFrom(_liquidityProvider, address(this), baseAmount), "failed to transfer base token");
            emit LogAddLiquidity(_liquidityProvider, _tokenAmount, baseAmount);
        } else {
            require(BaseToken.transferFrom(_liquidityProvider, address(this), _maxBaseToken), "failed to transfer base token");
            emit LogAddLiquidity(_liquidityProvider, _tokenAmount, _maxBaseToken);
        }
        Token.transferFrom(msg.sender, address(this), _tokenAmount);
        _mint(_liquidityProvider, _tokenAmount*2);
        return _tokenAmount*2;
    }

    function calculateBaseTokenValue(uint256 _liquidity) public view returns (uint256) {
        require(totalSupply() != 0, "Division by Zero");
        uint256 baseReserve = BaseToken.balanceOf(address(this));
        return (_liquidity * baseReserve)/totalSupply();
    }

    function calculateQuoteTokenValue(uint256 _liquidity) public view returns (uint256) {
        require(totalSupply() != 0, "Division by Zero");
        uint256 tokenReserve = Token.balanceOf(address(this));
        return (_liquidity * tokenReserve)/totalSupply();
    }

    function expectedBaseTokenAmount(uint256 _quoteTokenAmount) public view returns (uint256) {
        uint256 baseReserve = BaseToken.balanceOf(address(this));
        uint256 tokenReserve = Token.balanceOf(address(this));
        return (_quoteTokenAmount * baseReserve)/tokenReserve;
    }

    function _removeFees(uint256 _amount) internal view returns (uint256) {
        return (_amount * (10000 - FeeInBIPS))/10000;
    }
}

contract BTC_DAI_Reserve is DEXReserve {
    constructor (ERC20 _baseToken, ERC20 _token, uint256 _feeInBIPS) public DEXReserve(_baseToken, _token, _feeInBIPS) {
    }
}

contract ZEC_DAI_Reserve is DEXReserve {
    constructor (ERC20 _baseToken, ERC20 _token, uint256 _feeInBIPS) public DEXReserve(_baseToken, _token, _feeInBIPS) {
    }
}

contract DEX {
    mapping (address=>DEXReserve) public reserves;
    address public BaseToken;
    address public ethereum = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    event LogTrade(address _src, address _dst, uint256 _sendAmount, uint256 _recvAmount);

    constructor(address _baseToken) public {
        BaseToken = _baseToken;
    }

    
    
    function recoverTokens(address _token) external {
        if (_token == address(0x0)) {
            msg.sender.transfer(address(this).balance);
        } else {
            ERC20(_token).transfer(msg.sender, ERC20(_token).balanceOf(address(this)));
        }
    }

    function registerReserve(address _erc20, DEXReserve _reserve) external {
        require(reserves[_erc20] == DEXReserve(0x0), "token reserve already registered");
        reserves[_erc20] = _reserve;
    }

    function trade(address _to, address _src, address _dst, uint256 _sendAmount) public returns (uint256) {
        uint256 recvAmount;
        if (_src == BaseToken) {
            require(reserves[_dst] != DEXReserve(0x0), "unsupported token");
            recvAmount = reserves[_dst].buy(_to, msg.sender, _sendAmount);
        } else if (_dst == BaseToken) {
            require(reserves[_src] != DEXReserve(0x0), "unsupported token");
            recvAmount = reserves[_src].sell(_to, msg.sender, _sendAmount);
        } else {
            require(reserves[_src] != DEXReserve(0x0) && reserves[_dst] != DEXReserve(0x0), "unsupported token");
            uint256 intermediteAmount = reserves[_src].sell(address(this), msg.sender, _sendAmount);
            ERC20(BaseToken).approve(address(reserves[_dst]), intermediteAmount);
            recvAmount = reserves[_dst].buy(_to, address(this), intermediteAmount);
        }
        emit LogTrade(_src, _dst, _sendAmount, recvAmount);
        return recvAmount;
    }

    function calculateReceiveAmount(address _src, address _dst, uint256 _sendAmount) public view returns (uint256) {
        if (_src == BaseToken) {
            return reserves[_dst].calculateBuyRcvAmt(_sendAmount);
        }
        if (_dst == BaseToken) {
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
        require(!isInList(self, newNode), "already in list");
        require(isInList(self, target) || target == NULL, "not in list");

        
        address prev = self.list[target].previous;

        self.list[newNode].next = target;
        self.list[newNode].previous = prev;
        self.list[target].previous = newNode;
        self.list[prev].next = newNode;

        self.list[newNode].inList = true;
    }

    
    function insertAfter(List storage self, address target, address newNode) internal {
        require(!isInList(self, newNode), "already in list");
        require(isInList(self, target) || target == NULL, "not in list");

        
        address n = self.list[target].next;

        self.list[newNode].previous = target;
        self.list[newNode].next = n;
        self.list[target].next = newNode;
        self.list[n].previous = newNode;

        self.list[newNode].inList = true;
    }

    
    function remove(List storage self, address node) internal {
        require(isInList(self, node), "not in list");
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
        require(isInList(self, node), "not in list");
        return self.list[node].next;
    }

    function previous(List storage self, address node) internal view returns (address) {
        require(isInList(self, node), "not in list");
        return self.list[node].previous;
    }

}

interface IShifter {
    function shiftIn(bytes32 _pHash, uint256 _amount, bytes32 _nHash, bytes calldata _sig) external returns (uint256);
    function shiftOut(bytes calldata _to, uint256 _amount) external returns (uint256);
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

    
    
    
    
    
    function setShifter(address _tokenAddress, address _shifterAddress) external onlyOwner {
        
        require(!LinkedList.isInList(shifterList, _shifterAddress), "shifter already registered");
        require(shifterByToken[_tokenAddress] == address(0x0), "token already registered");
        string memory symbol = ERC20Shifted(_tokenAddress).symbol();
        require(tokenBySymbol[symbol] == address(0x0), "symbol already registered");

        
        LinkedList.append(shifterList, _shifterAddress);

        
        LinkedList.append(shiftedTokenList, _tokenAddress);

        tokenBySymbol[symbol] = _tokenAddress;
        shifterByToken[_tokenAddress] = _shifterAddress;
        numShifters += 1;

        emit LogShifterRegistered(symbol, symbol, _tokenAddress, _shifterAddress);
    }

    
    
    
    
    
    function updateShifter(address _tokenAddress, address _newShifterAddress) external onlyOwner {
        
        address currentShifter = shifterByToken[_tokenAddress];
        require(shifterByToken[_tokenAddress] != address(0x0), "token not registered");

        
        LinkedList.remove(shifterList, currentShifter);

        
        LinkedList.append(shifterList, _newShifterAddress);

        shifterByToken[_tokenAddress] = _newShifterAddress;

        emit LogShifterUpdated(_tokenAddress, currentShifter, _newShifterAddress);
    }

    
    
    
    
    function removeShifter(string calldata _symbol) external onlyOwner {
        
        address tokenAddress = tokenBySymbol[_symbol];
        require(tokenAddress != address(0x0), "symbol not registered");

        
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

    function encodePayload(
         ERC20 _src, ERC20 _dst, uint256 _minDstAmt, bytes memory _to,
        uint256 _refundBN, bytes memory _refundAddress
    ) public pure returns (bytes memory) {
        return abi.encode(_src, _dst, _minDstAmt, _to, _refundBN, _refundAddress);
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
            require(ERC20(dex.BaseToken()).allowance(_liquidityProvider, address(reserve)) >= _maxBaseToken,
                "insufficient base token allowance");
            uint256 transferredAmount = _transferIn(_token, _amount, _nHash, lpHash, _sig);
            ERC20(_token).approve(address(reserve), transferredAmount);
            return reserve.addLiquidity(_liquidityProvider, _maxBaseToken, transferredAmount, _deadline);
    }

    function removeLiquidity(address _token, uint256 _liquidity, bytes calldata _tokenAddress) external {
        DEXReserve reserve = dex.reserves(_token);
        require(reserve != DEXReserve(0x0), "unsupported token");
        reserve.transferFrom(msg.sender, address(this), _liquidity);
        (uint256 baseTokenAmount, uint256 quoteTokenAmount) = reserve.removeLiquidity(_liquidity);
        reserve.BaseToken().transfer(msg.sender, baseTokenAmount);
        shifterRegistry.getShifterByToken(address(reserve.Token())).shiftOut(_tokenAddress, quoteTokenAmount);
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

        if (_src == dex.BaseToken()) {
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
        } else if (_src == dex.ethereum()) {
            require(msg.value >= _amount, "insufficient eth amount");
            return msg.value;
        } else {
            require(ERC20(_src).transferFrom(msg.sender, address(this), _amount), "source token transfer failed");
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
        return dex.calculateReceiveAmount(_src, _dst, _sendAmount);
    }
}