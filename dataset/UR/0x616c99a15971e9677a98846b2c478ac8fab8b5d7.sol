 

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


contract ILoanPoolLoaner {

    modifier withLoan(
        ILoanPool pool,
        IERC20 token,
        uint256 amount
    ) {
        if (msg.sender != address(this)) {
            pool.lend(
                token,
                amount,
                this,
                msg.data
            );
            return;
        }

        _;
    }

    function _getExpectedReturn() internal pure returns(uint256 amount) {
        assembly {
            amount := calldataload(sub(calldatasize, 32))
        }
    }

    function inLoan(
        uint256 expectedReturn,
        bytes calldata data
    )
        external
    {
        (bool success,) = address(this).call(abi.encodePacked(data, expectedReturn));
        require(success);
    }
}

interface ILoanPool {

    function lend(
        IERC20 token,
        uint256 amount,
        ILoanPoolLoaner loaner,
        bytes calldata data
    ) external;
}


interface ICompoundController {
    function enterMarkets(address[] calldata cTokens) external returns(uint[] memory);
}

interface ICERC20 {
    function comptroller() external view returns(ICompoundController);
    function borrowBalanceStored(address account) external view returns(uint256);
    function borrowBalanceCurrent(address account) external returns(uint256);

    function mint() external payable;
    function mint(uint256 amount) external returns(uint256);
    function redeem(uint256 amount) external returns(uint256);
    function borrow(uint256 amount) external returns(uint256);
    function repayBorrowBehalf(address borrower) external payable returns (uint256);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint256);
}


contract LoanHolder {

    address public owner = msg.sender;

    function () external payable {
    }

    function perform(address target, uint256 value, bytes calldata data) external payable returns(bytes memory) {
        require(msg.sender == owner, "Not authorized caller");
        (bool success, bytes memory ret) = target.call.value(value)(data);
        require(success);
        return ret;
    }
}


interface IGasToken {
    function freeUpTo(uint256 value) external returns (uint256 freed);
}

contract GasDiscounter {
    IGasToken constant private _gasToken = IGasToken(0x0000000000b3F879cb30FE243b4Dfee438691c04);

    modifier gasDiscount() {
        uint256 initialGasLeft = gasleft();
        _;
        _getGasDiscount(initialGasLeft - gasleft());
    }

    function _getGasDiscount(uint256 gasSpent) private {
        uint256 tokens = (gasSpent + 14154) / 41130;
        _gasToken.freeUpTo(tokens);
    }
}


 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}


 
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


 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


 
library Counters {
    using SafeMath for uint256;

    struct Counter {
         
         
         
        uint256 _value;  
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}




 
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
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


 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}





