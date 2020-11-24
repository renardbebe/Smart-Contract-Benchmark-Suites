 

pragma solidity 0.5.7;

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

 
 
 
 
 
 
 
 
 
 
 
 
 
 

 
 
 
contract SafeMath {
    uint256 constant private MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd (uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert (x <= MAX_UINT256 - y);
        return x + y;
    }

    function safeSub (uint256 x, uint256 y) internal pure returns (uint256 z) {
        assert (x >= y);
        return x - y;
    }

    function safeMul (uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (y == 0) return 0;
        assert (x <= MAX_UINT256 / y);
        return x * y;
    }
}

 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

 
 
 
contract Owned {
    address internal owner;
    address internal ownerToTransferTo;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        ownerToTransferTo = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == ownerToTransferTo);
        emit OwnershipTransferred(owner, ownerToTransferTo);
        owner = ownerToTransferTo;
        ownerToTransferTo = address(0);
    }
}

 
 
 
contract Pausable is Owned {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier notPaused() {
        require(!paused, "this contract is suspened, come later");
        _;
    }

    modifier whenPaused() {
        require(paused, "contract must be paused");
        _;
    }

    function pause() public onlyOwner notPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

 
 
 
contract TransferFee is Owned, SafeMath {

    event ChangedFee (
        uint256 fixedFee,
        uint256 minVariableFee,
        uint256 maxVariableFee,
        uint256 variableFee
    );

     
    uint256 constant internal VARIABLE_FEE_DENOMINATOR = 100000;

    mapping (address => bool) internal zeroFeeAddress;
    address internal feeCollector;  
    uint256 internal flatFee;  
    uint256 internal variableFee;  
    uint256 internal minVariableFee;  
    uint256 internal maxVariableFee;  

    constructor () public {
        flatFee = 0;  
        variableFee = 100;  
        minVariableFee = 0;  
        maxVariableFee =   
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff - flatFee;
        feeCollector = owner;

        zeroFeeAddress[address(this)] = true;
    }

    function calculateFee (address from, address to, uint256 amount) public view returns (uint256 _fee) {
        if (zeroFeeAddress[from] || from == owner) return 0;
        if (zeroFeeAddress[to] || to == owner) return 0;

        _fee = safeMul (amount, variableFee) / VARIABLE_FEE_DENOMINATOR;
        if (_fee < minVariableFee) _fee = minVariableFee;
        if (_fee > maxVariableFee) _fee = maxVariableFee;
        _fee = safeAdd (_fee, flatFee);
    }

    function setFeeCollector (address _newFeeCollector) public onlyOwner {
        feeCollector = _newFeeCollector;
    }

    function setZeroFee (address _address) public onlyOwner {
        zeroFeeAddress [_address] = true;
    }

    function getFeeParameters () public view returns (
        uint256 _flatFee,
        uint256 _minVariableFee,
        uint256 _maxVariableFee,
        uint256 _variableFee) 
    {
        _flatFee = flatFee;
        _minVariableFee = minVariableFee;
        _maxVariableFee = maxVariableFee;
        _variableFee = variableFee;
    }

    function setFeeParameters (
        uint256 _flatFee,
        uint256 _minVariableFee,
        uint256 _maxVariableFee,
        uint256 _variableFee) public onlyOwner
    {
        require (_minVariableFee <= _maxVariableFee, "minimum variable fee should be less than maximum one");
        require (_variableFee <= VARIABLE_FEE_DENOMINATOR, "variable fee should be less than 100%");

        flatFee = _flatFee;
        minVariableFee = _minVariableFee;
        maxVariableFee = _maxVariableFee;
        variableFee = _variableFee;

        emit ChangedFee (_flatFee, _minVariableFee, _maxVariableFee, _variableFee);
    }
}

 
 
 
 
contract EuPi is IERC20, Owned, Pausable, SafeMath, TransferFee {
    string public constant symbol = "EuPi";
    string public constant name = "EuPi";
    uint8 public constant decimals = 18;  
    
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowed;

     
     
     
    constructor() public {
         
        _totalSupply = 100000000000000000000000000;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

     
     
     
    function totalSupply() public view returns (uint256) {
        return _totalSupply - _balances[address(0)];
    }

     
     
     
    function balanceOf(address tokenOwner) public view returns (uint256 balance) {
        return _balances[tokenOwner];
    }

     
     
     
     
     
     
    function noFeeTransfer(address to, uint256 tokens) internal returns (bool success) {
        require(to != address(0), "not zero address is required");

        uint256 fromBalance = _balances [msg.sender];
        if (fromBalance < tokens) return false;
        if (tokens > 0 && msg.sender != to) {
            _balances [msg.sender] = safeSub (fromBalance, tokens);
            _balances [to] = safeAdd (_balances [to], tokens);
        }
         
        emit Transfer (msg.sender, to, tokens);
        return true;
    }

    function transfer(address to, uint256 tokens) public notPaused returns (bool success) {
        uint256 fee = calculateFee (msg.sender, to, tokens);
        if (tokens <= _balances [msg.sender] &&
          fee <= safeSub (_balances [msg.sender], tokens)) {
             
            assert (noFeeTransfer (to, tokens));
            assert (noFeeTransfer (feeCollector, fee));
            return true;
        } else return false;
    }

     
     
     
     
     
     
     
    function approve(address spender, uint256 tokens) public notPaused 
    returns (bool success) {
        _allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
     
    function noFeeTransferFrom (address from, address to, uint256 tokens) 
    internal returns (bool success) {
        require(to != address(0), "not zero address is required");

        uint256 allowance = _allowed [from][msg.sender];
        if (allowance < tokens) return false;
        uint256 fromBalance = _balances [from];
        if (fromBalance < tokens) return false;

        if (tokens > 0 && from != to) {
            _balances [from] = safeSub (fromBalance, tokens);
            _allowed [from][msg.sender] = safeSub (allowance, tokens);
            _balances [to] = safeAdd (_balances [to], tokens);
        }
         
        emit Transfer (from, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public notPaused 
    returns (bool success) {
        require(to != address(0), "not zero address is required");
        
        uint256 fee = calculateFee (msg.sender, to, tokens);
        uint256 fromBalance = _balances [from];
        uint256 allowance = _allowed [from][msg.sender];

         
         
         
        if (
            tokens <= allowance && fee <= safeSub (allowance, tokens) && 
            tokens <= fromBalance && fee <= safeSub (fromBalance, tokens)
            )
        {
             
            assert (noFeeTransferFrom (from, to, tokens));
            assert (noFeeTransferFrom (from, feeCollector, fee));
            return true;
        } else return false;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public view 
    returns (uint256 remaining) {
        return _allowed[tokenOwner][spender];
    }

     
     
     
     
     
     
    function approveAndCall(address spender, uint256 tokens, bytes memory data) public notPaused
    returns (bool _success) {
        _allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

     
     
     
     
     
    function increaseApproval(address spender, uint256 addedValue) public notPaused 
    returns (bool) {
        _allowed[msg.sender][spender] = (
            safeAdd(_allowed[msg.sender][spender], addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
     
     
     
     
    function decreaseApproval(address spender, uint256 substractedValue) public notPaused
    returns (bool) {
        uint256 oldValue = _allowed[msg.sender][spender];
        if (substractedValue > oldValue) {
            _allowed[msg.sender][spender] = 0;
        } else {
            _allowed[msg.sender][spender] = safeSub(oldValue, substractedValue);
        }
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
     
     
     
    function claimERC20(address tokenAddress, address to, uint256 amount) public onlyOwner returns (bool _success) {
        return 
            IERC20(tokenAddress).transfer(
                to,
                amount > 0 ? amount : 
                    IERC20(tokenAddress).balanceOf(address(this))
            );
    }

    function claimETH(address payable to, uint256 amount) public returns (bool _success) {
        require(msg.sender == owner);
        return to.send(amount);
    }
}