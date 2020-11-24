 

 

pragma solidity 0.5.11;

contract SafeMath {

    function safeMul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(
            c / a == b,
            "UINT256_OVERFLOW"
        );
        return c;
    }

    function safeDiv(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        require(
            b <= a,
            "UINT256_UNDERFLOW"
        );
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        require(
            c >= a,
            "UINT256_OVERFLOW"
        );
        return c;
    }

    function max64(uint64 a, uint64 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}


 
library Address {

     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}

 
 
 
interface IERC1155 {

     
     
     
     
     
     
     
     
     
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

     
     
     
     
     
     
     
     
     
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

     
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

     
     
     
    event URI(
        string value,
        uint256 indexed id
    );

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external;

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external;

     
     
     
     
    function setApprovalForAll(address operator, bool approved) external;

     
     
     
     
    function isApprovedForAll(address owner, address operator) external view returns (bool);

     
     
     
     
    function balanceOf(address owner, uint256 id) external view returns (uint256);

     
     
     
     
    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    )
        external
        view
        returns (uint256[] memory balances_);
}

 

interface IERC1155Receiver {

     
     
     
     
     
     
     
     
     
     
     
     
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

     
     
     
     
     
     
     
     
     
     
     
     
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

 

 

contract MNonFungibleToken {

     
    function isNonFungible(uint256 id) public pure returns(bool);

     
    function isFungible(uint256 _d) public pure returns(bool);

     
    function getNonFungibleIndex(uint256 id) public pure returns(uint256);

     
    function getNonFungibleBaseType(uint256 id) public pure returns(uint256);

     
    function isNonFungibleBaseType(uint256 id) public pure returns(bool);

     
    function isNonFungibleItem(uint256 id) public pure returns(bool);

     
    function ownerOf(uint256 id) public view returns (address);
}

contract MixinNonFungibleToken is
    MNonFungibleToken
{
     
     
    uint256 constant internal TYPE_MASK = uint256(uint128(~0)) << 128;

     
    uint256 constant internal NF_INDEX_MASK = uint128(~0);

     
    uint256 constant internal TYPE_NF_BIT = 1 << 255;

     
    mapping (uint256 => address) internal nfOwners;

     
    function isNonFungible(uint256 id) public pure returns(bool) {
        return id & TYPE_NF_BIT == TYPE_NF_BIT;
    }

     
    function isFungible(uint256 id) public pure returns(bool) {
        return id & TYPE_NF_BIT == 0;
    }

     
    function getNonFungibleIndex(uint256 id) public pure returns(uint256) {
        return id & NF_INDEX_MASK;
    }

     
    function getNonFungibleBaseType(uint256 id) public pure returns(uint256) {
        return id & TYPE_MASK;
    }

     
    function isNonFungibleBaseType(uint256 id) public pure returns(bool) {
         
        return (id & TYPE_NF_BIT == TYPE_NF_BIT) && (id & NF_INDEX_MASK == 0);
    }

     
    function isNonFungibleItem(uint256 id) public pure returns(bool) {
         
        return (id & TYPE_NF_BIT == TYPE_NF_BIT) && (id & NF_INDEX_MASK != 0);
    }

     
    function ownerOf(uint256 id) public view returns (address) {
        return nfOwners[id];
    }
}

contract ERC1155 is
    SafeMath,
    IERC1155,
    MixinNonFungibleToken
{
    using Address for address;

     
    bytes4 constant public ERC1155_RECEIVED       = 0xf23a6e61;
    bytes4 constant public ERC1155_BATCH_RECEIVED = 0xbc197c81;

     
    mapping (uint256 => mapping(address => uint256)) internal balances;

     
    mapping (address => mapping(address => bool)) internal operatorApproval;

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
    {
         
        require(
            to != address(0x0),
            "CANNOT_TRANSFER_TO_ADDRESS_ZERO"
        );
        require(
            from == msg.sender || operatorApproval[from][msg.sender] == true,
            "INSUFFICIENT_ALLOWANCE"
        );

         
        if (isNonFungible(id)) {
            require(
                    value == 1,
                    "AMOUNT_EQUAL_TO_ONE_REQUIRED"
            );
            require(
                nfOwners[id] == from,
                "NFT_NOT_OWNED_BY_FROM_ADDRESS"
            );
            nfOwners[id] = to;
             
             
             
             
        } else {
            balances[id][from] = safeSub(balances[id][from], value);
            balances[id][to] = safeAdd(balances[id][to], value);
        }
        emit TransferSingle(msg.sender, from, to, id, value);

         
        if (to.isContract()) {
            bytes4 callbackReturnValue = IERC1155Receiver(to).onERC1155Received(
                msg.sender,
                from,
                id,
                value,
                data
            );
            require(
                callbackReturnValue == ERC1155_RECEIVED,
                "BAD_RECEIVER_RETURN_VALUE"
            );
        }
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
    {
         
        require(
            to != address(0x0),
            "CANNOT_TRANSFER_TO_ADDRESS_ZERO"
        );
        require(
            ids.length == values.length,
            "TOKEN_AND_VALUES_LENGTH_MISMATCH"
        );

         
         
        require(
            from == msg.sender || operatorApproval[from][msg.sender] == true,
            "INSUFFICIENT_ALLOWANCE"
        );

         
        for (uint256 i = 0; i < ids.length; ++i) {
             
            uint256 id = ids[i];
            uint256 value = values[i];

            if (isNonFungible(id)) {
                require(
                    value == 1,
                    "AMOUNT_EQUAL_TO_ONE_REQUIRED"
                );
                require(
                    nfOwners[id] == from,
                    "NFT_NOT_OWNED_BY_FROM_ADDRESS"
                );
                nfOwners[id] = to;
            } else {
                balances[id][from] = safeSub(balances[id][from], value);
                balances[id][to] = safeAdd(balances[id][to], value);
            }
        }
        emit TransferBatch(msg.sender, from, to, ids, values);

         
        if (to.isContract()) {
            bytes4 callbackReturnValue = IERC1155Receiver(to).onERC1155BatchReceived(
                msg.sender,
                from,
                ids,
                values,
                data
            );
            require(
                callbackReturnValue == ERC1155_BATCH_RECEIVED,
                "BAD_RECEIVER_RETURN_VALUE"
            );
        }
    }

     
     
     
     
    function setApprovalForAll(address operator, bool approved) external {
        operatorApproval[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

     
     
     
     
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return operatorApproval[owner][operator];
    }

     
     
     
     
    function balanceOf(address owner, uint256 id) external view returns (uint256) {
        if (isNonFungibleItem(id)) {
            return nfOwners[id] == owner ? 1 : 0;
        }
        return balances[id][owner];
    }

     
     
     
     
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory balances_) {
         
        require(
            owners.length == ids.length,
            "OWNERS_AND_IDS_MUST_HAVE_SAME_LENGTH"
        );

         
        balances_ = new uint256[](owners.length);
        for (uint256 i = 0; i < owners.length; ++i) {
            uint256 id = ids[i];
            if (isNonFungibleItem(id)) {
                balances_[i] = nfOwners[id] == owners[i] ? 1 : 0;
            } else {
                balances_[i] = balances[id][owners[i]];
            }
        }

        return balances_;
    }
}

 
 
contract IERC1155Mintable is
    IERC1155
{

     
     
     
     
    function create(
        string calldata uri,
        bool isNF
    )
        external
        returns (uint256 type_);

     
     
     
     
    function mintFungible(
        uint256 id,
        address[] calldata to,
        uint256[] calldata quantities
    )
        external;

     
     
     
    function mintNonFungible(
        uint256 type_,
        address[] calldata to
    )
        external;
}

 
 
contract ERC1155Mintable is
    IERC1155Mintable,
    ERC1155
{

     
    uint256 internal nonce;

     
    mapping (uint256 => address) public creators;

     
    mapping (uint256 => uint256) public maxIndex;

     
    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == msg.sender);
        _;
    }

     
     
     
     
