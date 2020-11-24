 

 

pragma solidity ^0.4.24;

 
contract IOwned {
     
    function owner() public view returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

 

pragma solidity ^0.4.24;


 
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

 

pragma solidity ^0.4.24;

 
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

 

pragma solidity ^0.4.24;


 
contract BancorConverterRegistry is Owned, Utils {
    mapping (address => bool) private tokensRegistered;          
    mapping (address => address[]) private tokensToConverters;   
    mapping (address => address) private convertersToTokens;     
    address[] public tokens;                                     

     
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
        if (_index >= tokensToConverters[_token].length)
            return address(0);

        return tokensToConverters[_token][_index];
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

         
        if (!tokensRegistered[_token]) {
            tokens.push(_token);
            tokensRegistered[_token] = true;
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
        
         
        delete convertersToTokens[converter];

         
        emit ConverterRemoval(_token, converter);
    }
}