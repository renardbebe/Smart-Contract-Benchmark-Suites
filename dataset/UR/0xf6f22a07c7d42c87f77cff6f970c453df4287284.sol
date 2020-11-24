 

pragma solidity ^0.5.0;

pragma solidity ^0.5.0;

 
contract ERC20Proxy {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    function onTransfer(address _from, address _to, uint256 _value) external;
}

pragma solidity ^0.5.0;

contract Operators
{
    mapping (address=>bool) ownerAddress;
    mapping (address=>bool) operatorAddress;

    constructor() public
    {
        ownerAddress[msg.sender] = true;
    }

    modifier onlyOwner()
    {
        require(ownerAddress[msg.sender]);
        _;
    }

    function isOwner(address _addr) public view returns (bool) {
        return ownerAddress[_addr];
    }

    function addOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));

        ownerAddress[_newOwner] = true;
    }

    function removeOwner(address _oldOwner) external onlyOwner {
        delete(ownerAddress[_oldOwner]);
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender));
        _;
    }

    function isOperator(address _addr) public view returns (bool) {
        return operatorAddress[_addr] || ownerAddress[_addr];
    }

    function addOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0));

        operatorAddress[_newOperator] = true;
    }

    function removeOperator(address _oldOperator) external onlyOwner {
        delete(operatorAddress[_oldOperator]);
    }
}

pragma solidity ^0.5.0;

interface BlockchainCutiesERC1155Interface
{
    function mintNonFungibleSingleShort(uint128 _type, address _to) external;
    function mintNonFungibleSingle(uint256 _type, address _to) external;
    function mintNonFungibleShort(uint128 _type, address[] calldata _to) external;
    function mintNonFungible(uint256 _type, address[] calldata _to) external;
    function mintFungibleSingle(uint256 _id, address _to, uint256 _quantity) external;
    function mintFungible(uint256 _id, address[] calldata _to, uint256[] calldata _quantities) external;
    function isNonFungible(uint256 _id) external pure returns(bool);
    function ownerOf(uint256 _id) external view returns (address);
    function totalSupplyNonFungible(uint256 _type) view external returns (uint256);
    function totalSupplyNonFungibleShort(uint128 _type) view external returns (uint256);

     
    function uri(uint256 _id) external view returns (string memory);
    function proxyTransfer721(address _from, address _to, uint256 _tokenId, bytes calldata _data) external;
    function proxyTransfer20(address _from, address _to, uint256 _tokenId, uint256 _value) external;
     
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
     
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
}


contract Proxy20_1155 is ERC20Proxy, Operators {

    BlockchainCutiesERC1155Interface public erc1155;
    uint256 public tokenId;
    string public tokenName;
    string public tokenSymbol;
    bool public canSetup = true;
    uint256 totalTokens = 0;

    modifier canBeStoredIn128Bits(uint256 _value)
    {
        require(_value <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        _;
    }

    function setup(
        BlockchainCutiesERC1155Interface _erc1155,
        uint256 _tokenId,
        string calldata _tokenSymbol,
        string calldata _tokenName) external onlyOwner canBeStoredIn128Bits(_tokenId)
    {
        require(canSetup);
        erc1155 = _erc1155;
        tokenId = _tokenId;
        tokenSymbol = _tokenSymbol;
        tokenName = _tokenName;
    }

    function disableSetup() external onlyOwner
    {
        canSetup = false;
    }

     
    function name() external view returns (string memory)
    {
        return tokenName;
    }

     
    function symbol() external view returns (string memory)
    {
        return tokenSymbol;
    }

    function totalSupply() external view returns (uint)
    {
        return totalTokens;
    }

    function balanceOf(address tokenOwner) external view returns (uint balance)
    {
        balance = erc1155.balanceOf(tokenOwner, tokenId);
    }

    function allowance(address, address) external view returns (uint)
    {
        return 0;
    }

    function transfer(address _to, uint _value) external returns (bool)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal
    {
        erc1155.proxyTransfer20(_from, _to, tokenId, _value);
    }

    function approve(address, uint) external returns (bool)
    {
        revert();
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool)
    {
        _transfer(_from, _to, _value);
        return true;
    }

    function onTransfer(address _from, address _to, uint256 _value) external
    {
        require(msg.sender == address(erc1155));
        emit Transfer(_from, _to, _value);
        if (_from == address(0x0))
        {
            totalTokens += _value;
        }
        if (_to == address(0x0))
        {
            totalTokens -= _value;
        }
    }
}