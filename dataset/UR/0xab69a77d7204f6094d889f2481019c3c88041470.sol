 
    uint256 public startTimeForTransfers;

     
    bool public mintingFinished = false;

     
    modifier canMint() {
      require(!mintingFinished);
      _;
    }
    modifier hasMintPermission() {
      require(msg.sender == owner);
      _;
    }

     
    mapping (address => bool) public frozenAccount;

     
    event FrozenFunds(address target, bool frozen);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event Burn(address indexed burner, uint256 value);


    constructor() public {
        startTimeForTransfers = now - 210 days;

        _totalSupply = initialSupply;
        owner = msg.sender;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, balances[owner]);
    }

     
    function() public payable {
        revert();
    }


     
    function setPresaleAddress(address _presaleAddress) external onlyOwner {
        presaleAddress = _presaleAddress;
        assert(approve(presaleAddress, presale_amount));
    }
    function setCrowdsaleAddress(address _crowdsaleAddress) external onlyOwner {
        crowdsaleAddress = _crowdsaleAddress;
        assert(approve(crowdsaleAddress, crowdsale_amount));
    }
    function setVestingAddress(address _vestingAddress) external onlyOwner {
        vestingAddress = _vestingAddress;
        assert(approve(vestingAddress, vesting_amount));
    }
    function setBountyAddress(address _bountyAddress) external onlyOwner {
        bountyAddress = _bountyAddress;
        assert(approve(bountyAddress, bounty_amount));
    }
    


    function getPresaleAmount()  internal pure returns(uint256) {
        return presale_amount;
    }
    function getCrowdsaleAmount() internal pure  returns(uint256) {
        return crowdsale_amount;
    }
    function getVestingAmount() internal pure  returns(uint256) {
        return vesting_amount;
    }
    function getBountyAmount() internal pure  returns(uint256) {
        return bounty_amount;
    }

     
    function setStartTimeForTokenTransfers(uint256 _startTimeForTransfers) external {
        require(msg.sender == crowdsaleAddress);
        if (_startTimeForTransfers < startTimeForTransfers) {
            startTimeForTransfers = _startTimeForTransfers;
        }
    }


     
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(now >= startTimeForTransfers);
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[_to]);

        require(super.transfer(_to, _value));
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        require(!frozenAccount[msg.sender]);

        if (now < startTimeForTransfers) {
            require(_from == owner);
        }

        require(super.transferFrom(_from, _to, _value));
        return true;
    }

     
    function approve(address spender, uint256 tokens) public returns (bool){
        require(super.approve(spender, tokens));
        return true;
    }

    
    function freezeAccount(address target, bool freeze) public onlyOwner {
        require(frozenAccount[target] != freeze);

        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }


     
    function mint(address _to, uint256 _amount) public hasMintPermission canMint returns (bool) {
      require(_totalSupply.add(_amount) <= minting_capped_amount);

      _totalSupply = _totalSupply.add(_amount);
      balances[_to] = balances[_to].add(_amount);
      emit Mint(_to, _amount);
      emit Transfer(address(0), _to, _amount);
      return true;
    }

    
    function finishMinting() public onlyOwner canMint returns (bool) {
      mintingFinished = true;
      emit MintFinished();
      return true;
    }

     
     function burn(uint256 _value) public {
       _burn(msg.sender, _value);
     }

     function _burn(address _who, uint256 _value) internal {
       require(_value <= balances[_who]);
        
        

       balances[_who] = balances[_who].sub(_value);
       _totalSupply = _totalSupply.sub(_value);
       emit Burn(_who, _value);
       emit Transfer(_who, address(0), _value);
     }
}
