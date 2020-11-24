 

pragma solidity 0.4.26;

 

contract IBancorConverterRegistry {
    function tokens(uint256 _index) public view returns (address) { _index; }
    function tokenCount() public view returns (uint256);
    function converterCount(address _token) public view returns (uint256);
    function converterAddress(address _token, uint32 _index) public view returns (address);
    function latestConverterAddress(address _token) public view returns (address);
    function tokenAddress(address _converter) public view returns (address);
}

 

 
contract IOwned {
     
    function owner() public view returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

 

 
contract Owned is IOwned {
    address public owner;
    address public newOwner;

     
    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 

 
contract Utils {
     
    constructor() public {
    }

     
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

     
    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

}

 

 
contract BancorConverterRegistry is IBancorConverterRegistry, Owned, Utils {
    mapping (address => address[]) private tokensToConverters;   
    mapping (address => address) private convertersToTokens;     
    address[] public tokens;                                     

    struct TokenInfo {
        bool valid;
        uint256 index;
    }

    mapping(address => TokenInfo) public tokenTable;

     
    event TokenAddition(address indexed _token);

     
    event TokenRemoval(address indexed _token);

     
    event ConverterAddition(address indexed _token, address _address);

     
    event ConverterRemoval(address indexed _token, address _address);

     
    constructor() public {
    }

     
    function tokenCount() public view returns (uint256) {
        return tokens.length;
    }

     
    function converterCount(address _token) public view returns (uint256) {
        return tokensToConverters[_token].length;
    }

     
    function converterAddress(address _token, uint32 _index) public view returns (address) {
        if (tokensToConverters[_token].length > _index)
            return tokensToConverters[_token][_index];

        return address(0);
    }

     
    function latestConverterAddress(address _token) public view returns (address) {
        if (tokensToConverters[_token].length > 0)
            return tokensToConverters[_token][tokensToConverters[_token].length - 1];

        return address(0);
    }

     
    function tokenAddress(address _converter) public view returns (address) {
        return convertersToTokens[_converter];
    }

     
    function registerConverter(address _token, address _converter)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_converter)
    {
        require(convertersToTokens[_converter] == address(0));

         
        TokenInfo storage tokenInfo = tokenTable[_token];
        if (tokenInfo.valid == false) {
            tokenInfo.valid = true;
            tokenInfo.index = tokens.push(_token) - 1;
            emit TokenAddition(_token);
        }

        tokensToConverters[_token].push(_converter);
        convertersToTokens[_converter] = _token;

         
        emit ConverterAddition(_token, _converter);
    }

     
    function unregisterConverter(address _token, uint32 _index)
        public
        ownerOnly
        validAddress(_token)
    {
        require(_index < tokensToConverters[_token].length);

        address converter = tokensToConverters[_token][_index];

         
        for (uint32 i = _index + 1; i < tokensToConverters[_token].length; i++) {
            tokensToConverters[_token][i - 1] = tokensToConverters[_token][i];
        }

         
        tokensToConverters[_token].length--;

         
        if (tokensToConverters[_token].length == 0) {
            TokenInfo storage tokenInfo = tokenTable[_token];
            assert(tokens.length > tokenInfo.index);
            assert(_token == tokens[tokenInfo.index]);
            address lastToken = tokens[tokens.length - 1];
            tokenTable[lastToken].index = tokenInfo.index;
            tokens[tokenInfo.index] = lastToken;
            tokens.length--;
            delete tokenTable[_token];
            emit TokenRemoval(_token);
        }

         
        delete convertersToTokens[converter];

         
        emit ConverterRemoval(_token, converter);
    }
}