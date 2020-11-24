 

 

 

pragma solidity 0.5.10;

 

library SafeMath {

   
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

   
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

   
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 

 

pragma solidity 0.5.10;

 

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

 

 

pragma solidity 0.5.10;



 

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

 

 
pragma solidity 0.5.10;




 

contract ERC20Claimable is ERC20 {

    using SafeMath for uint256;
    using SafeMath for uint32;

     
    struct Claim {
        address claimant;  
        uint256 collateral;  
        uint32 timestamp;   
        address currencyUsed;  
    }

     
    struct PreClaim {
        bytes32 msghash;  
        uint256 timestamp;   
    }

    uint256 public claimPeriod = 90 days;  
    uint256 public preClaimPeriod = 1 days;  
    uint256 public preClaimPeriodEnd = 2 days;  

    mapping(address => Claim) public claims;  
    mapping(address => PreClaim) public preClaims;  
    mapping(address => bool) public claimingDisabled;  

     
    address public customCollateralAddress;
    uint256 public customCollateralRate;

     
    function getCollateralRate(address collateralType) public view returns (uint256) {
        if (collateralType == address(this)) {
            return 1;
        } else if (collateralType == customCollateralAddress) {
            return customCollateralRate;
        } else {
            return 0;
        }
    }

     
    function _setCustomClaimCollateral(address collateral, uint256 rate) internal {
        customCollateralAddress = collateral;
        if (customCollateralAddress == address(0)) {
            customCollateralRate = 0;  
        } else {
            require(rate > 0, "Collateral rate can't be zero");
            customCollateralRate = rate;
        }
        emit CustomClaimCollateralChanged(collateral, rate);
    }

    function getClaimDeleter() public returns (address);

     
    function _setClaimPeriod(uint256 claimPeriodInDays) internal {
        require(claimPeriodInDays > 90, "Claim period must be at least 90 days");  
        uint256 claimPeriodInSeconds = claimPeriodInDays.mul(1 days);
        claimPeriod = claimPeriodInSeconds;
        emit ClaimPeriodChanged(claimPeriod);
    }

    function setClaimable(bool enabled) public {
        claimingDisabled[msg.sender] = !enabled;
    }

     
    function isClaimsEnabled(address target) public view returns (bool) {
        return !claimingDisabled[target];
    }

    event ClaimMade(address indexed lostAddress, address indexed claimant, uint256 balance);
    event ClaimPrepared(address indexed claimer);
    event ClaimCleared(address indexed lostAddress, uint256 collateral);
    event ClaimDeleted(address indexed lostAddress, address indexed claimant, uint256 collateral);
    event ClaimResolved(address indexed lostAddress, address indexed claimant, uint256 collateral);
    event ClaimPeriodChanged(uint256 newClaimPeriodInDays);
    event CustomClaimCollateralChanged(address newCustomCollateralAddress, uint256 newCustomCollareralRate);

   
    function prepareClaim(bytes32 hashedpackage) public {
        preClaims[msg.sender] = PreClaim({
            msghash: hashedpackage,
            timestamp: block.timestamp
        });
        emit ClaimPrepared(msg.sender);
    }

    function validateClaim(address lostAddress, bytes32 nonce) private view {
        PreClaim memory preClaim = preClaims[msg.sender];
        require(preClaim.msghash != 0, "Message hash can't be zero");
        require(preClaim.timestamp.add(preClaimPeriod) <= block.timestamp, "Preclaim period violated. Claimed too early");
        require(preClaim.timestamp.add(preClaimPeriodEnd) >= block.timestamp, "Preclaim period end. Claimed too late");
        require(preClaim.msghash == keccak256(abi.encodePacked(nonce, msg.sender, lostAddress)),"Package could not be validated");
    }

    function declareLost(address collateralType, address lostAddress, bytes32 nonce) public {
        require(lostAddress != address(0), "Can't claim zero address");
        require(isClaimsEnabled(lostAddress), "Claims disabled for this address");
        uint256 collateralRate = getCollateralRate(collateralType);
        require(collateralRate > 0, "Unsupported collateral type");
        address claimant = msg.sender;
        uint256 balance = balanceOf(lostAddress);
        uint256 collateral = balance.mul(collateralRate);
        IERC20 currency = IERC20(collateralType);
        require(balance > 0, "Claimed address holds no shares");
        require(currency.allowance(claimant, address(this)) >= collateral, "Currency allowance insufficient");
        require(currency.balanceOf(claimant) >= collateral, "Currency balance insufficient");
        require(claims[lostAddress].collateral == 0, "Address already claimed");
        validateClaim(lostAddress, nonce);
        require(currency.transferFrom(claimant, address(this), collateral), "Collateral transfer failed");

        claims[lostAddress] = Claim({
            claimant: claimant,
            collateral: collateral,
            timestamp: uint32(block.timestamp),  
            currencyUsed: collateralType
        });

        delete preClaims[claimant];
        emit ClaimMade(lostAddress, claimant, balance);
    }

    function getClaimant(address lostAddress) public view returns (address) {
        return claims[lostAddress].claimant;
    }

    function getCollateral(address lostAddress) public view returns (uint256) {
        return claims[lostAddress].collateral;
    }

    function getCollateralType(address lostAddress) public view returns (address) {
        return claims[lostAddress].currencyUsed;
    }

    function getTimeStamp(address lostAddress) public view returns (uint256) {
        return claims[lostAddress].timestamp;
    }

    function getPreClaimTimeStamp(address claimerAddress) public view returns (uint256) {
        return preClaims[claimerAddress].timestamp;
    }

    function getMsgHash(address claimerAddress) public view returns (bytes32) {
        return preClaims[claimerAddress].msghash;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(super.transfer(recipient, amount), "Transfer failed");
        clearClaim();
        return true;
    }

     
    function clearClaim() public {
        if (claims[msg.sender].collateral != 0) {
            uint256 collateral = claims[msg.sender].collateral;
            IERC20 currency = IERC20(claims[msg.sender].currencyUsed);
            delete claims[msg.sender];
            require(currency.transfer(msg.sender, collateral), "Collateral transfer failed");
            emit ClaimCleared(msg.sender, collateral);
        }
    }

    
    function resolveClaim(address lostAddress) public {
        Claim memory claim = claims[lostAddress];
        uint256 collateral = claim.collateral;
        IERC20 currency = IERC20(claim.currencyUsed);
        require(collateral != 0, "No claim found");
        require(claim.claimant == msg.sender, "Only claimant can resolve claim");
        require(claim.timestamp.add(uint32(claimPeriod)) <= block.timestamp, "Claim period not over yet");
        address claimant = claim.claimant;
        delete claims[lostAddress];
        require(currency.transfer(claimant, collateral), "Collateral transfer failed");
        _transfer(lostAddress, claimant, balanceOf(lostAddress));
        emit ClaimResolved(lostAddress, claimant, collateral);
    }

     
    function deleteClaim(address lostAddress) public {
        require(msg.sender == getClaimDeleter(), "You cannot delete claims");
        Claim memory claim = claims[lostAddress];
        IERC20 currency = IERC20(claim.currencyUsed);
        require(claim.collateral != 0, "No claim found");
        delete claims[lostAddress];
        require(currency.transfer(claim.claimant, claim.collateral), "Collateral transfer failed");
        emit ClaimDeleted(lostAddress, claim.claimant, claim.collateral);
    }

}

 

 

pragma solidity 0.5.10;

 

contract Ownable {

    address public owner;
    address constant master = 0x56F8C2c85d6E359aB2245394390550285089cE37;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


   
    constructor() public {
        owner = msg.sender;
    }

   
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner of this contract");
        _;
    }

   
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

   
    function transferOwnership(address _newOwner) public {
        require(msg.sender == master, "You are not the master of this contract");
        _transferOwnership(_newOwner);
    }

   
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Zero address can't own the contract");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 

 

pragma solidity 0.5.10;


contract Pausable is Ownable {

     
    bool public paused = false;

     
    function pause(bool _pause, string calldata _message, address _newAddress, uint256 _fromBlock) external onlyOwner() {
        paused = _pause;
        emit Pause(_pause, _message, _newAddress, _fromBlock);
    }

    event Pause(bool paused, string message, address newAddress, uint256 fromBlock);
}

 

 
pragma solidity 0.5.10;




 

contract AlethenaShares is ERC20Claimable, Pausable {

    using SafeMath for uint256;

    string public constant symbol = "GCO";
    string public constant name = "Green Consensus SA Shares";
    string public constant terms = "greenconsensus.ch/terms";

    uint8 public constant decimals = 0;  

    uint256 public totalShares = 10 * 10 ** 6;  
    uint256 public invalidTokens = 0;

    address[] public subregisters;

    event Announcement(string message);
    event TokensDeclaredInvalid(address holder, uint256 amount, string message);
    event ShareNumberingEvent(address holder, uint256 firstInclusive, uint256 lastInclusive);
    event SubRegisterAdded(address contractAddress);
    event SubRegisterRemoved(address contractAddress);

     
    function setTotalShares(uint256 _newTotalShares) public onlyOwner() {
        require(_newTotalShares >= totalValidSupply(), "There can't be fewer tokens than shares");
        totalShares = _newTotalShares;
    }

     
    function recognizeSubRegister(address contractAddress) public onlyOwner () {
        subregisters.push(contractAddress);
        emit SubRegisterAdded(contractAddress);
    }

    function removeSubRegister(address contractAddress) public onlyOwner() {
        for (uint256 i = 0; i<subregisters.length; i++) {
            if (subregisters[i] == contractAddress) {
                subregisters[i] = subregisters[subregisters.length - 1];
                subregisters.pop();
                emit SubRegisterRemoved(contractAddress);
            }
        }
    }

     
    function balanceOfDeep(address holder) public view returns (uint256) {
        uint256 balance = balanceOf(holder);
        for (uint256 i = 0; i<subregisters.length; i++) {
            IERC20 subERC = IERC20(subregisters[i]);
            balance = balance.add(subERC.balanceOf(holder));
        }
        return balance;
    }

     
    function announcement(string calldata message) external onlyOwner() {
        emit Announcement(message);
    }

    function setClaimPeriod(uint256 claimPeriodInDays) public onlyOwner() {
        super._setClaimPeriod(claimPeriodInDays);
    }

     
    function setCustomClaimCollateral(address collateral, uint256 rate) public onlyOwner() {
        super._setCustomClaimCollateral(collateral, rate);
    }

    function getClaimDeleter() public returns (address) {
        return owner;
    }

     
    function declareInvalid(address holder, uint256 amount, string calldata message) external onlyOwner() {
        uint256 holderBalance = balanceOf(holder);
        require(amount <= holderBalance, "Cannot invalidate more tokens than held by address");
        invalidTokens = invalidTokens.add(amount);
        emit TokensDeclaredInvalid(holder, amount, message);
    }

     
    function totalValidSupply() public view returns (uint256) {
        return totalSupply().sub(invalidTokens);
    }

     
    function mint(address shareholder, uint256 _amount) public onlyOwner() {
        require(totalValidSupply().add(_amount) <= totalShares, "There can't be fewer shares than valid tokens");
        _mint(shareholder, _amount);
    }

     
    function mintNumbered(address shareholder, uint256 firstShareNumber, uint256 lastShareNumber) public onlyOwner() {
        mint(shareholder, lastShareNumber.sub(firstShareNumber).add(1));
        emit ShareNumberingEvent(shareholder, firstShareNumber, lastShareNumber);
    }

     
    function burn(uint256 _amount) public {
        require(_amount <= balanceOf(msg.sender), "Not enough shares available");
        _transfer(msg.sender, address(this), _amount);
        _burn(address(this), _amount);
    }

    function _transfer(address from, address _to, uint256 _value) internal {
        require(!paused, "Contract is paused");
        super._transfer(from, _to, _value);
    }

}