library UniversalERC20 {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function universalTransfer(IERC20 token, address to, uint256 amount) internal {
        universalTransfer(token, to, amount, false);
    }

    function universalTransfer(IERC20 token, address to, uint256 amount, bool allowFail) internal returns(bool) {

        if (token == IERC20(0) || address(token) == ETH_ADDRESS) {
            if (allowFail) {
                return address(uint160(to)).send(amount);
            } else {
                address(uint160(to)).transfer(amount);
                return true;
            }
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalApprove(IERC20 token, address to, uint256 amount) internal {
        if (address(token) == address(0) || address(token) == ETH_ADDRESS) {
            return;
        }
        token.safeApprove(to, amount);
    }

    function universalTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        if (address(token) == address(0) || address(token) == ETH_ADDRESS) {
            if (to == address(this)) {
                require(from == msg.sender && msg.value >= amount, "msg.value is zero");
                if (msg.value > amount) {
                    msg.sender.transfer(msg.value.sub(amount));
                }
            } else {
                address(uint160(to)).transfer(amount);
            }
            return;
        }

        token.safeTransferFrom(from, to, amount);
    }

    function universalBalanceOf(IERC20 token, address who) internal returns (uint256) {

        if (address(token) == address(0) || address(token) == ETH_ADDRESS) {
            return who.balance;
        }

        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(token.balanceOf.selector, who)
        );

        return success ? _bytesToUint(data) : 0;
    }

    function universalDecimals(IERC20 token) internal returns (uint256) {

        if (address(token) == address(0) || address(token) == ETH_ADDRESS) {
            return 18;
        }

        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSignature("decimals()")
        );
        if (!success) {
            (success, data) = address(token).call(
                abi.encodeWithSignature("DECIMALS()")
            );
        }

        return success ? _bytesToUint(data) : 18;
    }

    function universalName(IERC20 token) internal returns(string memory) {

        if (address(token) == address(0) || address(token) == ETH_ADDRESS) {
            return "Ether";
        }

         
        (bool success, bytes memory symbol) = address(token).call(abi.encodeWithSignature("symbol()"));
        if (!success) {
             
            (success, symbol) = address(token).call(abi.encodeWithSignature("SYMBOL()"));
        }

        return success ? _handleReturnBytes(symbol) : "";
    }

    function universalSymbol(IERC20 token) internal returns(string memory) {

        if (address(token) == address(0) || address(token) == ETH_ADDRESS) {
            return "ETH";
        }

         
        (bool success, bytes memory name) = address(token).call(abi.encodeWithSignature("name()"));
        if (!success) {
             
            (success, name) = address(token).call(abi.encodeWithSignature("NAME()"));
        }

        return success ? _handleReturnBytes(name) : "";
    }

    function _bytesToUint(bytes memory data) private pure returns(uint256 result) {
         
        assembly {
            result := mload(add(data, 32))
        }
    }

    function _handleReturnBytes(bytes memory str) private pure returns(string memory result) {

        result = string(str);

        if (str.length > 32) {
             
            assembly {
                result := add(str, 32)
            }
        }
    }
}


 
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

     
    function balanceOf(address owner) public view returns (uint256 balance);

     
    function ownerOf(uint256 tokenId) public view returns (address owner);

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
     
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}


 
contract ERC165 is IERC165 {
     
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

     
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
         
         
        _registerInterface(_INTERFACE_ID_ERC165);
    }

     
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

     
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}


 
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}


 
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}







 
contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

     
     
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

     
    mapping (uint256 => address) private _tokenOwner;

     
    mapping (uint256 => address) private _tokenApprovals;

     
    mapping (address => Counters.Counter) private _ownedTokensCount;

     
    mapping (address => mapping (address => bool)) private _operatorApprovals;

     
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
         
        _registerInterface(_INTERFACE_ID_ERC721);
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

     
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

     
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

     
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

     
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

     
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

     
    function transferFrom(address from, address to, uint256 tokenId) public {
         
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

     
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

     
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

     
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

     
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

     
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

     
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

     
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}




 
contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
     
    mapping(address => uint256[]) private _ownedTokens;

     
    mapping(uint256 => uint256) private _ownedTokensIndex;

     
    uint256[] private _allTokens;

     
    mapping(uint256 => uint256) private _allTokensIndex;

     
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

     
    constructor () public {
         
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

     
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

     
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

     
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

     
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

     
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
         
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

     
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

     
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

     
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

     
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
         
         

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

         
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;  
            _ownedTokensIndex[lastTokenId] = tokenIndex;  
        }

         
        _ownedTokens[from].length--;

         
         
    }

     
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
         
         

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

         
         
         
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;  
        _allTokensIndex[lastTokenId] = tokenIndex;  

         
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}




contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
     
    string private _name;

     
    string private _symbol;

     
    mapping(uint256 => string) private _tokenURIs;

     
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

     
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

         
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

     
    function name() external view returns (string memory) {
        return _name;
    }

     
    function symbol() external view returns (string memory) {
        return _symbol;
    }

     
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

     
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

         
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}




interface ITokenizer {

    function enterMarkets(
        uint256 tokenId,
        address controller,
        address[] calldata cTokens
    )
        external
        returns(bytes memory ret);

    function migrate(
        ILoanPool pool,
        IERC20 collateralToken,
        uint256 collateralAmount,
        IERC20 borrowedToken,
        IERC20 borrowedUnderlyingToken,
        uint256 borrowedAmount,
        address msgSender
    )
        external;

    function mint(
        uint256 tokenId,
        IERC20 cToken,
        IERC20 token,
        uint256 amount
    )
        external
        payable;

    function redeem(
        uint256 tokenId,
        IERC20 cToken,
        IERC20 token,
        uint256 amount
    )
        external;

    function borrow(
        uint256 tokenId,
        IERC20 cToken,
        IERC20 token,
        uint256 amount
    )
        external;

    function repay(
        uint256 tokenId,
        IERC20 cToken,
        IERC20 token,
        uint256 amount
    )
        external
        payable;
}












