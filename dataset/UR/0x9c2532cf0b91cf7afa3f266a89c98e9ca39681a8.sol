 

pragma solidity ^0.4.24;

 
 
 
 
contract PLAYToken {
     
     
     
     
    event Transfer (address indexed from, address indexed to, uint tokens);

     
     
     
     
     
    event Approval (
        address indexed tokenOwner, 
        address indexed spender, 
        uint tokens
    );
    
     
     
    uint totalPLAY = 1000000000 * 10**18;     
     
    mapping (address => uint) playBalances;
     
    mapping (address => mapping (address => uint)) allowances;

    constructor() public {
        playBalances[msg.sender] = totalPLAY;
    }

     
     
     
    modifier notZero(uint param) {
        require (param != 0, "Parameter cannot be zero");
        _;
    }
    
     
     
     
    modifier sufficientFunds(address tokenOwner, uint tokens) {
        require (playBalances[tokenOwner] >= tokens, "Insufficient balance");
        _;
    }
    
     
     
     
    modifier sufficientAllowance(address owner, address spender, uint tokens) {
        require (
            allowances[owner][spender] >= tokens, 
            "Insufficient allowance"
        );
        _;
    }

     
     
     
     
     
     
     
     
    function transfer(address to, uint tokens) 
        public 
        notZero(uint(to)) 
        notZero(tokens)
        sufficientFunds(msg.sender, tokens)
        returns(bool) 
    {
         
        playBalances[msg.sender] -= tokens;
         
        playBalances[to] += tokens;
         
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) 
        public 
        notZero(uint(to)) 
        notZero(tokens) 
        sufficientFunds(from, tokens)
        sufficientAllowance(from, msg.sender, tokens)
        returns(bool) 
    {
         
        allowances[from][msg.sender] -= tokens;
         
        playBalances[from] -= tokens;
         
        playBalances[to] += tokens;
         
        emit Transfer(from, to, tokens);

        return true;
    }

     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) external returns(bool) {
         
        allowances[msg.sender][spender] = tokens;
         
        emit Approval(msg.sender, spender, tokens);

        return true;
    }

     
     
     
     
    function totalSupply() external view returns (uint) { return totalPLAY; }

     
     
     
     
     
     
    function balanceOf(address tokenOwner) 
        public 
        view 
        notZero(uint(tokenOwner))
        returns(uint)
    {
        return playBalances[tokenOwner];
    }

     
     
     
     
     
     
    function allowance(
        address tokenOwner, 
        address spender
    ) public view returns (uint) {
        return allowances[tokenOwner][spender];
    }

     
     
     
     
    function name() external pure returns (string) { 
        return "PLAY Network Token"; 
    }

     
     
     
     
    function symbol() external pure returns (string) { return "PLAY"; }

     
     
     
     
    function decimals() external pure returns (uint8) { return 18; }
}


 
 
 
 
contract BurnToken is PLAYToken {
     
     
     
     
     
     
     
     
    function burn(uint tokens)
        external 
        notZero(tokens) 
        sufficientFunds(msg.sender, tokens)
        returns(bool) 
    {
         
        playBalances[msg.sender] -= tokens;
         
        totalPLAY -= tokens;
         
        emit Transfer(msg.sender, address(0), tokens);

        return true;
    }

     
     
     
     
     
     
     
     
     
     
     
    function burnFrom(address from, uint tokens) 
        external 
        notZero(tokens) 
        sufficientFunds(from, tokens)
        sufficientAllowance(from, msg.sender, tokens)
        returns(bool) 
    {
         
        allowances[from][msg.sender] -= tokens;
         
        playBalances[from] -= tokens;
         
        totalPLAY -= tokens;
         
        emit Transfer(from, address(0), tokens);

        return true;
    }
}


 
 
 
 
