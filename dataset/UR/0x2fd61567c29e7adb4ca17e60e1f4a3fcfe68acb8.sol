 

 

 
  

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
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

     
     
     
}

 
  
contract Delegable is Ownable {
    address private _delegator;
    
    event DelegateAppointed(address indexed previousDelegator, address indexed newDelegator);
    
    constructor () internal {
        _delegator = address(0);
    }
    
     
     
    function delegator() public view returns (address) {
        return _delegator;
    }
    
     
     
    modifier onlyDelegator() {
        require(isDelegator());
        _;
    }
    
     
     
    modifier ownerOrDelegator() {
        require(isOwner() || isDelegator());
        _;
    }
    
    function isDelegator() public view returns (bool) {
        return msg.sender == _delegator;
    }
    
     
     
    function appointDelegator(address delegator) public onlyOwner returns (bool) {
        require(delegator != address(0));
        require(delegator != owner());
        return _appointDelegator(delegator);
    }
    
     
     
    function dissmissDelegator() public onlyOwner returns (bool) {
        require(_delegator != address(0));
        return _appointDelegator(address(0));
    }
    
     
     
    function _appointDelegator(address delegator) private returns (bool) {
        require(_delegator != delegator);
        emit DelegateAppointed(_delegator, delegator);
        _delegator = delegator;
        return true;
    }
}

 
  
