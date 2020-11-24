 

pragma solidity ^0.5.8;

 
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


 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
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


 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor() public {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}


 
 
 
 
 
 
 
 
contract WrappedCK is ERC20, ReentrancyGuard {

     
    using SafeMath for uint256;

     
     
     

     
     
     
     
     
    event DepositKittyAndMintToken(
        uint256 kittyId,
        uint256 tokensMinted
    );

     
     
     
     
     
    event BurnTokenAndWithdrawKitty(
        uint256 kittyId,
        uint256 tokensBurned
    );

     
     
     

     
     
     
     
    uint256[] private depositedKittiesQueue;
    uint256 private queueStartIndex;
    uint256 private queueEndIndex;
    
     
     
     

     
    uint8 constant public decimals = 18;
    string constant public name = "Wrapped CryptoKitties";
    string constant public symbol = "WCK";

     
     
     
    address public kittyCoreAddress = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
    KittyCore kittyCore;

     
     
     

     
     
     
     
     
     
     
     
    function depositKittyAndMintToken(uint256 _kittyId) external nonReentrant {
        require(msg.sender == kittyCore.ownerOf(_kittyId), 'you do not own this cat');
        require(kittyCore.kittyIndexToApproved(_kittyId) == address(this), 'you must approve() this contract to give it permission to withdraw this cat before you can deposit a cat');
        kittyCore.transferFrom(msg.sender, address(this), _kittyId);
        _enqueueKitty(_kittyId);
        _mint(msg.sender, 10**18);
        emit DepositKittyAndMintToken(_kittyId, 10**18);
    }

     
     
    function multiDepositKittyAndMintToken(uint256[] calldata _kittyIds) external nonReentrant {
        for(uint i = 0; i < _kittyIds.length; i++){
            uint256 kittyToDeposit = _kittyIds[i];
            require(msg.sender == kittyCore.ownerOf(kittyToDeposit), 'you do not own this cat');
            require(kittyCore.kittyIndexToApproved(kittyToDeposit) == address(this), 'you must approve() this contract to give it permission to withdraw this cat before you can deposit a cat');
            kittyCore.transferFrom(msg.sender, address(this), kittyToDeposit);
            _enqueueKitty(kittyToDeposit);
            emit DepositKittyAndMintToken(kittyToDeposit, 10**18);
        }
        _mint(msg.sender, (_kittyIds.length).mul(10**18));
    }

     
     
     
     
    function burnTokenAndWithdrawKitty() external nonReentrant {
        require(balanceOf(msg.sender) >= 10**18, 'you do not own enough tokens to withdraw an ERC721 cat');
        uint256 kittyId = _dequeueKitty();
        _burn(msg.sender, 10**18);
        kittyCore.transfer(msg.sender, kittyId);
        emit BurnTokenAndWithdrawKitty(kittyId, 10**18);
    }

     
     
    function multiBurnTokenAndWithdrawKitty(uint256 _numTokens) external nonReentrant {
        require(balanceOf(msg.sender) >= _numTokens.mul(10**18), 'you do not own enough tokens to withdraw this many ERC721 cats');
        _burn(msg.sender, _numTokens.mul(10**18));
        for(uint i = 0; i < _numTokens; i++){
            uint256 kittyToWithdraw = _dequeueKitty();
            kittyCore.transfer(msg.sender, kittyToWithdraw);
            emit BurnTokenAndWithdrawKitty(kittyToWithdraw, 10**18);
        }
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function depositKittyAndWithdrawDifferentKitty(uint256 _kittyId) external nonReentrant {
        require(msg.sender == kittyCore.ownerOf(_kittyId), 'you do not own this cat');
        require(kittyCore.kittyIndexToApproved(_kittyId) == address(this), 'you must approve() this contract to give it permission to withdraw this cat before you can deposit a cat');
        kittyCore.transferFrom(msg.sender, address(this), _kittyId);
        _enqueueKitty(_kittyId);
        uint256 kittyToWithdraw = _dequeueKitty();
        kittyCore.transfer(msg.sender, kittyToWithdraw);
        emit DepositKittyAndMintToken(_kittyId, 10**18);
        emit BurnTokenAndWithdrawKitty(kittyToWithdraw, 10**18);
    }

     
     
    function multiDepositKittyAndWithdrawDifferentKitty(uint256[] calldata _kittyIds) external nonReentrant {
        for(uint i = 0; i < _kittyIds.length; i++){
            uint256 kittyToDeposit = _kittyIds[i];
            require(msg.sender == kittyCore.ownerOf(kittyToDeposit), 'you do not own this cat');
            require(kittyCore.kittyIndexToApproved(kittyToDeposit) == address(this), 'you must approve() this contract to give it permission to withdraw this cat before you can deposit a cat');
            kittyCore.transferFrom(msg.sender, address(this), kittyToDeposit);
            _enqueueKitty(kittyToDeposit);
            uint256 kittyToWithdraw = _dequeueKitty();
            kittyCore.transfer(msg.sender, kittyToWithdraw);
            emit DepositKittyAndMintToken(kittyToDeposit, 10**18);
            emit BurnTokenAndWithdrawKitty(kittyToWithdraw, 10**18);
        }
    }
    
     
     
    function _enqueueKitty(uint256 _kittyId) internal {
        depositedKittiesQueue.push(_kittyId);
        queueEndIndex = queueEndIndex.add(1);
    }

     
     
    function _dequeueKitty() internal returns(uint256){
        require(queueStartIndex < queueEndIndex, 'there are no cats in the queue');
        uint256 kittyId = depositedKittiesQueue[queueStartIndex];
        queueStartIndex = queueStartIndex.add(1);
        return kittyId;
    }

     
     
    function totalCatsLockedInContract() public view returns(uint256){
        return queueEndIndex.sub(queueStartIndex);
    }

     
     
    constructor() public {
        kittyCore = KittyCore(kittyCoreAddress);
    }

     
     
     
     
     
    function() external payable {}
}

 
contract KittyCore {
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    mapping (uint256 => address) public kittyIndexToApproved;
}