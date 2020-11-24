 

 

pragma solidity 0.4.24;

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract TokenRegistry is Ownable {

    event LogAddToken(
        address indexed token,
        string name,
        string symbol,
        uint8 decimals,
        string url
    );

    event LogRemoveToken(
        address indexed token,
        string name,
        string symbol,
        uint8 decimals,
        string url
    );

    event LogTokenNameChange(address indexed token, string oldName, string newName);
    event LogTokenSymbolChange(address indexed token, string oldSymbol, string newSymbol);
    event LogTokenURLChange(address indexed token, string oldURL, string newURL);

    mapping (address => TokenMetadata) public tokens;
    mapping (string => address) internal tokenBySymbol;
    mapping (string => address) internal tokenByName;

    address[] public tokenAddresses;

    struct TokenMetadata {
        address token;
        string name;
        string symbol;
        uint8 decimals;
        string url;
    }

    modifier tokenExists(address _token) {
        require(tokens[_token].token != address(0), "TokenRegistry::token doesn't exist");
        _;
    }

    modifier tokenDoesNotExist(address _token) {
        require(tokens[_token].token == address(0), "TokenRegistry::token exists");
        _;
    }

    modifier nameDoesNotExist(string _name) {
        require(tokenByName[_name] == address(0), "TokenRegistry::name exists");
        _;
    }

    modifier symbolDoesNotExist(string _symbol) {
        require(tokenBySymbol[_symbol] == address(0), "TokenRegistry::symbol exists");
        _;
    }

    modifier addressNotNull(address _address) {
        require(_address != address(0), "TokenRegistry::address is null");
        _;
    }

     
     
     
     
     
     
    function addToken(
        address _token,
        string _name,
        string _symbol,
        uint8 _decimals,
        string _url)
        public
        onlyOwner
        tokenDoesNotExist(_token)
        addressNotNull(_token)
        symbolDoesNotExist(_symbol)
        nameDoesNotExist(_name)
    {
        tokens[_token] = TokenMetadata({
            token: _token,
            name: _name,
            symbol: _symbol,
            decimals: _decimals,
            url: _url
        });
        tokenAddresses.push(_token);
        tokenBySymbol[_symbol] = _token;
        tokenByName[_name] = _token;
        emit LogAddToken(
            _token,
            _name,
            _symbol,
            _decimals,
            _url
        );
    }

     
     
    function removeToken(address _token, uint _index)
        public
        onlyOwner
        tokenExists(_token)
    {
        require(tokenAddresses[_index] == _token, "TokenRegistry::invalid index");

        tokenAddresses[_index] = tokenAddresses[tokenAddresses.length - 1];
        tokenAddresses.length -= 1;

        TokenMetadata storage token = tokens[_token];
        emit LogRemoveToken(
            token.token,
            token.name,
            token.symbol,
            token.decimals,
            token.url
        );
        delete tokenBySymbol[token.symbol];
        delete tokenByName[token.name];
        delete tokens[_token];
    }

     
     
     
    function setTokenName(address _token, string _name)
        public
        onlyOwner
        tokenExists(_token)
        nameDoesNotExist(_name)
    {
        TokenMetadata storage token = tokens[_token];
        emit LogTokenNameChange(_token, token.name, _name);
        delete tokenByName[token.name];
        tokenByName[_name] = _token;
        token.name = _name;
    }

     
     
     
    function setTokenSymbol(address _token, string _symbol)
        public
        onlyOwner
        tokenExists(_token)
        symbolDoesNotExist(_symbol)
    {
        TokenMetadata storage token = tokens[_token];
        emit LogTokenSymbolChange(_token, token.symbol, _symbol);
        delete tokenBySymbol[token.symbol];
        tokenBySymbol[_symbol] = _token;
        token.symbol = _symbol;
    }

     
     
     
    function setTokenURL(address _token, string _url)
        public
        onlyOwner
        tokenExists(_token)
    {
        TokenMetadata storage token = tokens[_token];
        emit LogTokenURLChange(_token, token.url, _url);
        token.url = _url;
    }

     
     
     
     
    function getTokenAddressBySymbol(string _symbol) 
        public
        view 
        returns (address)
    {
        return tokenBySymbol[_symbol];
    }

     
     
     
    function getTokenAddressByName(string _name) 
        public
        view
        returns (address)
    {
        return tokenByName[_name];
    }

     
     
     
    function getTokenMetaData(address _token)
        public
        view
        returns (
            address,   
            string,    
            string,    
            uint8,     
            string     
        )
    {
        TokenMetadata memory token = tokens[_token];
        return (
            token.token,
            token.name,
            token.symbol,
            token.decimals,
            token.url
        );
    }

     
     
     
    function getTokenByName(string _name)
        public
        view
        returns (
            address,   
            string,    
            string,    
            uint8,     
            string     
        )
    {
        address _token = tokenByName[_name];
        return getTokenMetaData(_token);
    }

     
     
     
    function getTokenBySymbol(string _symbol)
        public
        view
        returns (
            address,   
            string,    
            string,    
            uint8,     
            string     
        )
    {
        address _token = tokenBySymbol[_symbol];
        return getTokenMetaData(_token);
    }

     
     
    function getTokenAddresses()
        public
        view
        returns (address[])
    {
        return tokenAddresses;
    }
}