contract ERC20Like is IERC20, Delegable {
    using SafeMath for uint256;

    uint256 internal _totalSupply;   
    bool isLock = false;   

     
     
    struct TokenContainer {
        uint256 chargeAmount;  
        uint256 unlockAmount;  
        uint256 balance;   
        mapping (address => uint256) allowed;  
    }

    mapping (address => TokenContainer) internal _tokenContainers;
    
    event ChangeCirculation(uint256 circulationAmount);
    event Charge(address indexed holder, uint256 chargeAmount, uint256 unlockAmount);
    event IncreaseUnlockAmount(address indexed holder, uint256 unlockAmount);
    event DecreaseUnlockAmount(address indexed holder, uint256 unlockAmount);
    event Exchange(address indexed holder, address indexed exchangeHolder, uint256 amount);
    event Withdraw(address indexed holder, uint256 amount);

     
     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
     
    function balanceOf(address holder) public view returns (uint256) {
        return _tokenContainers[holder].balance;
    }

     
     
    function allowance(address holder, address spender) public view returns (uint256) {
        return _tokenContainers[holder].allowed[spender];
    }

     
     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _tokenContainers[from].allowed[msg.sender].sub(value));
        return true;
    }

     
     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(!isLock);
        uint256 value = _tokenContainers[msg.sender].allowed[spender].add(addedValue);
        if (msg.sender == owner()) {   
            require(_tokenContainers[msg.sender].chargeAmount >= _tokenContainers[msg.sender].unlockAmount.add(addedValue));
            _tokenContainers[msg.sender].unlockAmount = _tokenContainers[msg.sender].unlockAmount.add(addedValue);
            _tokenContainers[msg.sender].balance = _tokenContainers[msg.sender].balance.add(addedValue);
        }
        _approve(msg.sender, spender, value);
        return true;
    }

     
     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(!isLock);
         
         
        if (_tokenContainers[msg.sender].allowed[spender] < subtractedValue) {
            subtractedValue = _tokenContainers[msg.sender].allowed[spender];
        }
        
        uint256 value = _tokenContainers[msg.sender].allowed[spender].sub(subtractedValue);
        if (msg.sender == owner()) {   
            _tokenContainers[msg.sender].unlockAmount = _tokenContainers[msg.sender].unlockAmount.sub(subtractedValue);
            _tokenContainers[msg.sender].balance = _tokenContainers[msg.sender].balance.sub(subtractedValue);
        }
        _approve(msg.sender, spender, value);
        return true;
    }

     
     
    function _transfer(address from, address to, uint256 value) private {
        require(!isLock);
         
         
        require(to != address(this));
        require(to != address(0));

        _tokenContainers[from].balance = _tokenContainers[from].balance.sub(value);
        _tokenContainers[to].balance = _tokenContainers[to].balance.add(value);
        emit Transfer(from, to, value);
    }

     
     
    function _approve(address holder, address spender, uint256 value) private {
        require(!isLock);
        require(spender != address(0));
        require(holder != address(0));

        _tokenContainers[holder].allowed[spender] = value;
        emit Approval(holder, spender, value);
    }

     
     
     
    function chargeAmountOf(address holder) external view returns (uint256) {
        return _tokenContainers[holder].chargeAmount;
    }

     
     
    function unlockAmountOf(address holder) external view returns (uint256) {
        return _tokenContainers[holder].unlockAmount;
    }

     
     
    function availableBalanceOf(address holder) external view returns (uint256) {
        return _tokenContainers[holder].balance;
    }

     
     
    function receiptAccountOf(address holder) external view returns (string memory) {
        bytes memory blockStart = bytes("{");
        bytes memory chargeLabel = bytes("\"chargeAmount\" : \"");
        bytes memory charge = bytes(uint2str(_tokenContainers[holder].chargeAmount));
        bytes memory unlockLabel = bytes("\", \"unlockAmount\" : \"");
        bytes memory unlock = bytes(uint2str(_tokenContainers[holder].unlockAmount));
        bytes memory balanceLabel = bytes("\", \"availableBalance\" : \"");
        bytes memory balance = bytes(uint2str(_tokenContainers[holder].balance));
        bytes memory blockEnd = bytes("\"}");

        string memory receipt = new string(blockStart.length + chargeLabel.length + charge.length + unlockLabel.length + unlock.length + balanceLabel.length + balance.length + blockEnd.length);
        bytes memory receiptBytes = bytes(receipt);

        uint readIndex = 0;
        uint writeIndex = 0;

        for (readIndex = 0; readIndex < blockStart.length; readIndex++) {
            receiptBytes[writeIndex++] = blockStart[readIndex];
        }
        for (readIndex = 0; readIndex < chargeLabel.length; readIndex++) {
            receiptBytes[writeIndex++] = chargeLabel[readIndex];
        }
        for (readIndex = 0; readIndex < charge.length; readIndex++) {
            receiptBytes[writeIndex++] = charge[readIndex];
        }
        for (readIndex = 0; readIndex < unlockLabel.length; readIndex++) {
            receiptBytes[writeIndex++] = unlockLabel[readIndex];
        }
        for (readIndex = 0; readIndex < unlock.length; readIndex++) {
            receiptBytes[writeIndex++] = unlock[readIndex];
        }
        for (readIndex = 0; readIndex < balanceLabel.length; readIndex++) {
            receiptBytes[writeIndex++] = balanceLabel[readIndex];
        }
        for (readIndex = 0; readIndex < balance.length; readIndex++) {
            receiptBytes[writeIndex++] = balance[readIndex];
        }
        for (readIndex = 0; readIndex < blockEnd.length; readIndex++) {
            receiptBytes[writeIndex++] = blockEnd[readIndex];
        }

        return string(receiptBytes);
    }

     
     
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
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

     
     
    function circulationAmount() external view returns (uint256) {
        return _tokenContainers[owner()].unlockAmount;
    }

     
     
     
     
    function increaseCirculation(uint256 amount) external onlyOwner returns (uint256) {
        require(!isLock);
        require(_tokenContainers[msg.sender].chargeAmount >= _tokenContainers[msg.sender].unlockAmount.add(amount));
        _tokenContainers[msg.sender].unlockAmount = _tokenContainers[msg.sender].unlockAmount.add(amount);
        _tokenContainers[msg.sender].balance = _tokenContainers[msg.sender].balance.add(amount);
        emit ChangeCirculation(_tokenContainers[msg.sender].unlockAmount);
        return _tokenContainers[msg.sender].unlockAmount;
    }

     
     
     
     
    function decreaseCirculation(uint256 amount) external onlyOwner returns (uint256) {
        require(!isLock);
        _tokenContainers[msg.sender].unlockAmount = _tokenContainers[msg.sender].unlockAmount.sub(amount);
        _tokenContainers[msg.sender].balance = _tokenContainers[msg.sender].balance.sub(amount);
        emit ChangeCirculation(_tokenContainers[msg.sender].unlockAmount);
        return _tokenContainers[msg.sender].unlockAmount;
    }

     
     
    function charge(address holder, uint256 chargeAmount, uint256 unlockAmount) external ownerOrDelegator {
        require(!isLock);
        require(holder != address(0));
        require(holder != owner());
        require(chargeAmount > 0);
        require(chargeAmount >= unlockAmount);
        require(_tokenContainers[owner()].balance >= chargeAmount);

        _tokenContainers[owner()].balance = _tokenContainers[owner()].balance.sub(chargeAmount);

        _tokenContainers[holder].chargeAmount = _tokenContainers[holder].chargeAmount.add(chargeAmount);
        _tokenContainers[holder].unlockAmount = _tokenContainers[holder].unlockAmount.add(unlockAmount);
        _tokenContainers[holder].balance = _tokenContainers[holder].balance.add(unlockAmount);
        
        emit Charge(holder, chargeAmount, unlockAmount);
    }
    
     
     
    function increaseUnlockAmount(address holder, uint256 unlockAmount) external ownerOrDelegator {
        require(!isLock);
        require(holder != address(0));
        require(holder != owner());
        require(_tokenContainers[holder].chargeAmount >= _tokenContainers[holder].unlockAmount.add(unlockAmount));

        _tokenContainers[holder].unlockAmount = _tokenContainers[holder].unlockAmount.add(unlockAmount);
        _tokenContainers[holder].balance = _tokenContainers[holder].balance.add(unlockAmount);
        
        emit IncreaseUnlockAmount(holder, unlockAmount);
    }
    
     
     
    function decreaseUnlockAmount(address holder, uint256 lockAmount) external ownerOrDelegator {
        require(!isLock);
        require(holder != address(0));
        require(holder != owner());
        require(_tokenContainers[holder].balance >= lockAmount);

        _tokenContainers[holder].unlockAmount = _tokenContainers[holder].unlockAmount.sub(lockAmount);
        _tokenContainers[holder].balance = _tokenContainers[holder].balance.sub(lockAmount);
        
        emit DecreaseUnlockAmount(holder, lockAmount);
    }

     
     
    function unlockAmountAll(address holder) external ownerOrDelegator {
        require(!isLock);
        require(holder != address(0));
        require(holder != owner());

        uint256 unlockAmount = _tokenContainers[holder].chargeAmount.sub(_tokenContainers[holder].unlockAmount);

        require(unlockAmount > 0);
        
        _tokenContainers[holder].unlockAmount = _tokenContainers[holder].unlockAmount.add(unlockAmount);
        _tokenContainers[holder].balance = _tokenContainers[holder].balance.add(unlockAmount);
    }

     
     
    function lock() external onlyOwner returns (bool) {
        isLock = true;
        return isLock;
    }

     
     
    function unlock() external onlyOwner returns (bool) {
        isLock = false;
        return isLock;
    }
    
     
     
    function exchange(address holder) external onlyDelegator returns (bool) {
        require(isLock);     
        require((delegator() == msg.sender) && isContract(msg.sender));     
        
        uint256 balance = _tokenContainers[holder].balance;
        _tokenContainers[holder].balance = 0;
        _tokenContainers[msg.sender].balance = _tokenContainers[msg.sender].balance.add(balance);
        
        emit Exchange(holder, msg.sender, balance);
        return true;
    }
    
     
     
    function withdraw() external onlyDelegator returns (bool) {
        require(isLock);     
        require((delegator() == msg.sender) && isContract(msg.sender));     
        
        uint256 balance = _tokenContainers[msg.sender].balance;
        _tokenContainers[msg.sender].balance = 0;
        _tokenContainers[owner()].balance = _tokenContainers[owner()].balance.add(balance);
        
        emit Withdraw(msg.sender, balance);
    }
    
     
     
    function isContract(address addr) private returns (bool) {
      uint size;
      assembly { size := extcodesize(addr) }
      return size > 0;
    }
}

contract SymToken is ERC20Like {
    string public name = "SymVerse";
    string public symbol = "SYM";
    uint256 public decimals = 18;

    constructor () public {
        _totalSupply = 1000000000 * (10 ** decimals);
        _tokenContainers[msg.sender].chargeAmount = _totalSupply;
        emit Charge(msg.sender, _tokenContainers[msg.sender].chargeAmount, _tokenContainers[msg.sender].unlockAmount);
    }
}