 

pragma solidity 0.5.7;
 
 
 
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
    address private _nominatedOwner;

    event NewOwnerNominated(address indexed previousOwner, address indexed nominee);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    function nominatedOwner() external view returns (address) {
        return _nominatedOwner;
    }

     
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        require(_msgSender() == _owner, "caller is not owner");
    }

     
    function nominateNewOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "new owner is 0 address");
        emit NewOwnerNominated(_owner, newOwner);
        _nominatedOwner = newOwner;
    }

     
    function acceptOwnership() external {
        require(_nominatedOwner == _msgSender(), "unauthorized");
        emit OwnershipTransferred(_owner, _nominatedOwner);
        _owner = _nominatedOwner;
    }

     
    function renounceOwnership(string calldata declaration) external onlyOwner {
        string memory requiredDeclaration = "I hereby renounce ownership of this contract forever.";
        require(
            keccak256(abi.encodePacked(declaration)) ==
            keccak256(abi.encodePacked(requiredDeclaration)),
            "declaration incorrect");

        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract ReserveEternalStorage is Ownable {

    using SafeMath for uint256;


     

    address public reserveAddress;

    event ReserveAddressTransferred(
        address indexed oldReserveAddress,
        address indexed newReserveAddress
    );

     
    constructor() public {
        reserveAddress = _msgSender();
        emit ReserveAddressTransferred(address(0), reserveAddress);
    }

     
    modifier onlyReserveAddress() {
        require(_msgSender() == reserveAddress, "onlyReserveAddress");
        _;
    }

     
    function updateReserveAddress(address newReserveAddress) external {
        require(newReserveAddress != address(0), "zero address");
        require(_msgSender() == reserveAddress || _msgSender() == owner(), "not authorized");
        emit ReserveAddressTransferred(reserveAddress, newReserveAddress);
        reserveAddress = newReserveAddress;
    }



     

    mapping(address => uint256) public balance;

     
     
     
     
     
    function addBalance(address key, uint256 value) external onlyReserveAddress {
        balance[key] = balance[key].add(value);
    }

     
    function subBalance(address key, uint256 value) external onlyReserveAddress {
        balance[key] = balance[key].sub(value);
    }

     
    function setBalance(address key, uint256 value) external onlyReserveAddress {
        balance[key] = value;
    }



     

    mapping(address => mapping(address => uint256)) public allowed;

     
    function setAllowed(address from, address to, uint256 value) external onlyReserveAddress {
        allowed[from][to] = value;
    }
}

interface ITXFee {
     function calculateFee(address from, address to, uint256 amount) external returns (uint256);
}

contract Reserve is IERC20, Ownable {
    using SafeMath for uint256;


     


     
    ReserveEternalStorage internal trustedData;

     
    ITXFee public trustedTxFee;

     
    uint256 public totalSupply;
    uint256 public maxSupply;

     
    bool public paused;

     
    address public minter;
    address public pauser;
    address public feeRecipient;


     


     
    event MinterChanged(address indexed newMinter);
    event PauserChanged(address indexed newPauser);
    event FeeRecipientChanged(address indexed newFeeRecipient);
    event MaxSupplyChanged(uint256 indexed newMaxSupply);
    event EternalStorageTransferred(address indexed newReserveAddress);
    event TxFeeHelperChanged(address indexed newTxFeeHelper);

     
    event Paused(address indexed account);
    event Unpaused(address indexed account);

     
    string public constant name = "Reserve";
    string public constant symbol = "RSV";
    uint8 public constant decimals = 18;

     
    constructor() public {
        pauser = msg.sender;
        feeRecipient = msg.sender;
         

        maxSupply = 2 ** 256 - 1;
        paused = true;

        trustedTxFee = ITXFee(address(0));
        trustedData = new ReserveEternalStorage();
        trustedData.nominateNewOwner(msg.sender);
    }

     
    function getEternalStorageAddress() external view returns(address) {
        return address(trustedData);
    }


     


     
    modifier only(address role) {
        require(msg.sender == role, "unauthorized: not role holder");
        _;
    }

     
    modifier onlyOwnerOr(address role) {
        require(msg.sender == owner() || msg.sender == role, "unauthorized: not owner or role");
        _;
    }

     
    function changeMinter(address newMinter) external onlyOwnerOr(minter) {
        minter = newMinter;
        emit MinterChanged(newMinter);
    }

     
    function changePauser(address newPauser) external onlyOwnerOr(pauser) {
        pauser = newPauser;
        emit PauserChanged(newPauser);
    }

    function changeFeeRecipient(address newFeeRecipient) external onlyOwnerOr(feeRecipient) {
        feeRecipient = newFeeRecipient;
        emit FeeRecipientChanged(newFeeRecipient);
    }

     
     
     
    function transferEternalStorage(address newReserveAddress) external onlyOwner isPaused {
        require(newReserveAddress != address(0), "zero address");
        emit EternalStorageTransferred(newReserveAddress);
        trustedData.updateReserveAddress(newReserveAddress);
    }

     
    function changeTxFeeHelper(address newTrustedTxFee) external onlyOwner {
        trustedTxFee = ITXFee(newTrustedTxFee);
        emit TxFeeHelperChanged(newTrustedTxFee);
    }

     
    function changeMaxSupply(uint256 newMaxSupply) external onlyOwner {
        maxSupply = newMaxSupply;
        emit MaxSupplyChanged(newMaxSupply);
    }

     
    function pause() external only(pauser) {
        paused = true;
        emit Paused(pauser);
    }

     
    function unpause() external only(pauser) {
        paused = false;
        emit Unpaused(pauser);
    }

     
    modifier isPaused() {
        require(paused, "contract is not paused");
        _;
    }

     
    modifier notPaused() {
        require(!paused, "contract is paused");
        _;
    }


     


     
    function balanceOf(address holder) external view returns (uint256) {
        return trustedData.balance(holder);
    }

     
    function allowance(address holder, address spender) external view returns (uint256) {
        return trustedData.allowed(holder, spender);
    }

     
    function transfer(address to, uint256 value)
        external
        notPaused
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value)
        external
        notPaused
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

     
     
     
     
    function transferFrom(address from, address to, uint256 value)
        external
        notPaused
        returns (bool)
    {
        _transfer(from, to, value);
        _approve(from, msg.sender, trustedData.allowed(from, msg.sender).sub(value));
        return true;
    }

     
     
     
     
    function increaseAllowance(address spender, uint256 addedValue)
        external
        notPaused
        returns (bool)
    {
        _approve(msg.sender, spender, trustedData.allowed(msg.sender, spender).add(addedValue));
        return true;
    }

     
     
     
     
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        notPaused
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            trustedData.allowed(msg.sender, spender).sub(subtractedValue)
        );
        return true;
    }

     
    function mint(address account, uint256 value)
        external
        notPaused
        only(minter)
    {
        require(account != address(0), "can't mint to address zero");

        totalSupply = totalSupply.add(value);
        require(totalSupply < maxSupply, "max supply exceeded");
        trustedData.addBalance(account, value);
        emit Transfer(address(0), account, value);
    }

     
    function burnFrom(address account, uint256 value)
        external
        notPaused
        only(minter)
    {
        _burn(account, value);
        _approve(account, msg.sender, trustedData.allowed(account, msg.sender).sub(value));
    }

     
     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "can't transfer to address zero");
        trustedData.subBalance(from, value);
        uint256 fee = 0;

        if (address(trustedTxFee) != address(0)) {
            fee = trustedTxFee.calculateFee(from, to, value);
            require(fee <= value, "transaction fee out of bounds");

            trustedData.addBalance(feeRecipient, fee);
            emit Transfer(from, feeRecipient, fee);
        }

        trustedData.addBalance(to, value.sub(fee));
        emit Transfer(from, to, value.sub(fee));
    }

     
     
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "can't burn from address zero");

        totalSupply = totalSupply.sub(value);
        trustedData.subBalance(account, value);
        emit Transfer(account, address(0), value);
    }

     
     
    function _approve(address holder, address spender, uint256 value) internal {
        require(spender != address(0), "spender cannot be address zero");
        require(holder != address(0), "holder cannot be address zero");

        trustedData.setAllowed(holder, spender, value);
        emit Approval(holder, spender, value);
    }
}