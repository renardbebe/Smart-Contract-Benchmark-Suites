 

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


 
 
 

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

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


 
 
 

pragma solidity ^0.5.0;



contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}


 
 
 

pragma solidity ^0.5.0;



 
contract Pausable is Context, PauserRole {
     
    event Paused(address account);

     
    event Unpaused(address account);

    bool private _paused;

     
    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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


 
 
 

pragma solidity ^0.5.0;

contract Payment is Pausable, Ownable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

     
    bytes32 constant private INVOICE_SCHEMA_HASH = 0x9b5fecc7f7fca49a5a75b168891cd29e66acc9e7e59c8e35e08e0c078a5aebf2;

     
    address constant private  ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

     
    address private _signer;

     
    address payable private _sellerAddress;
    address private _tokenAddress;

     
    event SignerChanged(address indexed signer);
    event SellerAddressChanged(address indexed sellerAddress);
    event TokenAddressChanged(address indexed tokenAddress);
    event TokenPurchased(address indexed buyerAddress, address tokenAddress, uint256 tokenAmount, bytes32 hash);

     
    struct Invoice{
        address buyerAddress;
        address sellerAddress;
        address tokenAddress;
        uint256 tokenUnitPrice;
        uint256 tokenAmount;
        address paymentTokenAddress;
        uint256 paymentTokenRate;
        uint256 paymentTokenAmount;
        uint256 expirationTimeSeconds;
        uint256 salt;
    }

     
    constructor (address payable sellerAddress, address tokenAddress)
        public
    {
        _signer = msg.sender;
        emit SignerChanged(_signer);

        _sellerAddress = sellerAddress;
        emit SellerAddressChanged(_sellerAddress);

        _tokenAddress = tokenAddress;
        emit TokenAddressChanged(_tokenAddress);
    }

     
    function () external {
    }

     
    function checkoutWithETH(
            address buyerAddress,
            address payable sellerAddress,
            address tokenAddress,
            uint256 tokenUnitPrice,
            uint256 tokenAmount,
            address paymentTokenAddress,
            uint256 paymentTokenRate,
            uint256 paymentTokenAmount,
            uint256 expirationTimeSeconds,
            uint256 salt,
            bytes32 hash,
            bytes memory signature
        )
        public
        payable
        whenNotPaused
    {

        Invoice memory invoice = Invoice({
                                buyerAddress: buyerAddress,
                                sellerAddress: sellerAddress,
                                tokenAddress: tokenAddress,
                                tokenUnitPrice: tokenUnitPrice,
                                tokenAmount: tokenAmount,
                                paymentTokenAddress: paymentTokenAddress,
                                paymentTokenRate: paymentTokenRate,
                                paymentTokenAmount: paymentTokenAmount,
                                expirationTimeSeconds: expirationTimeSeconds,
                                salt: salt
                            });

         
        bytes32 invoiceHash = _getStructHash(invoice);
        require(invoiceHash == hash, "invoice hash does not match");

         
        require(_isValidSignature(hash, signature) == true, "invoice signature is invalid");
        
         
        require(_isValidInvoice(invoice) == true, "invoice is invalid");

         
        IERC20 token = IERC20(_tokenAddress);
        require(token.allowance(_sellerAddress, address(this)) >= invoice.tokenAmount, "insufficient token allowance");

         
        require(ETH_TOKEN_ADDRESS == invoice.paymentTokenAddress, "_ETH_ payment token address is invalid");
        require(msg.value == invoice.paymentTokenAmount, "insufficient ETH payment");

         
        token.safeTransferFrom(_sellerAddress, invoice.buyerAddress, invoice.tokenAmount);
        _sellerAddress.transfer(invoice.paymentTokenAmount);

        emit TokenPurchased(invoice.buyerAddress, invoice.tokenAddress, invoice.tokenAmount, invoiceHash);
    }

     
    function checkoutWithToken(
            address buyerAddress,
            address sellerAddress,
            address tokenAddress,
            uint256 tokenUnitPrice,
            uint256 tokenAmount,
            address paymentTokenAddress,
            uint256 paymentTokenRate,
            uint256 paymentTokenAmount,
            uint256 expirationTimeSeconds,
            uint256 salt,
            bytes32 hash,
            bytes memory signature
        ) 
        public
        whenNotPaused
    {

        Invoice memory invoice = Invoice({
                                buyerAddress: buyerAddress,
                                sellerAddress: sellerAddress,
                                tokenAddress: tokenAddress,
                                tokenUnitPrice: tokenUnitPrice,
                                tokenAmount: tokenAmount,
                                paymentTokenAddress: paymentTokenAddress,
                                paymentTokenRate: paymentTokenRate,
                                paymentTokenAmount: paymentTokenAmount,
                                expirationTimeSeconds: expirationTimeSeconds,
                                salt: salt
                            });

         
        bytes32 invoiceHash = _getStructHash(invoice);
        require(invoiceHash == hash, "invoice hash does not match");

         
        require(_isValidSignature(hash, signature) == true, "invoice signature is invalid");
        
         
        require(_isValidInvoice(invoice) == true, "invoice is invalid");

         
        IERC20 token = IERC20(_tokenAddress);
        require(token.allowance(_sellerAddress, address(this)) >= invoice.tokenAmount, "insufficient token allowance");

         
        IERC20 paymentToken = IERC20(invoice.paymentTokenAddress);
        require(paymentToken.allowance(invoice.buyerAddress, address(this)) >= invoice.paymentTokenAmount, "insufficient payment token allowance. please approval for the contract before checkout");

         
        token.safeTransferFrom(_sellerAddress, invoice.buyerAddress, invoice.tokenAmount);
        paymentToken.safeTransferFrom(invoice.buyerAddress, _sellerAddress, invoice.paymentTokenAmount);

        emit TokenPurchased(invoice.buyerAddress, invoice.tokenAddress, invoice.tokenAmount, invoiceHash);
    }

     
     
     
    function _isValidInvoice(Invoice memory invoice)
        internal
        view
        returns (bool){

         
        require(invoice.sellerAddress != address(0), "seller address is the zero address");
        require(invoice.sellerAddress == _sellerAddress, "seller address is not the seller address of the contract");

         
        require(invoice.tokenAddress != address(0), "token address is the zero address");
        require(invoice.tokenAddress == _tokenAddress, "token address is not the token address of the contract");

         
        require(invoice.buyerAddress != address(0), "buyer address is the zero address");
        require(invoice.buyerAddress == msg.sender, "buyer address is not msg.sender");

         
        require(invoice.paymentTokenAddress != address(0), "payment token address is the zero address");
        
         
        require(now < invoice.expirationTimeSeconds, "the invoice is expired. please refresh invoice and try again");

        return true;

    }

     
     
    function getSigner() 
        public
        view
        returns (address)
    {
        return _signer;
    }

     
     
    function setSigner(address newSigner) 
        public
        onlyOwner
    {
        require(newSigner != address(0), "signer address is the zero address");

        _signer = newSigner;
        emit SignerChanged(_signer);
    }

     
     
    function getSellerAddress() 
        public
        view
        returns (address)
    {
        return _sellerAddress;
    }

     
     
    function setSellerAddress(address payable newSellerAddress) 
        public
        onlyOwner
    {
        require(newSellerAddress != address(0), "seller address is the zero address");

        _sellerAddress = newSellerAddress;

        emit SellerAddressChanged(_sellerAddress);
    }

     
     
    function getTokenAddress() 
        public
        view
        returns (address)
    {
        return _tokenAddress;
    }

     
     
    function setTokenAddress(address newTokenAddress) 
        public
        onlyOwner
    {
        require(newTokenAddress != address(0), "token address is the zero address");

        _tokenAddress = newTokenAddress;

        emit TokenAddressChanged(_tokenAddress);
    }

     
     
     
    function _getStructHash(Invoice memory invoice)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(
                INVOICE_SCHEMA_HASH,
                invoice.buyerAddress,
                invoice.sellerAddress,
                invoice.tokenAddress,
                invoice.tokenUnitPrice,
                invoice.tokenAmount,
                invoice.paymentTokenAddress,
                invoice.paymentTokenRate,
                invoice.paymentTokenAmount,
                invoice.expirationTimeSeconds,
                invoice.salt            
            ));
    }
    
     
     
     
     
    function _isValidSignature(
        bytes32 hash,
        bytes memory signature
    )
        internal
        view
        returns (bool)
    {
        address signerAddress = ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), signature);

        if(signerAddress != address(0) && signerAddress == _signer){
            return true;
        }else{
            return false;
        }
    }
}