contract CompoundTokenization is
    ERC721,
    ERC721Enumerable,
    ERC721Metadata("Compound Position Token", "cPosition"),
    Ownable,
    ILoanPoolLoaner,
    ITokenizer,
    GasDiscounter
{

    using UniversalERC20 for IERC20;

    modifier onlyTokenOwner(uint256 tokenId) {
        require(tokenId == 0 || ownerOf(tokenId) == msg.sender, "Wrong tokenId");
        _;
    }

    function _enterMarket(
        LoanHolder holder,
        ICompoundController controller,
        address cToken1,
        address cToken2
    )
        internal
        returns(LoanHolder)
    {
        holder.perform(address(controller), 0, abi.encodeWithSelector(
            controller.enterMarkets.selector,
            uint256(0x20),  
            uint256(2),     
            cToken1,
            cToken2
        ));
    }

    function enterMarkets(
        uint256 tokenId,
        address controller,
        address[] calldata cTokens
    )
        external
        onlyTokenOwner(tokenId)
        returns(bytes memory ret)
    {
        LoanHolder holder = LoanHolder(address(tokenId));

        ret = holder.perform(controller, 0, abi.encodeWithSelector(
            ICompoundController(controller).enterMarkets.selector,
            cTokens
        ));
    }

    function migrate(
        ILoanPool pool,
        IERC20 collateralToken,
        uint256 collateralAmount,
        IERC20 borrowedToken,
        IERC20 borrowedUnderlyingToken,
        uint256 borrowedAmount,
        address msgSender
    )
        public
        withLoan(
            pool,
            borrowedUnderlyingToken,
            borrowedAmount = ICERC20(address(borrowedToken)).borrowBalanceCurrent(msgSender)
        )
    {
        LoanHolder holder = new LoanHolder();
        _enterMarket(
            holder,
            ICERC20(address(borrowedToken)).comptroller(),
            address(collateralToken),
            address(borrowedToken)
        );

         
        borrowedUnderlyingToken.universalApprove(address(borrowedToken), borrowedAmount);
        ICERC20(address(borrowedToken)).repayBorrowBehalf(msgSender, borrowedAmount);
        collateralToken.universalTransferFrom(msgSender, address(holder), collateralAmount);

         
        holder.perform(address(borrowedToken), 0, abi.encodeWithSelector(
            ICERC20(address(borrowedToken)).borrow.selector,
            _getExpectedReturn()
        ));

         
        if (borrowedToken == IERC20(0)) {
            holder.perform(address(msgSender), _getExpectedReturn(), "");
        } else {
            holder.perform(address(borrowedUnderlyingToken), 0, abi.encodeWithSelector(
                borrowedUnderlyingToken.transfer.selector,
                address(pool),
                _getExpectedReturn()
            ));
        }

         
        _mint(msgSender, uint256(address(holder)));
    }

    function mint(
        uint256 tokenId,
        IERC20 cToken,
        IERC20 token,
        uint256 amount
    )
        external
        gasDiscount
        onlyTokenOwner(tokenId)
        payable
    {
        LoanHolder holder = LoanHolder(address(tokenId));
        if (tokenId == 0) {
            holder = new LoanHolder();
            _enterMarket(holder, ICERC20(address(cToken)).comptroller(), address(cToken), address(0));
            _mint(msg.sender, uint256(address(holder)));
        }

        token.universalTransferFrom(msg.sender, address(this), amount);
        token.universalApprove(address(token), amount);
        if (msg.value == 0) {
            ICERC20(address(cToken)).mint(amount);
        } else {
            (bool success,) = address(cToken).call.value(msg.value)(
                abi.encodeWithSignature("mint()")
            );
            require(success, "");
        }
        cToken.universalTransfer(
            address(holder),
            cToken.universalBalanceOf(address(this))
        );
    }

    function redeem(
        uint256 tokenId,
        IERC20 cToken,
        IERC20 token,
        uint256 amount
    )
        external
        gasDiscount
        onlyTokenOwner(tokenId)
    {
        LoanHolder holder = LoanHolder(address(tokenId));

        holder.perform(address(cToken), 0, abi.encodeWithSelector(
            ICERC20(address(cToken)).redeem.selector,
            amount
        ));

        if (token != IERC20(0)) {
            holder.perform(address(token), 0, abi.encodeWithSelector(
                token.transfer.selector,
                msg.sender,
                token.universalBalanceOf(address(holder))
            ));
        } else {
            holder.perform(msg.sender, token.universalBalanceOf(address(holder)), "");
        }
    }

    function borrow(
        uint256 tokenId,
        IERC20 cToken,
        IERC20 token,
        uint256 amount
    )
        external
        gasDiscount
        onlyTokenOwner(tokenId)
    {
        require(ownerOf(tokenId) == msg.sender, "Wrong tokenId");
        LoanHolder holder = LoanHolder(address(tokenId));

        holder.perform(address(cToken), 0, abi.encodeWithSelector(
            ICERC20(address(cToken)).borrow.selector,
            amount
        ));

        if (token != IERC20(0)) {
            holder.perform(address(token), 0, abi.encodeWithSelector(
                token.transfer.selector,
                msg.sender,
                token.universalBalanceOf(address(holder))
            ));
        } else {
            holder.perform(msg.sender, token.universalBalanceOf(address(holder)), "");
        }
    }

    function repay(
        uint256 tokenId,
        IERC20 cToken,
        IERC20 token,
        uint256 amount
    )
        public
        gasDiscount
        onlyTokenOwner(tokenId)
        payable
    {
        LoanHolder holder = LoanHolder(address(tokenId));

        uint256 borrowAmount = ICERC20(address(cToken)).borrowBalanceCurrent(msg.sender);
        if (amount > borrowAmount) {
            amount = borrowAmount;
        }

        token.universalTransferFrom(msg.sender, address(this), amount);
        token.universalApprove(address(cToken), amount);
        if (token != IERC20(0)) {
            ICERC20(address(cToken)).repayBorrowBehalf(address(holder), amount);
        } else {
            (bool success,) = address(cToken).call.value(msg.value)(
                abi.encodeWithSignature(
                    "repayBorrowBehalf(address)",
                    address(holder)
                )
            );
            require(success, "");
        }
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    function reclaimToken(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.universalTransfer(owner(), balance);
    }
}