contract LockToken is BurnToken {
     
     
     
     
    event Lock (address indexed tokenOwner, uint tokens);

     
     
     
    event Unlock (address indexed tokenOwner, uint tokens);

     
     
    uint constant FIRST_YEAR_TIMESTAMP = 1514764800;
     
    uint public currentYear;
     
    uint public maximumLockYears = 10;
     
    mapping (address => mapping(uint => uint)) tokensLockedUntilYear;

     
     
     
     
     
     
     
     
     
    function lock(uint numberOfYears, uint tokens) 
        public 
        notZero(tokens)
        sufficientFunds(msg.sender, tokens)
        returns(bool)
    {
         
        require (
            numberOfYears > 0 && numberOfYears <= maximumLockYears,
            "Invalid number of years"
        );

         
        playBalances[msg.sender] -= tokens;
         
        tokensLockedUntilYear[msg.sender][currentYear+numberOfYears] += tokens;
         
        emit Lock(msg.sender, tokens);

        return true;
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function lockFrom(address from, uint numberOfYears, uint tokens) 
        external
        notZero(tokens)
        sufficientFunds(from, tokens)
        sufficientAllowance(from, msg.sender, tokens)
        returns(bool) 
    {
         
        require (
            numberOfYears > 0 && numberOfYears <= maximumLockYears,
            "Invalid number of years"
        );

         
        allowances[from][msg.sender] -= tokens;
         
        playBalances[from] -= tokens;
         
        tokensLockedUntilYear[from][currentYear + numberOfYears] += tokens;
         
        emit Lock(from, tokens);
        
        return true;
    }

     
     
     
     
     
     
     
     
     
     
    function transferAndLock(
        address to, 
        uint numberOfYears, 
        uint tokens
    ) external {
         
        transfer(to, tokens);

         
        playBalances[to] -= tokens;
         
        tokensLockedUntilYear[to][currentYear + numberOfYears] += tokens;
         
        emit Lock(msg.sender, tokens);
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function transferFromAndLock(
        address from, 
        address to, 
        uint numberOfYears, 
        uint tokens
    ) external {
         
         
        transferFrom(from, to, tokens);

         
        playBalances[to] -= tokens;
         
        tokensLockedUntilYear[to][currentYear + numberOfYears] += tokens;
         
        emit Lock(msg.sender, tokens);
    }

     
     
     
     
     
     
     
    function unlockAll(address tokenOwner) external {
         
        address addressToUnlock = tokenOwner;
         
        if (addressToUnlock == address(0)) {
            addressToUnlock = msg.sender;
        }
         
        if (msg.sender != addressToUnlock) {
            require (
                allowances[addressToUnlock][msg.sender] > 0,
                "Not authorized to unlock for this address"
            );
        }

         
        uint tokensToUnlock;
         
        for (uint i = 1; i <= currentYear; ++i) {
             
            tokensToUnlock += tokensLockedUntilYear[addressToUnlock][i];
             
            tokensLockedUntilYear[addressToUnlock][i] = 0;
        }
         
        playBalances[addressToUnlock] += tokensToUnlock;
         
        emit Unlock (addressToUnlock, tokensToUnlock);
    }

     
     
     
     
     
     
     
     
    function unlockByYear(address tokenOwner, uint year) external {
         
        address addressToUnlock = tokenOwner;
         
        if (addressToUnlock == address(0)) {
            addressToUnlock = msg.sender;
        }
         
        if (msg.sender != addressToUnlock) {
            require (
                allowances[addressToUnlock][msg.sender] > 0,
                "Not authorized to unlock for this address"
            );
        }
         
        require (
            currentYear >= year,
            "Tokens from this year cannot be unlocked yet"
        );
         
        uint tokensToUnlock = tokensLockedUntilYear[addressToUnlock][year];
         
        tokensLockedUntilYear[addressToUnlock][year] = 0;
         
        playBalances[addressToUnlock] += tokensToUnlock;
         
        emit Unlock(addressToUnlock, tokensToUnlock);
    }

     
     
     
     
    function updateYearsSinceRelease() external {
         
        uint secondsSinceRelease = block.timestamp - FIRST_YEAR_TIMESTAMP;
        require (
            currentYear < secondsSinceRelease / (365 * 1 days),
            "Cannot update year yet"
        );
         
        ++currentYear;
    }

     
     
     
     
     
    function getTotalLockedTokens(
        address tokenOwner
    ) public view returns (uint lockedTokens) {
        for (uint i = 1; i < currentYear + maximumLockYears; ++i) {
            lockedTokens += tokensLockedUntilYear[tokenOwner][i];
        }
    }

     
     
     
     
     
     
     
    function getLockedTokensByYear(
        address tokenOwner, 
        uint year
    ) external view returns (uint) {
        return tokensLockedUntilYear[tokenOwner][year];
    }
}


 
 
 
 
 
 
contract Ownable {
     
     
     
    event OwnershipTransfer (address previousOwner, address newOwner);
    
     
    address owner;
    
     
     
     
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransfer(address(0), owner);
    }

     
     
     
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Function can only be called by contract owner"
        );
        _;
    }

     
     
     
     
     
    function transferOwnership(address _newOwner) public onlyOwner {
         
        require (
            _newOwner != address(0),
            "New owner address cannot be zero"
        );
         
        address oldOwner = owner;
         
        owner = _newOwner;
         
        emit OwnershipTransfer(oldOwner, _newOwner);
    }
}


 
 
 
interface ToyTokenOwnership {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(
        address _owner, 
        address _operator
    ) external view returns (bool);
}


 
 
 
 
 
contract ColorToken is LockToken, Ownable {
     
     
     
    event NewColor(address indexed creator, string name);

     
     
     
     
    event DepositColor(
        uint indexed to, 
        uint indexed colorIndex, 
        uint tokens
    );

     
     
     
     
    event SpendColor(
        uint indexed from, 
        uint indexed color, 
        uint amount
    );

     
    struct ColoredToken {
        address creator;
        string name;
        mapping (uint => uint) balances;
    }

     
    ColoredToken[] coloredTokens;
     
    uint public requiredLockedForColorRegistration = 10000 * 10**18;
     
    ToyTokenOwnership toy;
     
    uint constant UID_MAX = 0xFFFFFFFFFFFFFF;

     
     
     
     
     
    function setToyTokenContractAddress (address toyAddress) 
        external 
        notZero(uint(toyAddress)) 
        onlyOwner
    {
         
        toy = ToyTokenOwnership(toyAddress);
    }

     
     
     
     
     
     
     
    function setRequiredLockedForColorRegistration(uint newAmount) 
        external 
        onlyOwner
        notZero(newAmount)
    {
        requiredLockedForColorRegistration = newAmount;
    }
    
     
     
     
     
     
     
     
     
    function registerNewColor(string colorName) external returns (uint) {
         
        require (
            getTotalLockedTokens(msg.sender) >= requiredLockedForColorRegistration,
            "Insufficient locked tokens"
        );
         
        require (
            bytes(colorName).length > 0 && bytes(colorName).length < 32,
            "Invalid color name length"
        );
         
        uint index = coloredTokens.push(ColoredToken(msg.sender, colorName));
        return index;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
    function deposit (uint colorIndex, uint to, uint tokens)
        external 
        notZero(tokens)
    {
         
        require (colorIndex < coloredTokens.length, "Invalid color index");
         
        require (
            msg.sender == coloredTokens[colorIndex].creator,
            "Not authorized to deposit this color"
        );
         
        require (to < UID_MAX, "Invalid UID");
         
        require(toy.ownerOf(to) != address(0), "TOY Token does not exist");
         
        require (colorIndex < coloredTokens.length, "Invalid color index");
        
         
        lock(2, tokens);

         
        coloredTokens[colorIndex].balances[to] += tokens;
         
        emit DepositColor(to, colorIndex, tokens);
    }

     
     
     
     
     
     
     
     
     
     
     
    function spend (uint colorIndex, uint from, uint tokens) 
        external 
        notZero(tokens)
        returns(bool) 
    {
         
        require (colorIndex < coloredTokens.length, "Invalid color index");
         
        require (
            msg.sender == toy.ownerOf(from), 
            "Sender is not owner of TOY Token"
        );
         
        require (
            coloredTokens[colorIndex].balances[from] >= tokens,
            "Insufficient tokens to spend"
        );
         
        coloredTokens[colorIndex].balances[from] -= tokens;
         
        emit SpendColor(from, colorIndex, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
     
     
     
    function spendFrom(uint colorIndex, uint from, uint tokens)
        external 
        notZero(tokens)
        returns (bool) 
    {
         
        require (colorIndex < coloredTokens.length, "Invalid color index");
         
        require (
            msg.sender == toy.getApproved(from) ||
            toy.isApprovedForAll(toy.ownerOf(from), msg.sender), 
            "Sender is not authorized operator for TOY Token"
        );
         
        require (
            coloredTokens[colorIndex].balances[from] >= tokens,
            "Insufficient balance to spend"
        );
         
        coloredTokens[colorIndex].balances[from] -= tokens;
         
        emit SpendColor(from, colorIndex, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
    function getColoredTokenBalance(uint uid, uint colorIndex) 
        external 
        view 
        returns(uint) 
    {
        return coloredTokens[colorIndex].balances[uid];
    }

     
     
     
     
    function coloredTokenCount() external view returns (uint) {
        return coloredTokens.length;
    }

     
     
     
     
     
     
    function getColoredToken(uint colorIndex) 
        external 
        view 
        returns(address, string)
    {
        return (
            coloredTokens[colorIndex].creator, 
            coloredTokens[colorIndex].name
        );
    }
}