    function create(
        string calldata uri,
        bool isNF
    )
        external
        returns (uint256 type_)
    {
         
        type_ = (++nonce << 128);

         
        if (isNF) {
            type_ = type_ | TYPE_NF_BIT;
        }

         
        creators[type_] = msg.sender;

         
        emit TransferSingle(
            msg.sender,
            address(0x0),
            address(0x0),
            type_,
            0
        );

        if (bytes(uri).length > 0) {
            emit URI(uri, type_);
        }
    }

     
     
     
    function createWithType(
        uint256 type_,
        string calldata uri
    )
        external
    {
         
        creators[type_] = msg.sender;

         
        emit TransferSingle(
            msg.sender,
            address(0x0),
            address(0x0),
            type_,
            0
        );

        if (bytes(uri).length > 0) {
            emit URI(uri, type_);
        }
    }

     
     
     
     
    function mintFungible(
        uint256 id,
        address[] calldata to,
        uint256[] calldata quantities
    )
        external
        creatorOnly(id)
    {
         
        require(
            isFungible(id),
            "TRIED_TO_MINT_FUNGIBLE_FOR_NON_FUNGIBLE_TOKEN"
        );

         
        for (uint256 i = 0; i < to.length; ++i) {
             
            address dst = to[i];
            uint256 quantity = quantities[i];

             
            balances[id][dst] = safeAdd(quantity, balances[id][dst]);

             
             
             
            emit TransferSingle(
                msg.sender,
                address(0x0),
                dst,
                id,
                quantity
            );

             
            if (dst.isContract()) {
                bytes4 callbackReturnValue = IERC1155Receiver(dst).onERC1155Received(
                    msg.sender,
                    msg.sender,
                    id,
                    quantity,
                    ""
                );
                require(
                    callbackReturnValue == ERC1155_RECEIVED,
                    "BAD_RECEIVER_RETURN_VALUE"
                );
            }
        }
    }

     
     
     
    function mintNonFungible(
        uint256 type_,
        address[] calldata to
    )
        external
        creatorOnly(type_)
    {
         
         
        require(
            isNonFungible(type_),
            "TRIED_TO_MINT_NON_FUNGIBLE_FOR_FUNGIBLE_TOKEN"
        );

         
        uint256 index = maxIndex[type_] + 1;

        for (uint256 i = 0; i < to.length; ++i) {
             
            address dst = to[i];
            uint256 id  = type_ | index + i;

            nfOwners[id] = dst;

             
             

            emit TransferSingle(msg.sender, address(0x0), dst, id, 1);

             
            if (dst.isContract()) {
                bytes4 callbackReturnValue = IERC1155Receiver(dst).onERC1155Received(
                    msg.sender,
                    msg.sender,
                    id,
                    1,
                    ""
                );
                require(
                    callbackReturnValue == ERC1155_RECEIVED,
                    "BAD_RECEIVER_RETURN_VALUE"
                );
            }
        }

         
         
        maxIndex[type_] = safeAdd(to.length, maxIndex[type_]);
    }
}

contract IOwnable {

    function transferOwnership(address newOwner)
        public;
}

contract Ownable is
    IOwnable
{
    address public owner;

    constructor ()
        public
    {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "ONLY_CONTRACT_OWNER"
        );
        _;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract VotedToken is
    ERC1155Mintable,
    Ownable
{
     
     
     
     
    function create(
        string calldata uri,
        bool isNF
    )
        external
        onlyOwner()
        returns (uint256 type_)
    {
         
        type_ = (++nonce << 128);

         
        if (isNF) {
            type_ = type_ | TYPE_NF_BIT;
        }

         
        creators[type_] = msg.sender;

         
        emit TransferSingle(
            msg.sender,
            address(0x0),
            address(0x0),
            type_,
            0
        );

        if (bytes(uri).length > 0) {
            emit URI(uri, type_);
        }
    }

     
     
     
    function createWithType(
        uint256 type_,
        string calldata uri
    )
        external
        onlyOwner()
    {
         
        creators[type_] = msg.sender;

         
        emit TransferSingle(
            msg.sender,
            address(0x0),
            address(0x0),
            type_,
            0
        );

        if (bytes(uri).length > 0) {
            emit URI(uri, type_);
        }
    }

}