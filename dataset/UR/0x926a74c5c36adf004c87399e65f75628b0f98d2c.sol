 

 

pragma solidity 0.4.11;

 
contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}


 
 
contract TokenRegistry is Ownable {

    event LogAddToken(
        address indexed token,
        string name,
        string symbol,
        uint8 decimals,
        bytes ipfsHash,
        bytes swarmHash
    );

    event LogRemoveToken(
        address indexed token,
        string name,
        string symbol,
        uint8 decimals,
        bytes ipfsHash,
        bytes swarmHash
    );

    event LogTokenNameChange(address indexed token, string oldName, string newName);
    event LogTokenSymbolChange(address indexed token, string oldSymbol, string newSymbol);
    event LogTokenIpfsHashChange(address indexed token, bytes oldIpfsHash, bytes newIpfsHash);
    event LogTokenSwarmHashChange(address indexed token, bytes oldSwarmHash, bytes newSwarmHash);

    mapping (address => TokenMetadata) public tokens;
    mapping (string => address) tokenBySymbol;
    mapping (string => address) tokenByName;

    address[] public tokenAddresses;

    struct TokenMetadata {
        address token;
        string name;
        string symbol;
        uint8 decimals;
        bytes ipfsHash;
        bytes swarmHash;
    }

    modifier tokenExists(address _token) {
        require(tokens[_token].token != address(0));
        _;
    }

    modifier tokenDoesNotExist(address _token) {
        require(tokens[_token].token == address(0));
        _;
    }

    modifier nameDoesNotExist(string _name) {
      require(tokenByName[_name] == address(0));
      _;
    }

    modifier symbolDoesNotExist(string _symbol) {
        require(tokenBySymbol[_symbol] == address(0));
        _;
    }

    modifier addressNotNull(address _address) {
        require(_address != address(0));
        _;
    }


     
     
     
     
     
     
     
    function addToken(
        address _token,
        string _name,
        string _symbol,
        uint8 _decimals,
        bytes _ipfsHash,
        bytes _swarmHash)
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
            ipfsHash: _ipfsHash,
            swarmHash: _swarmHash
        });
        tokenAddresses.push(_token);
        tokenBySymbol[_symbol] = _token;
        tokenByName[_name] = _token;
        LogAddToken(
            _token,
            _name,
            _symbol,
            _decimals,
            _ipfsHash,
            _swarmHash
        );
    }

     
     
    function removeToken(address _token, uint _index)
        public
        onlyOwner
        tokenExists(_token)
    {
        require(tokenAddresses[_index] == _token);

        tokenAddresses[_index] = tokenAddresses[tokenAddresses.length - 1];
        tokenAddresses.length -= 1;

        TokenMetadata storage token = tokens[_token];
        LogRemoveToken(
            token.token,
            token.name,
            token.symbol,
            token.decimals,
            token.ipfsHash,
            token.swarmHash
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
        LogTokenNameChange(_token, token.name, _name);
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
        LogTokenSymbolChange(_token, token.symbol, _symbol);
        delete tokenBySymbol[token.symbol];
        tokenBySymbol[_symbol] = _token;
        token.symbol = _symbol;
    }

     
     
     
    function setTokenIpfsHash(address _token, bytes _ipfsHash)
        public
        onlyOwner
        tokenExists(_token)
    {
        TokenMetadata storage token = tokens[_token];
        LogTokenIpfsHashChange(_token, token.ipfsHash, _ipfsHash);
        token.ipfsHash = _ipfsHash;
    }

     
     
     
    function setTokenSwarmHash(address _token, bytes _swarmHash)
        public
        onlyOwner
        tokenExists(_token)
    {
        TokenMetadata storage token = tokens[_token];
        LogTokenSwarmHashChange(_token, token.swarmHash, _swarmHash);
        token.swarmHash = _swarmHash;
    }

     

     
     
     
    function getTokenAddressBySymbol(string _symbol) constant returns (address) {
        return tokenBySymbol[_symbol];
    }

     
     
     
    function getTokenAddressByName(string _name) constant returns (address) {
        return tokenByName[_name];
    }

     
     
     
    function getTokenMetaData(address _token)
        public
        constant
        returns (
            address,   
            string,    
            string,    
            uint8,     
            bytes,     
            bytes      
        )
    {
        TokenMetadata memory token = tokens[_token];
        return (
            token.token,
            token.name,
            token.symbol,
            token.decimals,
            token.ipfsHash,
            token.swarmHash
        );
    }

     
     
     
    function getTokenByName(string _name)
        public
        constant
        returns (
            address,   
            string,    
            string,    
            uint8,     
            bytes,     
            bytes      
        )
    {
        address _token = tokenByName[_name];
        return getTokenMetaData(_token);
    }

     
     
     
    function getTokenBySymbol(string _symbol)
        public
        constant
        returns (
            address,   
            string,    
            string,    
            uint8,     
            bytes,     
            bytes      
        )
    {
        address _token = tokenBySymbol[_symbol];
        return getTokenMetaData(_token);
    }

     
     
    function getTokenAddresses()
        public
        constant
        returns (address[])
    {
        return tokenAddresses;
    }
}