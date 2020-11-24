 

pragma solidity 0.4.18;

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract TokenRegistry is Ownable {
    mapping (bytes32 => TokenAttributes) public symbolHashToTokenAttributes;
    string[256] public tokenSymbolList;
    uint8 public tokenSymbolListLength;

    struct TokenAttributes {
         
        address tokenAddress;
         
        uint tokenIndex;
         
        string name;
         
        uint8 numDecimals;
    }

     
    function setTokenAttributes(
        string _symbol,
        address _tokenAddress,
        string _tokenName,
        uint8 _numDecimals
    )
        public onlyOwner
    {
        bytes32 symbolHash = keccak256(_symbol);

         
        TokenAttributes memory attributes = symbolHashToTokenAttributes[symbolHash];

        if (attributes.tokenAddress == address(0)) {
             
            attributes.tokenAddress = _tokenAddress;
            attributes.numDecimals = _numDecimals;
            attributes.name = _tokenName;
            attributes.tokenIndex = tokenSymbolListLength;

            tokenSymbolList[tokenSymbolListLength] = _symbol;
            tokenSymbolListLength++;
        } else {
             
            attributes.tokenAddress = _tokenAddress;
            attributes.numDecimals = _numDecimals;
            attributes.name = _tokenName;
        }

         
        symbolHashToTokenAttributes[symbolHash] = attributes;
    }

     
    function getTokenAddressBySymbol(string _symbol) public view returns (address) {
        bytes32 symbolHash = keccak256(_symbol);

        TokenAttributes storage attributes = symbolHashToTokenAttributes[symbolHash];

        return attributes.tokenAddress;
    }

     
    function getTokenAddressByIndex(uint _index) public view returns (address) {
        string storage symbol = tokenSymbolList[_index];

        return getTokenAddressBySymbol(symbol);
    }

     
    function getTokenIndexBySymbol(string _symbol) public view returns (uint) {
        bytes32 symbolHash = keccak256(_symbol);

        TokenAttributes storage attributes = symbolHashToTokenAttributes[symbolHash];

        return attributes.tokenIndex;
    }

     
    function getTokenSymbolByIndex(uint _index) public view returns (string) {
        return tokenSymbolList[_index];
    }

     
    function getTokenNameBySymbol(string _symbol) public view returns (string) {
        bytes32 symbolHash = keccak256(_symbol);

        TokenAttributes storage attributes = symbolHashToTokenAttributes[symbolHash];

        return attributes.name;
    }

     
    function getNumDecimalsFromSymbol(string _symbol) public view returns (uint8) {
        bytes32 symbolHash = keccak256(_symbol);

        TokenAttributes storage attributes = symbolHashToTokenAttributes[symbolHash];

        return attributes.numDecimals;
    }

     
    function getNumDecimalsByIndex(uint _index) public view returns (uint8) {
        string memory symbol = getTokenSymbolByIndex(_index);

        return getNumDecimalsFromSymbol(symbol);
    }

     
    function getTokenNameByIndex(uint _index) public view returns (string) {
        string memory symbol = getTokenSymbolByIndex(_index);

        string memory tokenName = getTokenNameBySymbol(symbol);

        return tokenName;
    }

     
    function getTokenAttributesBySymbol(string _symbol)
        public
        view
        returns (
            address,
            uint,
            string,
            uint
        )
    {
        bytes32 symbolHash = keccak256(_symbol);

        TokenAttributes storage attributes = symbolHashToTokenAttributes[symbolHash];

        return (
            attributes.tokenAddress,
            attributes.tokenIndex,
            attributes.name,
            attributes.numDecimals
        );
    }

     
    function getTokenAttributesByIndex(uint _index)
        public
        view
        returns (
            address,
            string,
            string,
            uint8
        )
    {
        string memory symbol = getTokenSymbolByIndex(_index);

        bytes32 symbolHash = keccak256(symbol);

        TokenAttributes storage attributes = symbolHashToTokenAttributes[symbolHash];

        return (
            attributes.tokenAddress,
            symbol,
            attributes.name,
            attributes.numDecimals
        );
    }
}