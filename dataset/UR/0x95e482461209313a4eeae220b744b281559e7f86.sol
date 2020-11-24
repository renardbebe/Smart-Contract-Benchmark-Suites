 

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.5;

 
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

 

pragma solidity ^0.5.0;




 
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

 

pragma solidity 0.5.13;







 
contract Lock is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    enum Status { _, OPEN, CLOSED }
    enum TokenStatus {_, ACTIVE, INACTIVE }

    struct Token {
        address tokenAddress;
        uint256 minAmount;
        bool emergencyUnlock;
        TokenStatus status;
    }

    Token[] private _tokens;

     
    mapping(address => uint256) private _tokenVsIndex;

     
     
     
    uint256 private _fee;

     
    address payable private _wallet;

    address constant private ETH_ADDRESS = address(
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    );

    struct LockedAsset {
        address token; 
        uint256 amount; 
        uint256 startDate; 
        uint256 endDate;
        address payable beneficiary; 
        Status status;
    }

    struct Airdrop {
        address destToken;
         
         
         
        uint256 numerator;
        uint256 denominator;
        uint256 date; 
         
         
    }

     
    mapping(address => Airdrop[]) private _baseTokenVsAirdrops;

     
    uint256 private _lockId;

     
    mapping(address => uint256[]) private _userVsLockIds;

    mapping(uint256 => LockedAsset) private _idVsLockedAsset;

    bool private _paused;

    event TokenAdded(address indexed token);
    event TokenInactivated(address indexed token);
    event TokenActivated(address indexed token);
    event FeeChanged(uint256 fee);
    event WalletChanged(address indexed wallet);
    event AssetLocked(
        address indexed token,
        address indexed sender,
        address indexed beneficiary,
        uint256 id,
        uint256 amount,
        uint256 startDate,
        uint256 endDate
    );
    event TokenUpdated(
        uint256 indexed id,
        address indexed token,
        uint256 minAmount,
        bool emergencyUnlock
    );
    event Paused();
    event Unpaused();

    event AssetClaimed(
        uint256 indexed id,
        address indexed beneficiary,
        address indexed token
    );

    event AirdropAdded(
        address indexed baseToken,
        address indexed destToken,
        uint256 airdropDate
    );

    event TokensAirdropped(
        address indexed destToken,
        uint256 amount
    );

    modifier tokenExist(address token) {
        require(_tokenVsIndex[token] > 0, "Lock: Token does not exist!!");
        _;
    }

    modifier tokenDoesNotExist(address token) {
        require(_tokenVsIndex[token] == 0, "Lock: Token already exist!!");
        _;
    }

    modifier canLockAsset(address token) {
        uint256 index = _tokenVsIndex[token];

        require(index > 0, "Lock: Token does not exist!!");

        require(
            _tokens[index.sub(1)].status == TokenStatus.ACTIVE,
            "Lock: Token not active!!"
        );

        require(
            !_tokens[index.sub(1)].emergencyUnlock,
            "Lock: Token is in emergency unlock state!!"
        );
        _;
    }

    modifier canClaim(uint256 id) {

        require(claimable(id), "Lock: Can't claim asset");

        require(
            _idVsLockedAsset[id].beneficiary == msg.sender,
            "Lock: Unauthorized access!!"
        );
        _;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "Lock: paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "Lock: not paused");
        _;
    }

     
    constructor(
        uint256 fee,
        address payable wallet,
        address[] memory tokens,
        uint256[] memory minAmount
    )
        public
    {
        require(
            tokens.length == minAmount.length,
            "Lock: Length mismatch between token list and their minimum lock amount!!"
        );
        require(
            wallet != address(0),
            "Lock: Please provide valid wallet address!!"
        );

        _wallet = wallet;
        _fee = fee;

        for(uint256 i = 0; i<tokens.length; i = i.add(1)) {
            require(
                _tokenVsIndex[tokens[i]] == 0,
                "Lock: Token already exists"
            );
            _tokens.push(Token({
                tokenAddress: tokens[i],
                minAmount: minAmount[i],
                emergencyUnlock: false,
                status: TokenStatus.ACTIVE
            }));
            _tokenVsIndex[tokens[i]] = _tokens.length;

            emit TokenAdded(tokens[i]);
        }

    }

     
    function paused() external view returns (bool) {
        return _paused;
    }

     
    function getFee() external view returns(uint256) {
        return _fee;
    }

     
    function getWallet() external view returns(address) {
        return _wallet;
    }

     
    function getTokenCount() external view returns(uint256) {
        return _tokens.length;
    }

     
    function getTokens(uint256 start, uint256 length) external view returns(
        address[] memory tokenAddresses,
        uint256[] memory minAmounts,
        bool[] memory emergencyUnlocks,
        TokenStatus[] memory statuses
    )
    {
        tokenAddresses = new address[](length);
        minAmounts = new uint256[](length);
        emergencyUnlocks = new bool[](length);
        statuses = new TokenStatus[](length);

        require(start.add(length) <= _tokens.length, "Lock: Invalid input");
        require(length > 0 && length <= 15, "Lock: Invalid length");

        for(uint256 i = start; i < start.add(length); i++) {
            tokenAddresses[i] = _tokens[i].tokenAddress;
            minAmounts[i] = _tokens[i].minAmount;
            emergencyUnlocks[i] = _tokens[i].emergencyUnlock;
            statuses[i] = _tokens[i].status;
        }

        return(
            tokenAddresses,
            minAmounts,
            emergencyUnlocks,
            statuses
        );
    }

     
    function getTokenInfo(address tokenAddress) external view returns(
        uint256 minAmount,
        bool emergencyUnlock,
        TokenStatus status
    )
    {
        uint256 index = _tokenVsIndex[tokenAddress];

        if(index > 0){
            index = index.sub(1);
            Token memory token = _tokens[index];
            return (
                token.minAmount,
                token.emergencyUnlock,
                token.status
            );
        }
    }

     
    function getLockedAsset(uint256 id) external view returns(
        address token,
        uint256 amount,
        uint256 startDate,
        uint256 endDate,
        address beneficiary,
        Status status
    )
    {
        LockedAsset memory asset = _idVsLockedAsset[id];
        token = asset.token;
        amount = asset.amount;
        startDate = asset.startDate;
        endDate = asset.endDate;
        beneficiary = asset.beneficiary;
        status = asset.status;

        return(
            token,
            amount,
            startDate,
            endDate,
            beneficiary,
            status
        );
    }

     
    function getAssetIds(
        address user
    )
        external
        view
        returns (uint256[] memory ids)
    {
        return _userVsLockIds[user];
    }

     
    function getAirdrops(address token) external view returns(
        address[] memory destTokens,
        uint256[] memory numerators,
        uint256[] memory denominators,
        uint256[] memory dates
    )
    {   
        uint256 length = _baseTokenVsAirdrops[token].length;

        destTokens = new address[](length);
        numerators = new uint256[](length);
        denominators = new uint256[](length);
        dates = new uint256[](length);

         
         
        for(uint256 i = 0; i < length; i++){

            Airdrop memory airdrop = _baseTokenVsAirdrops[token][i];
            destTokens[i] = airdrop.destToken;
            numerators[i] = airdrop.numerator;
            denominators[i] = airdrop.denominator;
            dates[i] = airdrop.date;
        }

        return (
            destTokens,
            numerators,
            denominators,
            dates
        );
    }

     
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused();
    }

     
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused();
    }

     
    function setAirdrop(
        address baseToken,
        address destToken,
        uint256 numerator,
        uint256 denominator,
        uint256 date
    )
        external
        onlyOwner
        tokenExist(baseToken)
    {
        require(destToken != address(0), "Lock: Invalid destination token!!");
        require(numerator > 0, "Lock: Invalid numerator!!");
        require(denominator > 0, "Lock: Invalid denominator!!");
        require(isActive(baseToken), "Lock: Base token is not active!!");

        _baseTokenVsAirdrops[baseToken].push(Airdrop({
            destToken: destToken,
            numerator: numerator,
            denominator: denominator,
            date: date
        }));

        emit AirdropAdded(
            baseToken,
            destToken,
            date
        );
    }

     
    function updateAirdrop(
        address baseToken,
        uint256 numerator,
        uint256 denominator,
        uint256 date,
        uint256 index
    )
        external
        onlyOwner
    {
        require(
            _baseTokenVsAirdrops[baseToken].length > index,
            "Lock: Invalid index value!!"
        );
        require(numerator > 0, "Lock: Invalid numerator!!");
        require(denominator > 0, "Lock: Invalid denominator!!");

        Airdrop storage airdrop = _baseTokenVsAirdrops[baseToken][index];
        airdrop.numerator = numerator;
        airdrop.denominator = denominator;
        airdrop.date = date;
    }


     
    function setFee(uint256 fee) external onlyOwner {
        _fee = fee;
        emit FeeChanged(fee);
    }

     
    function setWallet(address payable wallet) external onlyOwner {
        require(
            wallet != address(0),
            "Lock: Please provider valid wallet address!!"
        );
        _wallet = wallet;

        emit WalletChanged(wallet);
    }

     
    function updateToken(
        address tokenAddress,
        uint256 minAmount,
        bool emergencyUnlock
    )
        external
        onlyOwner
        tokenExist(tokenAddress)
    {
        uint256 index = _tokenVsIndex[tokenAddress].sub(1);
        Token storage token = _tokens[index];
        token.minAmount = minAmount;
        token.emergencyUnlock = emergencyUnlock;
        
        emit TokenUpdated(
            index,
            tokenAddress,
            minAmount,
            emergencyUnlock
        );
    }

     
    function addToken(
        address token,
        uint256 minAmount
    )
        external
        onlyOwner
        tokenDoesNotExist(token)
    {
        _tokens.push(Token({
            tokenAddress: token,
            minAmount: minAmount,
            emergencyUnlock: false,
            status: TokenStatus.ACTIVE
        }));
        _tokenVsIndex[token] = _tokens.length;

        emit TokenAdded(token);
    }


     
    function inactivateToken(
        address token
    )
        external
        onlyOwner
        tokenExist(token)
    {
        uint256 index = _tokenVsIndex[token].sub(1);

        require(
            _tokens[index].status == TokenStatus.ACTIVE,
            "Lock: Token already inactive!!"
        );

        _tokens[index].status = TokenStatus.INACTIVE;

        emit TokenInactivated(token);
    }

     
    function activateToken(
        address token
    )
        external
        onlyOwner
        tokenExist(token)
    {
        uint256 index = _tokenVsIndex[token].sub(1);

        require(
            _tokens[index].status == TokenStatus.INACTIVE,
            "Lock: Token already active!!"
        );

        _tokens[index].status = TokenStatus.ACTIVE;

        emit TokenActivated(token);
    }

     
    function lock(
        address tokenAddress,
        uint256 amount,
        uint256 duration,
        address payable beneficiary
    )
        external
        payable
        whenNotPaused
        canLockAsset(tokenAddress)
    {
        require(
            beneficiary != address(0),
            "Lock: Provide valid beneficiary address!!"
        );

        Token memory token = _tokens[_tokenVsIndex[tokenAddress].sub(1)];

        require(
            amount >= token.minAmount,
            "Lock: Please provide minimum amount of tokens!!"
        );

        uint256 endDate = block.timestamp.add(duration);
        uint256 fee = amount.mul(_fee).div(10000);
        uint256 newAmount = amount.sub(fee);

        if(ETH_ADDRESS == tokenAddress) {
            _lockETH(
                newAmount,
                fee,
                endDate,
                beneficiary
            );
        }

        else {
            _lockERC20(
                tokenAddress,
                newAmount,
                fee,
                endDate,
                beneficiary
            );
        }

        emit AssetLocked(
            tokenAddress,
            msg.sender,
            beneficiary,
            _lockId,
            newAmount,
            block.timestamp,
            endDate
        );
    }

     
    function claim(uint256 id) external canClaim(id) {
        LockedAsset memory lockedAsset = _idVsLockedAsset[id];
        if(ETH_ADDRESS == lockedAsset.token) {
            _claimETH(
                id
            );
        }

        else {
            _claimERC20(
                id
            );
        }

        emit AssetClaimed(
            id,
            lockedAsset.beneficiary,
            lockedAsset.token
        );
    }

     
    function claimable(uint256 id) public view returns(bool){

        if(
            _idVsLockedAsset[id].status == Status.OPEN &&
            (
                _idVsLockedAsset[id].endDate <= block.timestamp ||
                _tokens[_tokenVsIndex[_idVsLockedAsset[id].token].sub(1)].emergencyUnlock
            )
        )
        {
            return true;
        }
        return false;
    }

     
    function isActive(address token) public view returns(bool) {
        uint256 index = _tokenVsIndex[token];

        if(index > 0){
            return (_tokens[index.sub(1)].status == TokenStatus.ACTIVE);
        }
        return false;
    }

     
    function _lockETH(
        uint256 amount,
        uint256 fee,
        uint256 endDate,
        address payable beneficiary
    )
        private
    {

         
        (bool success,) = _wallet.call.value(fee)("");
        require(success, "Lock: Transfer of fee failed");

        _lockId = _lockId.add(1);

        _idVsLockedAsset[_lockId] = LockedAsset({
            token: ETH_ADDRESS,
            amount: amount,
            startDate: block.timestamp,
            endDate: endDate,
            beneficiary: beneficiary,
            status: Status.OPEN
        });
        _userVsLockIds[beneficiary].push(_lockId);
    }

     
    function _lockERC20(
        address token,
        uint256 amount,
        uint256 fee,
        uint256 endDate,
        address payable beneficiary
    )
        private
    {

         
        IERC20(token).safeTransferFrom(msg.sender, _wallet, fee);

         
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        _lockId = _lockId.add(1);

        _idVsLockedAsset[_lockId] = LockedAsset({
            token: token,
            amount: amount,
            startDate: block.timestamp,
            endDate: endDate,
            beneficiary: beneficiary,
            status: Status.OPEN
        });
        _userVsLockIds[beneficiary].push(_lockId);
    }

     
    function _claimETH(uint256 id) private {
        LockedAsset storage asset = _idVsLockedAsset[id];
        asset.status = Status.CLOSED;
        (bool success,) = msg.sender.call.value(asset.amount)("");
        require(success, "Lock: Failed to transfer eth!!");

        _claimAirdroppedTokens(
            asset.token,
            asset.startDate,
            asset.amount
        );
    }

     
    function _claimERC20(uint256 id) private {
        LockedAsset storage asset = _idVsLockedAsset[id];
        asset.status = Status.CLOSED;
        IERC20(asset.token).safeTransfer(msg.sender, asset.amount);
        _claimAirdroppedTokens(
            asset.token,
            asset.startDate,
            asset.amount
        );
    }

     
    function _claimAirdroppedTokens(
        address baseToken,
        uint256 lockDate,
        uint256 amount
    )
        private
    {
         
         
        for(uint256 i = 0; i < _baseTokenVsAirdrops[baseToken].length; i++) {

            Airdrop memory airdrop = _baseTokenVsAirdrops[baseToken][i];

            if(airdrop.date < lockDate || airdrop.date > block.timestamp) {
                return;
            }
            else {
                uint256 airdropAmount = amount.mul(airdrop.numerator).div(airdrop.denominator);
                IERC20(airdrop.destToken).safeTransfer(msg.sender, airdropAmount);
                emit TokensAirdropped(airdrop.destToken, airdropAmount);
            }
        }

    }
}