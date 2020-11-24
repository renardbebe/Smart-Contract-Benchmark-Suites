 
    event Mint(
        uint256 indexed _artId,
        address indexed _owner
    );

    modifier onlyHolder() {
        require(msg.sender == holder);
        _;
    }
    
     
    
    function setHolder(address _requestor) public {
        if(holder==address(0)){
            require(msg.sender == owner);
            holder = _requestor;
        } else {
            require(msg.sender == holder);
            holder = _requestor;
        }
    }
    
    
    function getHolder() external view onlyOwner returns (address) {
        return holder;
    }

    function getrandPass(uint256 _tokenId) external view onlyHolder returns(bytes32){
        return randPass[_tokenId];
    }
    
    
    
     
    function mint(address _to) public onlyHolder returns (uint256) {
        require(_to != address(0));
        
        uint256 tokenId = nextId;
        nextId = nextId.add(1);
        emit Mint(tokenId, _to);
        issetPass[tokenId] = false;
        super._mint(_to, tokenId);
        return tokenId;
    }
    
     
    function burn(address _owner, uint256 _tokenId) public {
        require(_chkHoldOrOwn(msg.sender, _tokenId));
        delete artsPassPhrase[_tokenId];
        delete issetPass[_tokenId];
        burnCount.add(1);
        super._burn(_owner, _tokenId);
    }
    
     
    function setURI(uint256 _tokenId, string _uri) public onlyHolder {
        require(exists(_tokenId));
        require(issetURI[_tokenId] == false);
        issetURI[_tokenId] = true;
        _setTokenURI(_tokenId, _uri);
    }

    function resetURI(uint256 _tokenId) public onlyHolder {
        issetURI[_tokenId] = false;
    }
    
    
    function _chkHoldOrOwn(address _target, uint256 _tokenId) internal view returns (bool) {
        bool chk = false;
        if(_target != address(0)){
            if(_target == tokenOwner[_tokenId]){
                chk = true;
            } else if (_target == holder) {
                chk = true;
            }
        }
        return chk;
    }
    
    function setPass(uint256 _tokenId, string _pass) public {
        require(exists(_tokenId));
        require(_chkHoldOrOwn(msg.sender, _tokenId));
        artsPassPhrase[_tokenId] = _pass;
        issetPass[_tokenId] = true;
    }
    
    function setCreator(uint256 _tokenId, address _creator) public onlyHolder {
        require(exists(_tokenId));
        require(tokenToArtist[_tokenId] == address(0));
        tokenToArtist[_tokenId]  = _creator;
    }
    
    function tokenPass(uint256 _tokenId) external view returns (string){
        require(_chkHoldOrOwn(msg.sender, _tokenId));
        return artsPassPhrase[_tokenId];
    }
    
    function transfer(address _from, address _to, uint256 _tokenId) external onlyHolder payable {
        require(_to != address(0));
        require(_to != address(this));
        require(_chkHoldOrOwn(msg.sender, _tokenId));
        
        issetPass[_tokenId] = false;
        artsPassPhrase[_tokenId] = "";
        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);
        _record(_from, _to, _tokenId);
        _setrandPass(_tokenId, _from, _to, block.timestamp);

        emit Transfer(_from, _to, _tokenId);
    }
    
    function tokensOfOwner(address _owner) external view returns (uint256[]){
        uint256 balance = ownedTokens[_owner].length;
        if(balance == 0){
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](balance);
            for(uint256 i = 0; i < balance; i++){
                result[i] = ownedTokens[_owner][i];
            }
            return result;
        }
        
    }
    
}

