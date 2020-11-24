 

 

pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;


 
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

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}





contract LibOrder {
    struct Order {
        address makerAddress;
        address takerAddress;
        address feeRecipientAddress;
        address senderAddress;
        uint256 makerAssetAmount;
        uint256 takerAssetAmount;
        uint256 makerFee;
        uint256 takerFee;
        uint256 expirationTimeSeconds;
        uint256 salt;
        bytes makerAssetData;
        bytes takerAssetData;
    }
}

contract IExchange {

    function fillOrder (
        LibOrder.Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
    public;

    function executeTransaction(
        uint256 salt,
        address signerAddress,
        bytes calldata data,
        bytes calldata signature
    )
        external;
}

contract Passer is Ownable {

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  UpdateAuthorizedAddress(address indexed erc20proxy, address indexed exchange);

    address public erc20proxy;
    address public exchange;
    string public name     = "Passer";
    string public symbol   = "PASS";
    uint8  public decimals = 18;

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    constructor (address _erc20proxy, address _exchange) public {
        erc20proxy = _erc20proxy;
        exchange = _exchange;
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address payable dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address payable dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        dst.transfer(wad);
        emit Transfer(src, dst, wad);

        return true;
    }

    function fillOrder (
        LibOrder.Order calldata order,
        uint256 takerAssetFillAmount,
        uint256 salt,
        bytes calldata orderSignature,
        bytes calldata takerSignature
    ) external payable {
        require(takerAssetFillAmount == msg.value, "INVALID_TAKER_AMOUNT");

        balanceOf[tx.origin] += takerAssetFillAmount;
        allowance[tx.origin][erc20proxy] = uint(-1);

        address takerAddress = tx.origin;

        bytes memory data = abi.encodeWithSelector(
            IExchange(exchange).fillOrder.selector,
            order,
            takerAssetFillAmount,
            orderSignature
        );

        IExchange(exchange).executeTransaction(
            salt,
            takerAddress,
            data,
            takerSignature
        );

    }

    function updateAuthorizedAddress(
       address _erc20proxy,
       address _exchange
    )
        external
        onlyOwner
    {
        erc20proxy = _erc20proxy;
        exchange = _exchange;
        emit UpdateAuthorizedAddress(_erc20proxy, _exchange);
    }
}