 
contract UtilityTokenFactory is UtilityFactoryInterface, Ownable {

    constructor(address _token, uint256 _price, address _fundsHolder) public {
        require(_token != address(0), "Token address cannot be 0");
        require(_price > 0, "price should be more than 0");
        require(_fundsHolder != address(0), "FundsHolder address cannot be zero");
        metmToken = _token;
        price = _price;
        fundsHolder = FundsHolder(_fundsHolder);
    }

    function setFundsHolderAddress(address _fundsHolder) external onlyOwner {
        require(_fundsHolder!=address(0), "address cannot be 0x");
        fundsHolder = FundsHolder(_fundsHolder);
    }

    function setPrice(uint256 _price) external onlyOwner {
        require(_price > 0, "Price cannot be 0");
        price = _price;
    }

    function createToken(string _symbol, string _name, uint256 _initialSupply, uint8 _decimals, bool _mintable, bool _burnable) external {
        require(bytes(_symbol).length >= 2, "Symbol length should be more than 2");
        require(bytes(_name).length >= 2, "Name length should be more than 2");
        require(_initialSupply >= 0, "Supply has to be more or equal than 0");
        require(_decimals > 0, "Decimals has to be more than 0");
        require(IERC20(metmToken).allowance(msg.sender, address(this)) >= price, "Insufficent allowance");
        require(IERC20(metmToken).transferFrom(msg.sender, address(fundsHolder), price), "EVM Error");
        ERC20Detailed uToken = new ERC20Detailed(_name, _symbol, _decimals, _initialSupply, _mintable, _burnable);
        TokenSettings memory settings = TokenSettings({
            ts: now,
            price: price,
            name: _name,
            symbol: _symbol,
            tokenAddress: address(uToken)
        });
        issuerTokens[msg.sender].push(address(uToken));
        issuerTokensData[msg.sender][address(uToken)] = settings;
        issuers.push(msg.sender);
        tokens.push(address(uToken));
        uToken.transfer(msg.sender, uToken.balanceOf(this));
        uToken.transferOwnership(msg.sender);
        emit Issued(msg.sender, _symbol, _name, _initialSupply, _decimals);
    }

    function getAlltokens(address _issuer) public view returns (address[]) {
        return issuerTokens[_issuer];
    }

    function getInfo(address _issuer, address _token) public view
    returns (uint256, string, string, uint8, uint256, uint256, bool, bool) {
        TokenSettings memory settings = issuerTokensData[_issuer][_token];
        ERC20Detailed uToken = ERC20Detailed(_token);
        return(
            settings.price,
            settings.name,
            settings.symbol,
            uToken.decimals(),
            uToken.totalSupply(),
            settings.ts,
            uToken.mintable(),
            uToken.burnable()
        );
    }

    function getNumOfTokens() public view returns (uint256) {
        return tokens.length;
    }

    function getNumOfIssuers() public view returns (uint256) {
        return issuers.length;
    }

    function getFundsHolderAddress() public view returns (address) {
        return address(fundsHolder);
    }
}
